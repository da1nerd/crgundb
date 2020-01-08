# Network Protocol For GunDB

If you want an overview of what GunDB is, you're in the wrong place.
This is hopefully a detailed specification of the communication protocol employed by GunDB.
Websockets, storage devices, etc. are all beyond the scope of this specification.
My real goal is to provide something clear and succinct that others can develop from.
I may take license to reword/rename certain features in order to make things clearer to myself.

## Definitions

* **node** This is what I'm calling a server running some GunDB code. It could be a server or a client, but in some fashion it participates in propogating messages through the network.
* **network** this is a collection of nodes spread over a geographic region, that have at least one link to another node in the network.
* **message** this is information transmitted to and from a node.

## Message Format

A message is just a json object with a single reserved key `_` that contains information to uniquely identify the message and evaluate it's chronological order of occurrence within the network.

Here are some example payloads.
> TODO: break these down and explain each part.

writing to the database
```json
{
    "#": "yb2",
    "put": {
        "ASDF": {
            "_": {
                "#": "ASDF",
                ">": {
                    "name": 2,
                    "boss": 2
                }
            },
            "name": "Mark Nadal",
            "boss": {
                "#": "FDSA"
            }
        },
        "FDSA": {
            "_": {
                "#": "FDSA",
                ">": {
                    "name": 2,
                    "species": 2,
                    "slave": 2
                }
            },
            "name": "Fluffy",
            "species": "a kitty",
            "slave": {
                "#": "ASDF"
            }
        }
    }
}
```

writing more to the database
```json
{
    "#": "8t2",
    "put": {
        "ASDF": {
            "_": {
                "#": "ASDF",
                ">": {
                    "name": 1
                }
            },
            "name": "Mark"
        },
        "FDSA": {
            "_": {
                "#": "FDSA",
                ">": {
                    "species": 2,
                    "color": 3
                }
            },
            "species": "felis silvestris",
            "color": "ginger"
        }
    }
}
```

reading from the database
```json
{
    "#": "i9b",
    "get": {
        "#": "FDSA",
        ".": "species"
    }
}
```

response from read request
```json
{
    "#": "",
    "@": "i9b",
    "put": {
        "FDSA": {
            "_": {
                "#": "FDSA",
                ">": {
                    "species": 2
                }
            },
            "species": "a kitty"
        }
    }
}
```

forwarding message to the rest of the network, notice how it is identical to the response above.
```json
{
    "#": "",
    "@": "i9b",
    "put": {
        "FDSA": {
            "_": {
                "#": "FDSA",
                ">": {
                    "species": 2.0
                }
            },
            "species": "a kitty"
        }
    }
}
```