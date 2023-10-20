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

- `id`: the queue identifier
- `name`: the queue name (`id` prefixed with `Falqon.config.prefix`)
- `retry_strategy`: the retry strategy (defaults to `Falqon.config.retry_strategy`)
- `max_retries`: the maximum number of retries before a message is discarded (defaults to `Falqon.config.max_retries`)
- `redis`: the Redis connection pool (defaults to `Falqon.config.redis`)
- `logger`: the logger (defaults to `Falqon.config.logger`)
- `version`: the queue protocol version (defaults to `Falqon::PROTOCOL`)

### Create a queue

Use `Falqon::Queue.new` to create a new queue.
This will register the queue and set the appropriate metadata (timestamps, etc.).

```ruby
Falqon::Queue.new(name, max_retries:, redis:, logger:)
```

Arguments:

- `name`: the name of the queue
- `max_retries` (optional): the maximum number of retries before a message is discarded (defaults to `Falqon.configuration.max_retries`)
- `redis` (optional): the Redis connection pool to use (defaults to `Falqon.configuration.redis`)
- `logger` (optional): the logger to use (defaults to `Falqon.configuration.logger`)
- `version` (optional): the queue protocol version to use (defaults to `Falqon::PROTOCOL`)

Returns:

- `Falqon::Queue`: the queue instance

Raises:

- `Falqon::VersionMismatchError`: if the queue protocol version does not match the current version

Note: currently queues are not compatible between different protocol versions. In the future, it will be possible to upgrade queues to a newer protocol version.

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

## Entry

An entry describes an item in a queue.

### Attributes

- `queue`: queue the entry belongs to
- `id`: the entry identifier
- `message`: the entry message
- `metadata`: the entry metadata

### Create an entry

Use `Falqon::Entry.new` and `Falqon::Entry#save` to create a new entry.
The `id` attribute will be automatically generated and set.

```ruby
entry.create
```

Arguments:

None

Returns:

- `Falqon::Entry`: the entry instance

### Kill an entry

Use `Falqon::Entry#kill` to kill an entry.
This will move the entry to the dead queue and reset the retry count.

```ruby
entry.kill
```

Arguments:

None

Returns:

None

### Delete an entry

Use `Falqon::Entry#delete` to delete an entry.
This will delete the entry and all its data (including metadata) from the queue.

```ruby
entry.delete
```

Arguments:

None

Returns:

None

### Get the entry metadata

Use `Falqon::Entry#metadata` to get the entry metadata.

```ruby
Falqon::Entry#metadata
```

Returns:

- `Falqon::Entry::Metadata`: entry metadata. Supported attributes:
  - `status`: entry status (unknown, pending, processing, dead)
  - `retries`: total number of processing retries
  - `created_at`: timestamp of the entry creation
  - `updated_at`: timestamp of the entry update
