import grpc

import sys

sys.path.insert(0, '')

from quote_service_pb2 import QuoteRequest
from quote_service_pb2_grpc import QuoterStub


def main():
    with grpc.insecure_channel('localhost:5050') as channel:
        stub = QuoterStub(channel)
        for i in range(3):
            r = stub.GetQuote(QuoteRequest(author=None))
            print('{} ~ {}'.format(r.quote, r.author))


if __name__ == '__main__':
    main()
