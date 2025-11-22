"""
title: Document Search
author: daradib
author_url: https://github.com/daradib/
git_url: https://github.com/daradib/openwebui-plugins.git
description: Retrieves documents from a Qdrant vector store. Supports hybrid search for agentic knowledge base RAG.
requirements: fastembed, llama-index-embeddings-deepinfra, llama-index-embeddings-ollama, llama-index-llms-ollama, llama-index-vector-stores-qdrant
version: 0.2.4
license: AGPL-3.0-or-later
"""


# Notes:
#
# To use HuggingFace SentenceTransformer instead of Ollama or DeepInfra, add
# "llama-index-embeddings-huggingface, llama-index-llms-huggingface" to the
# requirements line above.
#
# Connection caching and citation indexing use async locking, but assume a
# single-node/worker (default). If a multi-node/worker deployment of Open WebUI
# will call this tool from separate workers, consider modifying it to use Redis
# for state synchronization.

import asyncio
import codecs
import json
import re
from typing import Any, Callable, Optional
from urllib.parse import urlparse

import aiohttp
from llama_index.core import QueryBundle, VectorStoreIndex
from llama_index.core.base.embeddings.base import BaseEmbedding
from llama_index.core.postprocessor.llm_rerank import LLMRerank
from llama_index.core.postprocessor.types import BaseNodePostprocessor
from llama_index.core.schema import NodeWithScore
from llama_index.core.vector_stores import (
    ExactMatchFilter,
    FilterCondition,
    MetadataFilters,
)
from llama_index.vector_stores.qdrant import QdrantVectorStore
from pydantic import BaseModel, Field
from qdrant_client import AsyncQdrantClient

# Number of candidates to retrieve if reranking:
CANDIDATES_PER_RESULT = 10
CANDIDATES_MIN = 20
CANDIDATES_MAX = 100

# Number of search results:
RESULTS_MIN = 1
RESULTS_DEFAULT = 5
RESULTS_MAX = 20

# Other reranker settings:
RERANKER_TEMPERATURE = 0
RERANKER_MAX_TOKENS = 64


class DeepInfraReranker(BaseNodePostprocessor):
    """
    Reranker using DeepInfra's reranking API.
    """

    top_n: int = Field(description="Number of top results to return")
    model_id: str = Field(description="DeepInfra reranker model ID")
    api_token: str = Field(description="DeepInfra API token")
    instruction: Optional[str] = Field(
        default=None,
        description="Instruction for the reranker model",
    )

    @classmethod
    def class_name(cls) -> str:
        return "DeepInfraReranker"

    def _postprocess_nodes(
        self,
        nodes: list[NodeWithScore],
        query_bundle: Optional[QueryBundle] = None,
    ) -> list[NodeWithScore]:
        raise NotImplementedError

    async def _apostprocess_nodes(
        self,
        nodes: list[NodeWithScore],
        query_bundle: Optional[QueryBundle] = None,
    ) -> list[NodeWithScore]:
        """
        Rerank nodes using DeepInfra API.
        """
        if not nodes:
            return []

        query_str = getattr(query_bundle, "query_str", "")
        if not query_str:
            return nodes[: self.top_n]

        # Prepare documents for reranking
        documents = [node.get_content() for node in nodes]
        queries = [query_str] * len(documents)

        # Call DeepInfra API
        url = f"https://api.deepinfra.com/v1/inference/{self.model_id}"
        headers = {
            "Authorization": f"bearer {self.api_token}",
            "Content-Type": "application/json",
        }
        payload = {
            "queries": queries,
            "documents": documents,
        }
        if self.instruction:
            payload["instruction"] = self.instruction

        async with aiohttp.ClientSession() as session:
            async with session.post(url, headers=headers, json=payload) as response:
                if not response.ok:
                    error_text = await response.text()
                    raise RuntimeError(
                        f"DeepInfra API error (status {response.status}): {error_text}"
                    )
                result = await response.json()

        scores = result.get("scores", [])
        if len(scores) != len(nodes):
            raise RuntimeError(
                f"DeepInfra returned {len(scores)} scores for {len(nodes)} documents"
            )

        # Pair nodes with scores and sort by score (descending)
        scored_nodes = list(zip(nodes, scores))
        scored_nodes.sort(key=lambda x: x[1], reverse=True)

        # Return top_n nodes with updated scores
        reranked_nodes = []
        for node, score in scored_nodes[: self.top_n]:
            node.score = score
            reranked_nodes.append(node)

        return reranked_nodes


