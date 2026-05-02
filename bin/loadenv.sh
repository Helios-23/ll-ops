#!/bin/bash
# Load environment variables from KeePassXC database
# Usage: source ./bin/loadenv.sh
# Or: . ./bin/loadenv.sh

OPS_ROOT="/Users/H23/logicallight/Epytype"
DB="$OPS_ROOT/ops/kpxc/epytype_ops.kdbx"
KEEPASSXC="/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli"

if [ ! -f "$DB" ]; then
  echo "ERROR: Database not found at $DB"
  return 1 2>/dev/null || exit 1
fi

printf "Database password: "
read -s DB_PASS
echo ""

# Query function
query_entry() {
  echo "$DB_PASS" | "$KEEPASSXC" show -s "$DB" "$1" 2>/dev/null
}

# Get Hetzner token
HCLOUD_TOKEN=$(query_entry "Hetzner devops API token" | awk '/Password:/ {print $2}')
if [ -z "$HCLOUD_TOKEN" ]; then
  echo "ERROR: Failed to load HCLOUD_TOKEN"
  unset DB_PASS
  return 1 2>/dev/null || exit 1
fi
export HCLOUD_TOKEN

# Get Cloudflare credentials
CF_ENTRY=$(query_entry "cloudflare epytype.org token")
CLOUDFLARE_API_TOKEN=$(echo "$CF_ENTRY" | awk '/Password:/ {print $2}')
CLOUDFLARE_ZONE_ID=$(echo "$CF_ENTRY" | awk '/UserName:/ {print $2}')

if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ]; then
  echo "ERROR: Failed to load Cloudflare credentials"
  unset DB_PASS
  return 1 2>/dev/null || exit 1
fi
export CLOUDFLARE_API_TOKEN
export CLOUDFLARE_ZONE_ID

# Cleanup
unset DB_PASS
pkill -f "keepassxc-cli" 2>/dev/null

echo "Environment variables loaded."
