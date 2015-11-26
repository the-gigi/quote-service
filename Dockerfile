FROM ubuntu:latest
MAINTAINER Gigi Sayfan "the.gigi@gmail.com"
RUN apt-get update -y
RUN apt-get install -y python3 python3-pip python3-dev build-essential
COPY . /quote-service
WORKDIR /quote-service
RUN pip3 install -r requirements.txt
EXPOSE 8000
ENTRYPOINT hug -f app.py
