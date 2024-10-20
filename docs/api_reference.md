---
layout: home
title: API reference
nav_order: 4
---

# API reference
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

## Queue

### Attributes

- `name`: the queue name (e.g. `my_queue`)
- `id`: the queue identifier (`name` prefixed with `Falqon.config.prefix` and a slash, e.g. `falqon/my_queue`)
- `retry_strategy`: the retry strategy (defaults to `Falqon.config.retry_strategy` or `linear` if not set)
- `max_retries`: the maximum number of retries before a message is discarded (defaults to `Falqon.config.max_retries` or `3` if not set)
- `retry_delay`: the delay between retries (defaults to `Falqon.config.retry_delay` or `0` if not set)
- `redis`: the Redis connection pool (defaults to `Falqon.config.redis`)
- `logger`: the logger (defaults to `Falqon.config.logger`)
- `version`: the queue protocol version (defaults to `Falqon::PROTOCOL`)

### Create a queue

Use `Falqon::Queue.new` to create a new queue.
This will register the queue and set the appropriate metadata (timestamps, etc.).

```ruby
Falqon::Queue.new(name)
```

Arguments:

- `name`: the name of the queue
- `retry_strategy`: the retry strategy to use (defaults to `Falqon.configuration.retry_strategy`)
- `max_retries` (optional): the maximum number of retries before a message is discarded (defaults to `Falqon.configuration.max_retries`)
- `retry_delay` (optional): the delay between retries (defaults to `Falqon.configuration.retry_delay` or `0` if not set)
- `redis` (optional): the Redis connection pool to use (defaults to `Falqon.configuration.redis`)
- `logger` (optional): the logger to use (defaults to `Falqon.configuration.logger`)
- `version` (optional): the queue protocol version to use (defaults to `Falqon::PROTOCOL`)

Returns:

- `Falqon::Queue`: the queue instance

Raises:

- `Falqon::VersionMismatchError`: if the queue protocol version does not match the current version

Note: currently queues are not compatible between different protocol versions. In the future, it will be possible to upgrade queues to a newer protocol version.

The id of the queue is the name of the queue prefixed with `Falqon.config.prefix` and a slash (if configured).

```ruby
Falqon.configuration.prefix = "falqon"

queue = Falqon::Queue.new("my_queue")

queue.name # => "my_queue"
queue.id # => "falqon/my_queue"
```

### Clear the queue

Use `Falqon::Queue#clear` to clear the queue.
This deletes the queue and all its messages.
It also resets the metadata (except for creation/update timestamp), but does not deregister the queue.

```ruby
Falqon::Queue#clear
```

Returns:

- `Array[Integer]`: the identifiers of the messages that were deleted

### Delete the queue

Use `Falqon::Queue#delete` to delete the queue.
This deletes the queue and all its messages.
It also resets the metadata and deregisters the queue.

```ruby
Falqon::Queue#delete
```

### Refill the queue

Use `Falqon::Queue#refill` to refill the queue.
This moves all processing messages to the head of the pending queue (in order).
This method is useful when a worker crashes and messages are stuck in the processing queue.

```ruby
Falqon::Queue#refill
```

### Revive the queue

Use `Falqon::Queue#revive` to revive the queue.
This moves all dead messages to the head of the pending queue (in order).

```ruby
Falqon::Queue#refill
```

### Schedule failed messages

Use `Falqon::Queue#schedule` to schedule eligible failed messages for retry.
This will move the messages that can be retried according to the retry strategy and delay to the head of the pending queue.

```ruby
Falqon::Queue#schedule
```

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

### Get the queue metadata

Use `Falqon::Queue#metadata` to get the queue metadata.

```ruby
Falqon::Queue#metadata
```

Returns:

- `Falqon::Queue::Metadata`: queue metadata. Supported attributes:
    - `processed`: total number of processing attempts
    - `failed`: total number of processing failures
    - `retried`: total number of processing retries
    - `created_at`: timestamp of the queue creation
    - `updated_at`: timestamp of the queue update
    - `version`: queue protocol version

### List all queues

Use `Falqon::Queue.all` to list all queues.
Queues are registered on initialization, and deregistered on deletion.

```ruby
Falqon::Queue.all
```

Returns:

- `Array[Falqon::Queue]`: active (registered) queues

### Get number of queues

Use `Falqon::Queue.size` to get the number of active (registered) queues.
Queues are registered on initialization, and deregistered on deletion.

```ruby
Falqon::Queue.size
```

Returns:

- `Integer`: the number of active (registered) queues

## Message

An message describes an item in a queue.

### Attributes

- `queue`: queue the message belongs to
- `id`: the message identifier
- `message`: the message message
- `metadata`: the message metadata

### Create an message

Use `Falqon::Message.new` and `Falqon::Message#save` to create a new message.
The `id` attribute will be automatically generated and set.

```ruby
message.create
```

Arguments:

None

Returns:

- `Falqon::Message`: the message instance

### Kill an message

Use `Falqon::Message#kill` to kill an message.
This will move the message to the dead queue and reset the retry count.

```ruby
message.kill
```

Arguments:

None

Returns:

None

### Delete an message

Use `Falqon::Message#delete` to delete an message.
This will delete the message and all its data (including metadata) from the queue.

```ruby
message.delete
```

Arguments:

None

Returns:

None

### Check message size

Use `Falqon::Message#size` to get the message size.

```ruby
message.size
```

Arguments:

None

Returns:

- `Integer`: the message size (in bytes)

### Check existence

Use `Falqon::Message#exists?` to check if an message exists.

```ruby
message.exists?
```

Arguments:

None

Returns:

- `Boolean`: `true` if the message exists, `false` otherwise

### Get the message metadata

Use `Falqon::Message#metadata` to get the message metadata.

```ruby
Falqon::Message#metadata
```

Returns:

- `Falqon::Message::Metadata`: message metadata. Supported attributes:
  - `status`: message status (unknown, pending, processing, scheduled, dead)
  - `retries`: total number of processing retries
  - `created_at`: timestamp of the message creation
  - `updated_at`: timestamp of the message update

The following convenience methods are also defined on `Message`:
- `unknown?`
- `pending?`
- `processing?`
- `scheduled?`
- `dead?`