def get_embedding_model(
    embedding_model_name: str,
    embedding_query_instruction: Optional[str] = None,
    ollama_base_url: Optional[str] = None,
    deepinfra_api_key: Optional[str] = None,
) -> BaseEmbedding:
    """
    Initialize and return the model for embedding.
    """
    if embedding_query_instruction:
        # Interpret escape sequences, e.g., literal '\n' into an actual newline.
        query_instruction = str(
            codecs.decode(embedding_query_instruction, "unicode_escape")
        ).strip()
    else:
        query_instruction = None
    if ollama_base_url:
        from llama_index.embeddings.ollama import OllamaEmbedding

        return OllamaEmbedding(
            model_name=embedding_model_name,
            base_url=ollama_base_url,
            query_instruction=query_instruction,
        )
    elif deepinfra_api_key:
        from llama_index.embeddings.deepinfra import DeepInfraEmbeddingModel

        return DeepInfraEmbeddingModel(
            model_id=embedding_model_name,
            api_token=deepinfra_api_key,
            query_prefix=query_instruction + " " if query_instruction else "",
        )
    else:
        from llama_index.embeddings.huggingface import HuggingFaceEmbedding

        return HuggingFaceEmbedding(
            model_name=embedding_model_name,
            query_instruction=query_instruction,
        )


def get_reranker(
    top_n: int,
    reranker_model_name: str,
    ollama_base_url: Optional[str] = None,
    deepinfra_api_key: Optional[str] = None,
) -> BaseNodePostprocessor:
    """
    Initialize and return the model for reranking.
    """
    if ollama_base_url:
        from llama_index.llms.ollama import Ollama

        llm = Ollama(
            model=reranker_model_name,
            base_url=ollama_base_url,
            temperature=RERANKER_TEMPERATURE,
            additional_kwargs={"num_predict": RERANKER_MAX_TOKENS},
        )
    elif deepinfra_api_key:
        return DeepInfraReranker(
            top_n=top_n,
            model_id=reranker_model_name,
            api_token=deepinfra_api_key,
        )
    else:
        from llama_index.llms.huggingface import HuggingFaceLLM

        llm = HuggingFaceLLM(
            model_name=reranker_model_name,
            max_new_tokens=RERANKER_MAX_TOKENS,
            generate_kwargs={"temperature": RERANKER_TEMPERATURE},
        )
    return LLMRerank(top_n=top_n, llm=llm)


def get_vector_index(
    qdrant_url: str,
    qdrant_collection_name: str,
    embedding_model: str,
    embedding_query_instruction: Optional[str] = None,
    ollama_base_url: Optional[str] = None,
    deepinfra_api_key: Optional[str] = None,
    qdrant_api_key: Optional[str] = None,
) -> VectorStoreIndex:
    """
    Initialize and return the VectorStoreIndex object.
    """
    # Connect to the existing Qdrant vector store.
    parsed_url = urlparse(qdrant_url, scheme="file")
    if parsed_url.scheme == "file":
        aclient = AsyncQdrantClient(path=parsed_url.path)
        kwargs = {"aclient": aclient}
        # Workaround for https://github.com/run-llama/llama_index/issues/20002
        QdrantVectorStore.use_old_sparse_encoder = lambda self, collection_name: False
    else:
        kwargs = {"url": qdrant_url, "api_key": qdrant_api_key or ""}

    vector_store = QdrantVectorStore(
        collection_name=qdrant_collection_name,
        enable_hybrid=True,
        fastembed_sparse_model="Qdrant/bm25",
        **kwargs,
    )

    embed_model = get_embedding_model(
        embedding_model_name=embedding_model,
        embedding_query_instruction=embedding_query_instruction,
        ollama_base_url=ollama_base_url,
        deepinfra_api_key=deepinfra_api_key,
    )

    # Create the index object from the existing vector store.
    index = VectorStoreIndex.from_vector_store(
        vector_store=vector_store, embed_model=embed_model
    )

    return index


def build_filters(file_name: str) -> MetadataFilters:
    """
    Build a LlamaIndex MetadataFilters object to filter by filename.
    """
    return MetadataFilters(
        filters=[ExactMatchFilter(key="file_name", value=file_name)],
        condition=FilterCondition.AND,
    )


def get_node_page(node: NodeWithScore) -> Optional[int]:
    """
    Return page number of Node.
    """
    page = node.metadata.get("page") or node.metadata.get("source")
    if not page:
        try:
            page = node.metadata["doc_items"][0]["prov"][0]["page_no"]
        except Exception:
            pass
    return page


