# Generate protobuf stubs
     python -m grpc.tools.protoc -I./ --python_out=. --grpc_python_out=. quote_service.proto