#!/bin/bash
set -euo pipefail

# Check for at least one argument
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <username> [sudo: 0 or 1] [\"group1,group2,...\"]"
    exit 1
fi

USERNAME="$1"
ADD_SUDO="${2:-0}"  # Default to 0 (do NOT add to sudo) if not provided

# Create the user with a home directory and bash shell
adduser --disabled-password --gecos "" "$USERNAME"

# Add user to sudo group only if second parameter is 1
if [ "$ADD_SUDO" -eq 1 ]; then
    usermod -aG sudo "$USERNAME"
fi

# Add user to additional groups if third parameter is provided
if [ -n "$3" ]; then
    usermod -aG "$3" "$USERNAME"
fi

# Create .ssh directory and authorized_keys file
mkdir -p /home/$USERNAME/.ssh
touch /home/$USERNAME/.ssh/authorized_keys

# Set correct permissions
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

echo "User $USERNAME created, sudo access: ${ADD_SUDO}, additional groups: ${3:-none}, and SSH directories set up."
