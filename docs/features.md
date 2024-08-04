---
layout: home
title: Features
nav_order: 3
---

# Features

## Acknowledgement

When using the block-style `pop` method, the message will be acknowledged when the block returns without raising a `Falqon::Error` exception.
Acknowledgement will remove the message and its data from the queue.
If the block raises a `Falqon::Error` exception, the message will be retried according to the configured retry strategy.

The return-style `pop` method immediately acknowledges the message before returning it.

## Retry strategy

A retry strategy can be configured to determine how a message should be retried before being discarded.
The following strategies are available:
- `none`: the message will not be retried and will be discarded immediately
- `linear`: the message will be retried a maximum of `max_retries` attempts, with linear backoff (configured by `retry_delay`)

Additionally, if the `linear` strategy is configured and the `retry_delay` is set to a non-zero value, a scheduler needs to be started to retry messages after the configured `retry_delay`:

```ruby
require "falqon"

queue = Falqon::Queue.new("my_queue")

# Start the watcher in a separate thread
Thread.new { loop { queue.schedule; sleep 1 } }

# Or start the watcher in a separate fiber
Fiber
  .new { loop { queue.schedule; sleep 1 } }
  .resume
```

Discarded messages will be moved to the dead queue, and can be revived manually if needed.

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
