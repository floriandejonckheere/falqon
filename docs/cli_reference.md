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
  falqon status          # Print queue status
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

## Commands

### Status

The `status` command prints the status of a queue, or all queues if no queue name is specified.

```bash
# Print status of all queues
$ falqon status
falqon/jobs: 41 entries (34 pending, 2 processing, 5 dead)
falqon/emails: empty

# Print status of a specific queue
$ falqon status --queue jobs
falqon/jobs: 41 entries (34 pending, 2 processing, 5 dead)
```

Options:
- `-q`, `--queue=QUEUE`: Queue name

### Show

The `show` command prints the contents of the queue.

```bash
# Print all entries in the queue
$ falqon show --queue jobs
id = 1 retries = 0 created_at = 1970-01-01 00:00:00 +0000 updated_at = 1970-01-01 00:00:00 +0000 message = 8742 bytes
```

Options:
- `-q`, `--queue=QUEUE`: Queue name (required)
- `--pending`: Display pending entries (default)
- `--processing`: Display processing entries
- `--dead`: Display dead entries
- `-d`, `--data`: Display raw data 
