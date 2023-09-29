---
layout: home
title: Architecture
nav_order: 5
---

# Architecture

A queue is identified with a name, which is used as a key prefix.
Queues are stored in Redis as a list of incrementing integers representing unique message identifiers.
The messages itself are stored in Redis as strings.

The following Redis keys are used:
- `{name}`: list of message identifiers on the (pending) queue
- `{name}:id`: message identifier sequence
- `{name}:processing`: list of message identifiers being processed
- `{name}:dead`: list of message identifiers that have been discarded
- `{name}:messages:{id}`: message contents for identifier `{id}`
- `{name}:metadata`: metadata for the queue
- `{name}:metadata:{id}`: metadata for identifier `{id}`
