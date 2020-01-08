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
* **record** a piece of information being sent in the message.
* **graph** a way to represent data recursively and other fun stuff.


## Message Format

Messages have a UUID keyed by `#`, an optional acknowledgement keyed by `@`, and a command.
The command is an object that contains any number of records.

> NOTE: If it were my decision, I would not have used `#` as the messages id key since it confuses with the similar field inside of a record.
> Just remember that the message's UUID is not at all related to the record's UUID, neither does it represent anything in the database. The message UUID is just used for transmitting messages through the network.

```json
{
    "#": "the-message-uuid",
    "@": "uuid-of-message-acknowledged",
    "some-command": {
        "some-record-uuid": {}
    }
}
```

Available commands:
* **get**
* **put**

### Put Message (write)

```json
{
    "#": "put-message-uuid",
    "put": {}
}
```

### Get Message (read)

```json
{
    "#": "get-message-uuid",
    "get": {}
}
```

### Awk Message (read response)

```json
{
    "#": "awk-message-uuid",
    "@": "get-message-uuid",
    "put": {}
}
```

## Graph Format

The data in GunDB is all communicated in JSON. However, JSON cannot represent graph data so we must follow some rules.
A record can be linked to any record in the graph including itself by referencing the record's UUID.

Example:
```json
{
    "ABC": {
        "name": "Jack",
        "sibling": {
            "#": "CBA"
        },
        "status": "self-employed",
        "boss": {
            "#": "ABC"
        }
    },
    "CBA": {
        "name": "Jill",
        "sibling": {
            "#": "ABC"
        }
    }
}
```

Let's pretend to take the above example and transform it into a language that conveniently provides dot-notation for looking up graph data. So we have a `jack` graph record and a `jill` graph record in our pseudo language, based on the example data above.

```js
// this is only pseudo code
jack.name == "Jack"

jack.sibling.name == "Jill"
jack.sibling.sibling.name == "Jack"

jack.boss.name == "Jack"
jack.boss.sibling.name == "Jill"
```

## Record Format

The command inside of a message usually contains some records. These describe the data being communicated.
There is a single reserved key `_` that contains metadata about this particular record.
The rest is the actual record data.

```json
{
    "_": {},
    "my-key": "My data",
}
```

### Record Metadata Format

The record metadata contains the record id under `#` and a vector under `>`.
The vector should contain keys matching the data and provides numerical values indicating the chronological order of the data keys. This information is used by GunDB to perform data conflict resolution.

```json
{
    "#": "the-record-uuid",
    ">": {
        "my-key": 123456789
    }
}
```

## Full Message Example

Writing data

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

Reading data

```json
{
    "#": "i9b",
    "get": {
        "#": "FDSA",
        ".": "species"
    }
}
```

Read response
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
