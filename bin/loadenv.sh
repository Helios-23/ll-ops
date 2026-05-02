#!/bin/bash
# Load environment variables from KeePassXC database
# Usage: source ./bin/loadenv.sh
# Or: . ./bin/loadenv.sh

# Root directory where the ops repository is installed
# Update this if you clone the repo to a different location
OPS_ROOT="/Users/H23/logicallight/epytype.org"

DB="$OPS_ROOT/ops/kpxc/epytype_ops.kdbx"
KEEPASSXC="/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli"

# Check if database exists
if [ ! -f "$DB" ]; then
  echo "ERROR: Database not found at $DB"
  return 1 2>/dev/null || exit 1
fi

# Read database password
printf "Database password: "
read -s DB_PASS
echo

# Function to query entry
query_entry() {
  echo "$DB_PASS" | "$KEEPASSXC" show -s "$DB" "$1" 2>&1
}

# Test if password is correct
TEST=$(query_entry "Hetzner devops API token")
if echo "$TEST" | grep -q "Invalid credentials"; then
  echo "ERROR: Incorrect database password"
  unset DB_PASS
  return 1 2>/dev/null || exit 1
fi

# Get Hetzner token (password field)
HCLOUD_TOKEN=$(query_entry "Hetzner devops API token" | awk '/Password:/ {print $2}')
if [ -z "$HCLOUD_TOKEN" ]; then
  echo "ERROR: Failed to load HCLOUD_TOKEN"
  unset DB_PASS
  return 1 2>/dev/null || exit 1
fi
export HCLOUD_TOKEN

# Get Cloudflare token (password) and zone ID (username)
CF_ENTRY=$(query_entry "cloudflare epytype.org token")

CLOUDFLARE_API_TOKEN=$(echo "$CF_ENTRY" | awk '/Password:/ {print $2}')
CLOUDFLARE_ZONE_ID=$(echo "$CF_ENTRY" | awk '/UserName:/ {print $2}')

if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ]; then
  echo "ERROR: Failed to load Cloudflare credentials"
  echo "  CLOUDFLARE_API_TOKEN: ${CLOUDFLARE_API_TOKEN:-empty}"
  echo "  CLOUDFLARE_ZONE_ID: ${CLOUDFLARE_ZONE_ID:-empty}"
  unset DB_PASS
  return 1 2>/dev/null || exit 1
fi
export CLOUDFLARE_API_TOKEN
export CLOUDFLARE_ZONE_ID

# Clear DB_PASS
unset DB_PASS

echo "Environment variables loaded:"
echo "  HCLOUD_TOKEN is set"
echo "  CLOUDFLARE_API_TOKEN is set"
echo "  CLOUDFLARE_ZONE_ID: $CLOUDFLARE_ZONE_ID"
