mqtt with regexp
================

> Simple monkeypatch, based on [named-regexp](https://www.npmjs.com/package/named-regexp), incoming topics are parsed with route like regexp, then captures are added to msg. This reduces number of nodes and simplify flow.

### example

![example](https://raw.githubusercontent.com/Baael/wojak-nodes/master/monkeypatches/mqtt-with-regexp/example.jpg)


### dead simple tri state gate

![example](http://screencast.com/t/mgJ5soNJRwV)

```coffees

    locked = "unlocked"
    color  = "green"

    this.lock = msg.lock if msg.lock
    cb(msg) if !msg.lock? && this.lock != "true"

    # status for node
    if this.lock == "true"
      locked = "locked"
      color  = "red"

    this.status
      shape: "dot"
      fill:  color
      text:  locked

    return null

```

