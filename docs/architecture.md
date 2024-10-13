---
layout: home
title: Architecture
nav_order: 6
---

# Architecture

A queue is identified with a name, which is used as a key prefix.
Queues are stored in Redis as a list of incrementing integers representing unique message identifiers.
The messages itself are stored in Redis as strings.

The following Redis keys are used to store data.

General:
- `[{prefix}:]queues`: set of queue names
- `[{prefix}/]{name}`: list of message identifiers on the (pending) queue
- `[{prefix}/]{name}:id`: message identifier sequence
- `[{prefix}/]{name}:processing`: list of message identifiers being processed
- `[{prefix}/]{name}:scheduled`: list of message identifiers scheduled to retry
- `[{prefix}/]{name}:dead`: list of message identifiers that have been discarded
- `[{prefix}/]{name}:data:{id}`: message data for identifier `{id}`
- `[{prefix}/]{name}:metadata`: metadata for the queue
- `[{prefix}/]{name}:metadata:{id}`: metadata for identifier `{id}`