def clean_text(text: str) -> str:
    """
    Remove unwanted formatting and artifacts from text output.
    """
    # Remove HTML tags.
    text = re.sub(r"<[a-zA-Z/][^>]*>", "", text)
    # Replace multiple blank lines with a single blank line.
    text = re.sub(r"\n\s*\n\s*\n+", "\n\n", text)
    # Remove lines with only whitespace.
    text = re.sub(r"^\s*$", "", text, flags=re.MULTILINE)
    # Remove excessive whitespace within lines.
    text = re.sub(r" +", " ", text)
    # Replace 4 or more periods with just 3 periods.
    text = re.sub(r"\.{4,}", "...", text)
    # Remove backticks.
    # Unclosed backticks seem to cause issues with citation rendering.
    text = text.replace("`", "")
    # Remove citation references.
    # Workaround for https://github.com/open-webui/open-webui/issues/17062
    # with updated regular expression for Open WebUI 0.6.33.
    text = re.sub(r"\[[\d,\s]+\]", "", text)
    # Strip leading/trailing whitespace.
    return text.strip()


def clean_node(node: NodeWithScore, citation_id: int) -> dict:
    """
    Remove internal LlamaIndex node attributes.
    """
    metadata_fields_to_keep = {
        "file_name",
        "file_type",
        "last_modified_date",
        "title",
        "total_pages",
        "headings",
    }
    cleaned_node = {
        "id": citation_id,
        "id_": node.id_,
        "metadata": {
            k: v for k, v in node.metadata.items() if k in metadata_fields_to_keep
        },
        "text": clean_text(node.text),
        "score": node.score,
    }
    page = get_node_page(node)
    if page:
        cleaned_node["metadata"]["page"] = page
    return cleaned_node


class CitationIndex:
    def __init__(self) -> None:
        self._set = set()
        self._count = 0
        self._lock = asyncio.Lock()

    async def emit_citation(
        self, node: NodeWithScore, __event_emitter__: Callable[[dict], Any]
    ) -> None:
        source_name = node.metadata.get("file_name", "Retrieved Document")
        source_name += f" ({node.id_})"
        page_number = get_node_page(node)
        if page_number:
            source_name += f" - p. {page_number}"
        await __event_emitter__(
            {
                "type": "citation",
                "data": {
                    "document": [clean_text(node.text)],
                    "metadata": [
                        {
                            "source": source_name,
                        }
                    ],
                    "source": {"name": source_name},
                },
            }
        )

    async def add_if_not_exists(
        self,
        node: NodeWithScore,
        __event_emitter__: Optional[Callable[[dict], Any]] = None,
    ) -> Optional[int]:
        # Lock required to prevent race conditions in check-and-set operation
        # and to ensure citations are emitted in citation_id order.
        async with self._lock:
            if node.id_ in self._set:
                return None
            else:
                if __event_emitter__:
                    await self.emit_citation(node, __event_emitter__)
                self._set.add(node.id_)
                self._count += 1
                return self._count


