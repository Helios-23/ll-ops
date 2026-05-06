#!/bin/bash

# Check for username argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME="$1"

# Find zombie processes for the user and kill their parents
ps -u "$USERNAME" -o pid,ppid,state | awk -v user="$USERNAME" '$3=="Z" {print $2}' | sort -u | xargs kill -9 2>/dev/null || true

echo "Attempted to kill parent processes of zombies for user: $USERNAME"
