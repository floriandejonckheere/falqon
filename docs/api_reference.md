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
