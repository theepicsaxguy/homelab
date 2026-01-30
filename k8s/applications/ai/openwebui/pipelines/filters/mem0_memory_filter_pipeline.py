"""
title: Long Term Memory Filter
author: Anton Nilsson
date: 2024-08-23
version: 1.0
license: MIT
description: A filter that processes user messages and stores them as long term memory by utilizing qdrant and fastembed with ollama
requirements: pydantic, qdrant-client[fastembed], fastembed, protobuf
"""

from typing import List, Optional
from pydantic import BaseModel
import json
from qdrant_client import QdrantClient
from qdrant_client.http import models
import fastembed
import threading

class Pipeline:
    class Valves(BaseModel):
        pipelines: List[str] = []
        priority: int = 0

        store_cycles: int = 5 # Number of messages from the user before the data is processed and added to the memory
        mem_zero_user: str = "user" # Memories belongs to this user, only used by mem0 for internal organization of memories

        # Default values for the mem0 vector store
        vector_store_qdrant_name: str = "memories"
        vector_store_qdrant_url: str = "qdrant.qdrant.svc.cluster.local"
        vector_store_qdrant_port: int = 6333
        vector_store_qdrant_dims: int = 384 # Need to match the vector dimensions of the embedder model

        # Default values for the mem0 language model (OpenAI API or LiteLLM)
        openai_api_key: str = "" # Set via environment variable or secret
        openai_llm_model: str = "mistral/mistral-small-latest"
        openai_llm_temperature: float = 0
        openai_llm_tokens: int = 8000
        llm_url: str = "http://litellm.litellm.svc.cluster.local:4000"

        # Default values for the mem0 embedding model (FastEmbed)
        embedder_model: str = "BAAI/bge-small-en-v1.5"

    def __init__(self):
        self.type = "filter"
        self.name = "Memory Filter"
        self.user_messages = []
        self.thread = None
        self.valves = self.Valves(
            **{
                "pipelines": ["*"],  # Connect to all pipelines
            }
        )
        # Direct Qdrant client
        self.qdrant = QdrantClient(
            host=self.valves.vector_store_qdrant_url,
            port=self.valves.vector_store_qdrant_port
        )
        # FastEmbed model
        self.embedder = fastembed.SentenceTransformerEmbedding(model_name=self.valves.embedder_model)
        self.collection_name = self.valves.vector_store_qdrant_name

    async def on_startup(self):
        print(f"on_startup:{__name__}")
        # Ensure collection exists
        self.qdrant.recreate_collection(
            collection_name=self.collection_name,
            vectors_config=models.VectorParams(size=self.valves.vector_store_qdrant_dims, distance=models.Distance.COSINE)
        )

    async def on_shutdown(self):
        print(f"on_shutdown:{__name__}")
        pass

    async def inlet(self, body: dict, user: Optional[dict] = None) -> dict:
        print(f"pipe:{__name__}")

        user = self.valves.mem_zero_user
        store_cycles = self.valves.store_cycles

        if isinstance(body, str):
            body = json.loads(body)

        all_messages = body["messages"]
        last_message = all_messages[-1]["content"]

        self.user_messages.append(last_message)

        if len(self.user_messages) == store_cycles:

            message_text = ""
            for message in self.user_messages:
                message_text += message + " "

            if self.thread and self.thread.is_alive():
                print("Waiting for previous memory to be done")
                self.thread.join()

            self.thread = threading.Thread(target=self.add_memory, args=(message_text, user))

            print("Text to be processed in to a memory:")
            print(message_text)

            self.thread.start()
            self.user_messages.clear()

        results = self.search_memory(last_message, user)

        if(results):
            fetched_memory = results[0].payload["memory"]
        else:
            fetched_memory = ""

        print("Memory added to the context:")
        print(fetched_memory)

        if fetched_memory:
            all_messages.insert(0, {"role":"system", "content":"This is your inner voice talking, you remember this about the person you chatting with "+str(fetched_memory)})

        print("Final body to send to the LLM:")
        print(body)

        return body

    def add_memory(self, text: str, user_id: str):
        embedding = self.embedder.embed([text])[0]
        self.qdrant.upsert(
            collection_name=self.collection_name,
            points=[models.PointStruct(
                id=hash(text),  # Simple ID generation
                vector=embedding,
                payload={"user_id": user_id, "memory": text}
            )]
        )

    def search_memory(self, query: str, user_id: str, limit=1):
        query_embedding = self.embedder.embed([query])[0]
        return self.qdrant.search(
            collection_name=self.collection_name,
            query_vector=query_embedding,
            query_filter=models.Filter(
                must=[models.FieldCondition(key="user_id", match=models.MatchValue(value=user_id))]
            ),
            limit=limit
        )