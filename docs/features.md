---
layout: home
title: Features
nav_order: 3
---

# Features

## Hooks

Hooks can be registered on a custom queue to execute code before and after certain events.
The following hooks are available:

- `after :initialize`: executed after the queue has been initialized
- `before :push`: executed before a message is pushed to the queue
- `after :push`: executed after a message has been pushed to the queue
- `before :pop`: executed before a message is popped from the queue
- `after :pop`: executed after a message has been popped from the queue (but before deleting it)
- `before :peek`: executed before peeking to a message in the queue
- `after :peek`: executed after peeking to a message in the queue
- `before :range`: executed before peeking to a message range in the queue
- `after :range`: executed after peeking to a message range in the queue
- `before :clear`: executed before clearing the queue
- `after :clear`: executed after clearing the queue
- `before :delete`: executed before deleting the queue
- `after :delete`: executed after deleting the queue
- `before :refill`: executed before refilling the queue
- `after :refill`: executed after refilling the queue
- `before :revive`: executed before reviving a message from the dead queue
- `after :revive`: executed after reviving a message from the dead queue

Hooks can be registered using the `Falqon::Queue.before` and `Falqon::Queue.after` methods:

```ruby
class MyQueue < Falqon::Queue
  before :push, :do_before_push

  after :delete do
    # ...
  end

  private

  def do_before_push
    # ...
  end
end
```
