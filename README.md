# quote-service
A simple web service that manages quotes.

It supports the following operations:

- Add quote
- Get all quotes

The quotes are stored in redis


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

