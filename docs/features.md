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
- `linear`: the message will be retried a maximum of `max_retries` times before being discarded
