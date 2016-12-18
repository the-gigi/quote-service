import random
from concurrent import futures
import time

from collections import defaultdict

import grpc
import sys
from pathlib import Path

sys.path.insert(0, '')

from quote_service_pb2 import (QuoterServicer,
                               QuoteReply,
                               add_QuoterServicer_to_server)

script_dir = Path(__file__).parent
lines = open(str(script_dir / '../quotes.txt')).read().split('\n')
quotes = defaultdict(list)
for line in (x for x in lines if x):
    q, a = line.split('~')
    quotes[a.strip()].append(q.strip())

all_authors = tuple(quotes.keys())


class Quoter(QuoterServicer):
    def GetQuote(self, request, context):
        # Choose random author if it requested author doesn't has quotes
        if request.author in all_authors:
            author = request.author
        else:
            author = random.choice(all_authors)

            # Choose random quote from this author
        quote = random.choice(quotes[author])
        return QuoteReply(quote=quote, author=author)


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    add_QuoterServicer_to_server(Quoter(), server)
    server.add_insecure_port('[::]:50051')
    server.start()
    print('Started...')
    try:
        while True:
            time.sleep(9999)
    except KeyboardInterrupt:
        server.stop(0)


if __name__ == '__main__':
    serve()
