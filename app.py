import os
from typing import List

from fastapi import FastAPI, Form
from fastapi.middleware.cors import CORSMiddleware
import redis
from pydantic import BaseModel

app = FastAPI(title="Quote Service", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

redis_host = os.environ.get('QUOTE_STORE_SERVICE_HOST', 'localhost')
redis_server = redis.Redis(host=redis_host, port=6379, db=0, decode_responses=True)


class Quote(BaseModel):
    quote: str


@app.get("/quotes", response_model=List[str])
async def get_all_quotes():
    quotes = redis_server.lrange('quotes', 0, -1)
    return quotes


@app.post("/quotes")
async def add_quote(quote: str = Form(...)):
    redis_server.lpush('quotes', quote)
    return {"message": "Quote added successfully"}


@app.get("/health")
async def health_check():
    try:
        redis_server.ping()
        return {"status": "healthy", "redis": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "redis": "disconnected", "error": str(e)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

