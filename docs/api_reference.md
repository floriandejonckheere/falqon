---
layout: home
title: API Reference
nav_order: 4
---

# API
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

## Queue

### Create a queue

Use `Falqon::Queue.new` to create a new queue.
This will not execute any Redis commands.

```ruby
Falqon::Queue.new(name, max_retries:, redis:, logger:)
```

Arguments:

- `name`: the name of the queue
- `max_retries` (optional): the maximum number of retries before a message is discarded (defaults to `Falqon.configuration.max_retries`)
- `redis` (optional): the Redis connection pool to use (defaults to `Falqon.configuration.redis`)
- `logger` (optional): the logger to use (defaults to `Falqon.configuration.logger`)

Returns:

- `Falqon::Queue`: the queue instance

The name of the queue will be automatically prefixed with `Falqon.config.prefix` and a slash if set.

```ruby
Falqon.configuration.prefix = "falqon"

queue = Falqon::Queue.new("my_queue")

queue.name # => "falqon/my_queue"
```

### Push a message to the queue

**Single message**

Use `Falqon::Queue#push` to push a message to the queue.

```ruby
Falqon::Queue#push(message)
```

Arguments:

- `message`: the message to push to the queue, must be a string

Returns:

- `String`: the message identifier

**Multiple messages**

Use `Falqon::Queue#push` to push multiple messages to the queue.

```ruby
Falqon::Queue#push(*messages)
```

Arguments:

- `messages`: the messages to push to the queue, must be strings

Returns:

- `Array[String]`: the message identifiers

### Pop a message from the queue

**Return-style**

Use `Falqon::Queue#pop` to pop a message from the queue.

```ruby
Falqon::Queue#pop
```

Returns:

- `String`: the message contents

This method blocks until a message is available.

**Block-style**

Use `Falqon::Queue#pop` to pop a message from the queue.

```ruby
Falqon::Queue#pop do |message|
  # ...
end
```

Yields:

- `String`: the message contents

Returns:

- `String`: the message contents

This method blocks until a message is available.

If the block raises a `Falqon::Error` exception, the message will be requeued at the end of the queue.
If the message has reached the maximum number of retries, it will be discarded and moved to the dead queue.

### Peek to the next message in the queue

Use `Falqon::Queue#peek` to peek to the next message in the queue.

```ruby
Falqon::Queue#peek
```

Returns:

- `String`: the message contents
- `nil`: if no message is available

This method does not block.

### Clear the queue

Use `Falqon::Queue#clear` to clear the queue.
This deletes the queue and all its messages.
It also resets the stats.

```ruby
Falqon::Queue#clear
```

Returns:

- `Array[Integer]`: the identifiers of the messages that were deleted

### Get the number of messages in the queue

Use `Falqon::Queue#size` to get the number of messages in the queue.

```ruby
Falqon::Queue#size
```

Returns:

- `Integer`: the number of messages in the queue

### Check if the queue is empty

Use `Falqon::Queue#empty?` to check if the queue is empty.

```ruby
Falqon::Queue#empty?
```

Returns:

- `Boolean`: `true` if the queue is empty, `false` otherwise

### Get the queue stats

Use `Falqon::Queue#stats` to get the queue stats.

```ruby
Falqon::Queue#stats
```

Returns:

- `Hash`: queue statistics. Supported keys:
    - `:processed`: total number of processing attempts
    - `:failed`: total number of processing failures
    - `:retried`: total number of processing retries
