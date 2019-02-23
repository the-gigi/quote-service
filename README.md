# quote-service
A simple web service that manages quotes.

It supports the following operations:

- Add quote
- Get all quotes

The quotes are stored in redis

The code here accompanies this article: [Introduction to Docker and Kubernetes](https://code.tutsplus.com/articles/introduction-to-docker-and-kubernetes--cms-25406)


# Running the server locally via docker-compose

`docker-compose up`

# Running the server locally the hard way

## Create the virtual environment

`pipenv install`

## Install docker

see https://docs.docker.com/install/

## Launch Redis locally

`docker run -p 6379:6379 redis`

## Launch the quote service

`pipenv shell hug -f app.py`


# Usage via [cURL](http://curl.haxx.se/)

Get all quotes:

    curl http://localhost:8000/quotes
     
Add a quote:

    curl http://localhost:8000/quotes -d "quote=We must be very careful when we give advice to younger people: sometimes they follow it! ~ Edsger W. Dijkstra"

# Usage via [httpie](https://github.com/jkbrzt/httpie) 

Get all quotes:

    http http://localhost:8000/quotes
     
Add a quote:

    http --form http://localhost:8000/quotes quote="We must be very careful when we give advice to younger people: sometimes they follow it! ~ Edsger W. Dijkstra"

