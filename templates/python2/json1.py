import python_jsonschema_objects as pjs
builder = pjs.ObjectBuilder('message.json')
ns = builder.build_classes()

# AST -> JSON -> Object -> 

# Provide your schema def

# Message override __getattr__ to simply return string, unicode, int, etc

class Dummy(ns.Abacomessage):
    def __getattribute__(self, attr):
        return attr

msg = Dummy.from_json('{"id": "abcdefgh", "ix": "12345", "merp": [1,2,3]}')

print(msg.id)
print(msg.ix)

msg['id'] = intern('xxxxx')
print(msg.id)

# Service interface

import reactors as Reactor
