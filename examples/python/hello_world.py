from examples.python.lib.hello import blah


def handler(event, context):
    print(event)
    blah()


handler(0, 0)
