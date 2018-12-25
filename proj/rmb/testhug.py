import hug


@hug.get('/', output=hug.output_format.json)
def root():
    return {'msg': "欢迎来到 HUG 指南"}


# @hug.default_input_format("application/json")
@hug.post('/test')
def test(body):
    # parsed = hug.input_format.json(body)
    # return "GOT {}: {}".format(type(parsed), repr(parsed))
    # print("GOT {}: {}".format(type(body), repr(body)))
    return body


@hug.post('/demo')
def demo(**kws):
    # parsed = hug.input_format.json(data)
    return kws


@hug.get('/happy_birthday', examples="name=HUG&age=1")
def happy_birthday(name, age: hug.types.number):
    """Says happy birthday to a user"""
    return "Happy {age} Birthday {name}!".format(**locals())


@hug.get('/greet/{event}')
def greet(event: str):
    """Greets appropriately (from http://blog.ketchum.com/how-to-write-10-common-holiday-greetings/)  """
    greetings = "Happy"
    if event == "Christmas":
        greetings = "Merry"
    if event == "Kwanzaa":
        greetings = "Joyous"
    if event == "wishes":
        greetings = "Warm"

    return "{greetings} {event}!".format(**locals())


@hug.get('/all')
def my_sink(request):
    return request.params
