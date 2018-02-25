import os

import hug
from hug_middleware_cors import CORSMiddleware
import redis

api = hug.API(__name__)
api.http.add_middleware(CORSMiddleware(api))

redis_host = os.environ.get('QUOTE_STORE_SERVICE_HOST', 'localhost')
redis_server = redis.StrictRedis(host=redis_host, port=6379, db=0)


@hug.get('/quotes')
def get_all_quotes():
    return redis_server.lrange('quotes', 0, -1)


@hug.post('/quotes')
def add_quote(quote):
    redis_server.lpush('quotes', quote)

