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

To see the available options for a command, run `falqon help COMMAND`.

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

### Queues

The `queues` command lists all queues.

```bash
$ falqon queues
jobs
emails
```

### Status

The `status` command displays the status of a queue, or all queues if no queue name is specified.

```bash
# Print status of all queues
$ falqon status
jobs: 41 entries (34 pending, 2 processing, 5 dead)
emails: empty

# Print status of a specific queue
$ falqon status --queue jobs
jobs: 41 entries (34 pending, 2 processing, 5 dead)
```

Options:
- `-q`, `--queue=QUEUE`: Queue name

### Show

The `show` command displays the contents of the queue.

```bash
# Print all entries in the queue
$ falqon show --queue jobs
id = 1 message = 8742 bytes

# Display raw data
$ falqon show --queue jobs --data
{"id":1,"message":"Hello, world!"}

# Display additional metadata
$ falqon show --queue jobs --meta
id = 1 retries = 0 created_at = 1970-01-01 00:00:00 +0000 updated_at = 1970-01-01 00:00:00 +0000 message = 8742 bytes

# Display first 5 entries
$ falqon show --queue jobs --head 5
id = 1 message = 8742 bytes
id = 2 message = 8742 bytes
id = 3 message = 8742 bytes
id = 4 message = 8742 bytes
id = 5 message = 8742 bytes

# Display last 5 entries
$ falqon show --queue jobs --tail 5
...

# Display entry at index 5
$ falqon show --queue jobs --index 3 --index 5
id = 3 message = 8742 bytes
id = 5 message = 8742 bytes

# Display entries from index 5 to 10
$ falqon show --queue jobs --range 5 10
...

# Display entry with ID 5
$ falqon show --queue jobs --id 5 --id 1
id = 5 message = 8742 bytes
id = 1 message = 8742 bytes
```

Options:
- `-q`, `--queue=QUEUE`: Queue name (required)
- `--pending`: Display pending entries (default)
- `--processing`: Display processing entries
- `--dead`: Display dead entries
- `-d`, `--data`: Display raw data 
- `-m`, `--meta`: Display additional metadata
- `--head N`: Display first N entries
- `--tail N`: Display last N entries
- `--index N`: Display entry at index N
- `--range N M`: Display entries from index N to M
- `--id N`: Display entry with ID N

### Clear

The `clear` command clears the contents of the queue.

```bash
# Clear all entries in the queue
$ falqon clear --queue jobs
Cleared 3 entries from queue jobs

# Clear only pending entries
$ falqon clear --queue jobs --pending
Cleared 3 entries from queue jobs

# Clear only processing entries
$ falqon clear --queue jobs --processing
Cleared 3 entries from queue jobs

# Clear only dead entries
$ falqon clear --queue jobs --dead
Cleared 3 entries from queue jobs
```

Options:

- `-q`, `--queue=QUEUE`: Queue name (required)
- `--pending`: Clear only pending entries
- `--processing`: Clear only processing entries
- `--dead`: Clear only dead entries

If none of the `--pending`, `--processing`, or `--dead` options are specified, all entries are cleared.