class Tools:
    """
    A toolset for interacting with an existing Qdrant vector store for Retrieval-Augmented Generation
    """

    class Valves(BaseModel):
        qdrant_url: str = Field(
            default="./qdrant_db",
            description="Path to a local Qdrant directory or remote Qdrant instance.",
        )
        qdrant_collection_name: str = Field(
            default="llamacollection",
            description="Qdrant collection containing both dense vectors and sparse vectors.",
        )
        qdrant_api_key: Optional[str] = Field(
            default=None,
            description="API key for remote Qdrant instance.",
        )
        embedding_model: str = Field(
            default="sentence-transformers/all-MiniLM-L6-v2",
            description="Model for query embeddings, which should match the model used to create the text embeddings.",
        )
        embedding_query_instruction: Optional[str] = Field(
            default=None,
            description="Instruction to prepend to query before embedding, e.g., 'query:'. Escape sequences like \\n are interpreted.",
        )
        reranker_model: Optional[str] = Field(
            default=None,
            description="Model for reranking search results. When set, retrieves more candidates to improve quality.",
        )
        ollama_base_url: Optional[str] = Field(
            default=None,
            description="Base URL for Ollama API. When set, uses Ollama instead of downloading the embedding/reranker models from HuggingFace.",
        )
        deepinfra_api_key: Optional[str] = Field(
            default=None,
            description="API key for DeepInfra. When set, uses DeepInfra instead of downloading the embedding/reranker models from HuggingFace.",
        )

    def __init__(self) -> None:
        """
        Initialize the tool and its valves.
        Disables automatic citation handling to allow for custom citation events.
        """
        self.valves = self.Valves()
        if self.valves.ollama_base_url and self.valves.deepinfra_api_key:
            raise ValueError("Do not set both Ollama base URL and DeepInfra API key")
        self.citation = False
        self._index = None
        self._last_config = None
        self._lock = asyncio.Lock()

    async def retrieve_documents(
        self,
        query: str,
        top_k: int = RESULTS_DEFAULT,
        file_name: Optional[str] = None,
        __metadata__: Optional[dict[str, Any]] = None,
        __event_emitter__: Optional[Callable[[dict], Any]] = None,
    ) -> str:
        """
        Retrieve relevant documents from the Qdrant vector store using hybrid search.

        :param query: Natural language search query
        :param top_k: Number of top documents to return
        :param file_name: Filename to optionally filter results by
        :param __metadata__: Injected by Open WebUI with information about the chat
        :param __event_emitter__: Injected by Open WebUI to send events to the frontend
        """

        async def emit_status(
            description: str, done: bool = False, hidden: bool = False
        ) -> None:
            """Helper function to emit status updates."""
            if __event_emitter__:
                await __event_emitter__(
                    {
                        "type": "status",
                        "data": {
                            "description": description,
                            "done": done,
                            "hidden": hidden,
                        },
                    }
                )

        if top_k < RESULTS_MIN or top_k > RESULTS_MAX:
            return f"Error: top_k must be between {RESULTS_MIN} and {RESULTS_MAX}."

        if file_name:
            parsed_filters = build_filters(file_name)
        else:
            parsed_filters = None

        filter_desc = f" in {file_name}" if file_name else ""
        await emit_status(f"Searching{filter_desc} for: {query}")

        try:
            # Cache and reuse the VectorStoreIndex object.
            # Lock required to prevent concurrent requests from closing/recreating
            # the index simultaneously, which could cause client errors.
            async with self._lock:
                current_config = self.valves.model_dump_json()
                if not self._index or self._last_config != current_config:
                    if self._index:
                        await self._index.vector_store._aclient.close()
                    self._index = get_vector_index(
                        qdrant_url=self.valves.qdrant_url,
                        qdrant_collection_name=self.valves.qdrant_collection_name,
                        embedding_model=self.valves.embedding_model,
                        embedding_query_instruction=self.valves.embedding_query_instruction,
                        ollama_base_url=self.valves.ollama_base_url,
                        deepinfra_api_key=self.valves.deepinfra_api_key,
                        qdrant_api_key=self.valves.qdrant_api_key,
                    )
                    self._last_config = current_config

            # Determine number of candidates to retrieve if reranking.
            if self.valves.reranker_model:
                num_candidates = max(
                    CANDIDATES_MIN,
                    min(CANDIDATES_MAX, top_k * CANDIDATES_PER_RESULT),
                )
            else:
                num_candidates = top_k

            # Create a query engine with hybrid search mode and async execution.
            retriever = self._index.as_retriever(
                vector_store_query_mode="hybrid",
                similarity_top_k=num_candidates,
                filters=parsed_filters,
                use_async=True,
            )

            nodes = await retriever.aretrieve(query)

            # Rerank if reranker model is configured.
            if self.valves.reranker_model and nodes:
                await emit_status(
                    f"Reranking top {top_k} from {len(nodes)} candidates..."
                )
                ranker = get_reranker(
                    top_n=top_k,
                    reranker_model_name=self.valves.reranker_model,
                    ollama_base_url=self.valves.ollama_base_url,
                    deepinfra_api_key=self.valves.deepinfra_api_key,
                )
                nodes = await ranker.apostprocess_nodes(nodes, query_str=query)

            if nodes:
                await emit_status("Search complete.", done=True, hidden=True)
            else:
                await emit_status("No documents found.", done=True)
                return "No relevant documents found for the query."

            if __metadata__:
                # Lock required to prevent concurrent requests from creating
                # separate CitationIndex instances, which would cause citation_id
                # collisions and loss of citation state across the conversation.
                if "document_search_citation_index" not in __metadata__:
                    async with self._lock:
                        if "document_search_citation_index" not in __metadata__:
                            __metadata__["document_search_citation_index"] = (
                                CitationIndex()
                            )
                citation_index = __metadata__["document_search_citation_index"]
            else:
                citation_index = CitationIndex()

            documents = []
            for node in nodes:
                citation_id = await citation_index.add_if_not_exists(
                    node, __event_emitter__
                )
                if citation_id:
                    documents.append(clean_node(node, citation_id=citation_id))

            return json.dumps(documents)

        except Exception as e:
            error_message = f"An error occurred during search: {e}"
            await emit_status(error_message, done=True, hidden=False)
            return error_message