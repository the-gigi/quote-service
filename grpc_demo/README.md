# gRPC Quote Service

The code in this directory accompanies this article: [High-Performance Services with gRPC](http://www.devx.com/architect/high-performance-services-with-grpc.html)

# Generate protobuf stubs

```
python -m grpc.tools.protoc -I./ --python_out=. --grpc_python_out=. quote_service.proto
```