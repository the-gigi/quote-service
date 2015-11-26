import hug
# import redis

quotes = []

@hug.get('/quotes')
def get_all_quotes():
    return quotes


@hug.post('/quotes')
def add_quote(quote):
    quotes.append(quote)
    return quote
