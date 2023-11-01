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
jobs: 41 messages (34 pending, 2 processing, 5 dead)
emails: empty

# Print status of a specific queue
$ falqon status --queue jobs
jobs: 41 messages (34 pending, 2 processing, 5 dead)
```

Options:
- `-q`, `--queue=QUEUE`: Queue name

### Show

The `show` command displays messages in a queue.

```bash
# Print all messages in the queue (by default only pending messages are displayed)
$ falqon show --queue jobs
id = 1 data = 8742 bytes

# Display only pending messages
$ falqon show --queue jobs --pending
...

# Display only processing messages
$ falqon show --queue jobs --processing
...

# Display only dead messages
$ falqon show --queue jobs --dead
...

# Display raw data
$ falqon show --queue jobs --data
{"id":1,"message":"Hello, world!"}

# Display additional metadata
$ falqon show --queue jobs --meta
id = 1 retries = 0 created_at = 1970-01-01 00:00:00 +0000 updated_at = 1970-01-01 00:00:00 +0000 data = 8742 bytes

# Display first 5 messages
$ falqon show --queue jobs --head 5
id = 1 data = 8742 bytes
id = 2 data = 8742 bytes
id = 3 data = 8742 bytes
id = 4 data = 8742 bytes
id = 5 data = 8742 bytes

# Display last 5 messages
$ falqon show --queue jobs --tail 5
...

# Display message at index 5
$ falqon show --queue jobs --index 3 --index 5
id = 3 data = 8742 bytes
id = 5 data = 8742 bytes

# Display messages from index 5 to 10
$ falqon show --queue jobs --range 5 10
...

# Display message with ID 5
$ falqon show --queue jobs --id 5 --id 1
id = 5 data = 8742 bytes
id = 1 data = 8742 bytes
```

Options:
- `-q`, `--queue=QUEUE`: Queue name (required)
- `--pending`: Display pending messages (default)
- `--processing`: Display processing messages
- `--dead`: Display dead messages
- `-d`, `--data`: Display raw data
- `-m`, `--meta`: Display additional metadata
- `--head N`: Display first N messages
- `--tail N`: Display last N messages
- `--index N`: Display message at index N
- `--range N M`: Display messages from index N to M
- `--id N`: Display message with ID N

### Delete

The `delete` command deletes messages in a queue.

```bash
# Delete all messages in the queue (by default only pending messages are deleted)
$ falqon delete --queue jobs
Deleted 10 messages from queue jobs

# Delete only pending messages
$ falqon delete --queue jobs --pending
Deleted 10 pending messages from queue jobs

# Delete only processing messages
$ falqon delete --queue jobs --processing
Deleted 1 processing message from queue jobs

# Delete only dead messages
$ falqon delete --queue jobs --dead
Deleted 5 dead messages from queue jobs

# Delete first 5 messages
$ falqon delete --queue jobs --head 5
Deleted 5 messages from queue jobs

# Delete last 5 messages
$ falqon delete --queue jobs --tail 5
Deleted 5 messages from queue jobs

# Delete message at index 5
$ falqon delete --queue jobs --index 3 --index 5
Deleted 1 message from queue jobs

# Delete messages from index 5 to 10
$ falqon delete --queue jobs --range 5 10
Deleted 6 messages from queue jobs

# Delete message with ID 5
$ falqon delete --queue jobs --id 5 --id 1
Deleted 2 messages from queue jobs
```

Options:
- `-q`, `--queue=QUEUE`: Queue name (required)
- `--pending`: Delete only pending messages
- `--processing`: Delete only processing messages
- `--dead`: Delete only dead messages
- `--head N`: Delete first N messages
- `--tail N`: Delete last N messages
- `--index N`: Delete message at index N
- `--range N M`: Delete messages from index N to M
- `--id N`: Delete message with ID N

### Kill

The `kill` command kills messages in a queue.

```bash
# Kill all messages in the queue (by default only pending messages are killed)
$ falqon kill --queue jobs
Killed 10 messages from queue jobs

# Kill only pending messages
$ falqon kill --queue jobs --pending
Killed 10 pending messages from queue jobs

# Kill only processing messages
$ falqon kill --queue jobs --processing
Killed 1 processing message from queue jobs

# Kill first 5 messages
$ falqon kill --queue jobs --head 5
Killed 5 messages from queue jobs

# Kill last 5 messages
$ falqon kill --queue jobs --tail 5
Killed 5 messages from queue jobs

# Kill message at index 5
$ falqon kill --queue jobs --index 3 --index 5
Killed 1 message from queue jobs

# Kill messages from index 5 to 10
$ falqon kill --queue jobs --range 5 10
Killed 6 messages from queue jobs

# Kill message with ID 5
$ falqon kill --queue jobs --id 5 --id 1
Killed 2 messages from queue jobs
```

Options:
- `-q`, `--queue=QUEUE`: Queue name (required)
- `--pending`: Kill only pending messages
- `--processing`: Kill only processing messages
- `--head N`: Kill first N messages
- `--tail N`: Kill last N messages
- `--index N`: Kill message at index N
- `--range N M`: Kill messages from index N to M
- `--id N`: Kill message with ID N

### Clear

The `clear` command clears all messages in a queue.

```bash
# Clear all messages in the queue
$ falqon clear --queue jobs
Cleared 3 messages from queue jobs

# Clear only pending messages
$ falqon clear --queue jobs --pending
Cleared 3 messages from queue jobs

# Clear only processing messages
$ falqon clear --queue jobs --processing
Cleared 3 messages from queue jobs

# Clear only dead messages
$ falqon clear --queue jobs --dead
Cleared 3 messages from queue jobs
```

Options:

- `-q`, `--queue=QUEUE`: Queue name (required)
- `--pending`: Clear only pending messages
- `--processing`: Clear only processing messages
- `--dead`: Clear only dead messages

If none of the `--pending`, `--processing`, or `--dead` options are specified, all messages are cleared.
