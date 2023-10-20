---
layout: home
title: CLI reference
nav_order: 5
---

# Command-line interface reference
{: .no_toc }

Falqon includes a command-line interface (CLI) to manage queues and messages.
After installing Falqon, run `falqon` to see the available commands.

```bash
$ falqon
Commands:
  falqon help [COMMAND]  # Describe available commands or one specific command
  falqon version         # Print version
```

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

## Configuration

The command-line interface assumes the default Falqon configuration.
To use a custom configuration, set the corresponding environment variables:

```dotenv
# Configure global queue name prefix
FALQON_PREFIX=falqon

# Configure Redis connection pool
REDIS_URL=redis://localhost:6379/0
```
