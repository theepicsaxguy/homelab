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
import os
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
    text = re.sub(r"\[\d+\]", "", text)
    return text.strip()


class Pipeline:
    """
    Document Search Pipeline for OpenWebUI.
    Provides document retrieval from Qdrant vector store with hybrid search.
    """

    class Valves(BaseModel):
        QDRANT_URL: str = Field(
            default="http://qdrant.qdrant.svc.cluster.local:6333",
            description="URL of the Qdrant server"
        )
        QDRANT_COLLECTION_NAME: str = Field(
            default="documents",
            description="Name of the Qdrant collection"
        )
        QDRANT_API_KEY: str = Field(
            default="",
            description="API key for Qdrant (optional)"
        )
        EMBEDDING_MODEL: str = Field(
            default="nomic-embed-text:latest",
            description="Name of the embedding model"
        )
        EMBEDDING_QUERY_INSTRUCTION: str = Field(
            default="",
            description="Optional instruction prefix for embeddings"
        )
        OLLAMA_BASE_URL: str = Field(
            default="http://litellm.litellm.svc.cluster.local:4000",
            description="Base URL for Ollama API"
        )
        DEEPINFRA_API_KEY: str = Field(
            default="",
            description="DeepInfra API key (optional)"
        )
        RERANKER_MODEL: str = Field(
            default="",
            description="Model to use for reranking results (optional)"
        )
        NUM_RESULTS: int = Field(
            default=RESULTS_DEFAULT,
            description=f"Number of results to return ({RESULTS_MIN}-{RESULTS_MAX})"
        )
        USE_RERANKING: bool = Field(
            default=False,
            description="Whether to use reranking"
        )

    def __init__(self):
        self.name = "Document Search Pipeline"
        self.valves = self.Valves(
            **{k: os.getenv(k, v.default) for k, v in self.Valves.model_fields.items()}
        )
        self.index = None
        self.lock = asyncio.Lock()

    async def on_startup(self):
        """Initialize the vector store connection on startup."""
        print(f"on_startup:{self.name}")
        await self._initialize_index()

    async def on_shutdown(self):
        """Cleanup on shutdown."""
        print(f"on_shutdown:{self.name}")

    async def _initialize_index(self):
        """Initialize the VectorStoreIndex."""
        async with self.lock:
            if self.index is None:
                self.index = get_vector_index(
                    qdrant_url=self.valves.QDRANT_URL,
                    qdrant_collection_name=self.valves.QDRANT_COLLECTION_NAME,
                    embedding_model=self.valves.EMBEDDING_MODEL,
                    embedding_query_instruction=self.valves.EMBEDDING_QUERY_INSTRUCTION,
                    ollama_base_url=self.valves.OLLAMA_BASE_URL,
                    deepinfra_api_key=self.valves.DEEPINFRA_API_KEY,
                    qdrant_api_key=self.valves.QDRANT_API_KEY,
                )

    async def search_documents(
        self,
        query: str,
        num_results: int = None,
        file_name: str = None
    ) -> list[dict]:
        """
        Search for documents in the vector store.
        
        Args:
            query: Search query string
            num_results: Number of results to return
            file_name: Optional filename filter
            
        Returns:
            List of search results with content and metadata
        """
        if self.index is None:
            await self._initialize_index()

        if num_results is None:
            num_results = self.valves.NUM_RESULTS

        # Clamp num_results to valid range
        num_results = max(RESULTS_MIN, min(num_results, RESULTS_MAX))

        # Build filters if filename is specified
        filters = build_filters(file_name) if file_name else None

        # Configure retriever
        retriever_kwargs = {
            "similarity_top_k": num_results,
        }
        if filters:
            retriever_kwargs["filters"] = filters

        # Add reranking if enabled
        node_postprocessors = []
        if self.valves.USE_RERANKING and self.valves.RERANKER_MODEL:
            candidates = max(
                CANDIDATES_MIN,
                min(num_results * CANDIDATES_PER_RESULT, CANDIDATES_MAX)
            )
            retriever_kwargs["similarity_top_k"] = candidates
            reranker = get_reranker(
                top_n=num_results,
                reranker_model_name=self.valves.RERANKER_MODEL,
                ollama_base_url=self.valves.OLLAMA_BASE_URL,
                deepinfra_api_key=self.valves.DEEPINFRA_API_KEY,
            )
            node_postprocessors.append(reranker)

        # Create query engine
        query_engine = self.index.as_query_engine(
            similarity_top_k=retriever_kwargs["similarity_top_k"],
            filters=filters,
            node_postprocessors=node_postprocessors,
        )

        # Execute query
        response = await query_engine.aquery(query)

        # Format results
        results = []
        for node in response.source_nodes:
            content = clean_text(node.get_content())
            page = get_node_page(node)
            
            result = {
                "content": content,
                "score": node.score if hasattr(node, "score") else None,
                "metadata": node.metadata,
            }
            if page:
                result["page"] = page
            results.append(result)

        return results

    def pipe(
        self,
        user_message: str,
        model_id: str,
        messages: list[dict],
        body: dict
    ) -> str:
        """
        Main pipeline function for document search.
        """
        print(f"pipe:{self.name}")
        print(f"User Message: {user_message}")

        # Check if this is a title generation request
        if body.get("title", False):
            return "(title generation disabled)"

        # For now, return a simple response
        # In a full implementation, this would search the vector store
        return "Document Search Pipeline is active. Use the search_documents function to retrieve documents."
