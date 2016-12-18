import grpc
import sys

sys.path.insert(0, '')

from quote_service_pb2 import (QuoteRequest, QuoterStub)


def main():
  channel = grpc.insecure_channel('localhost:50051')
  stub = QuoterStub(channel)

  for i in range(3):
      r = stub.GetQuote(QuoteRequest(author=None))
      print('{} ~ {}'.format(r.quote, r.author))

if __name__ == '__main__':
  main()
