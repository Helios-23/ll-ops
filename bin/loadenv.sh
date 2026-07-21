#!/bin/bash
# Load environment variables from KeePassXC database
# Usage: source ./bin/loadenv.sh
# Or: . ./bin/loadenv.sh

OPS_ROOT="/Users/H23/logicallight/LL/ops"
#DB="$OPS_ROOT/kpxc/logicl_ops.kdbx"
KEEPASSXC="/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli"

#if [ ! -f "$DB" ]; then
#  echo "ERROR: Database not found at $DB"
#  return 1 2>/dev/null || exit 1
#fi

# Allow editor/tooling shells to skip the interactive KeePass prompt.
# This keeps Zed-launched command shells from blocking unrelated work.
if [ "${EPYTYPE_FORCE_LOADENV:-0}" != "1" ]; then
  case "${TERM_PROGRAM:-}" in
    zed|vscode)
      if [ -z "${KEEPASSXC_DB_PASSWORD:-}" ] && [ -z "${DB_PASS:-}" ]; then
        echo "Skipping KeePass credential prompt in editor/tooling shell."
        return 0 2>/dev/null || exit 0
      fi
      ;;
  esac
  if [ "${ZED_TERM:-0}" = "1" ] || [ "${ZED_EDITOR:-0}" = "1" ] || [ "${EPYTYPE_SKIP_LOADENV:-0}" = "1" ]; then
    if [ -z "${KEEPASSXC_DB_PASSWORD:-}" ] && [ -z "${DB_PASS:-}" ]; then
      echo "Skipping KeePass credential prompt for non-ops shell session."
      return 0 2>/dev/null || exit 0
    fi
  fi
  if [ ! -t 0 ] && [ -z "${KEEPASSXC_DB_PASSWORD:-}" ] && [ -z "${DB_PASS:-}" ]; then
    echo "Skipping KeePass credential prompt without interactive stdin."
    return 0 2>/dev/null || exit 0
  fi
fi

#if [ -n "${KEEPASSXC_DB_PASSWORD:-}" ]; then
#  DB_PASS="$KEEPASSXC_DB_PASSWORD"
#elif [ -n "${DB_PASS:-}" ]; then
#  DB_PASS="$DB_PASS"
#else
#  printf "Database password: "
#  read -s DB_PASS
#  echo ""
#fi

# Check for empty password
#if [ -z "$DB_PASS" ]; then
#  echo "ERROR: Password cannot be empty"
#  return 1 2>/dev/null || exit 1
#fi

# Query function
query_entry() {
  local entry="$1"
  echo "$DB_PASS" | "$KEEPASSXC" show -s "$DB" "$entry" 2>&1
}

# Test password with Hetzner token query
OUTPUT=$(query_entry "Hetzner devops API token")
if echo "$OUTPUT" | grep -q "Invalid credentials"; then
  echo "ERROR: Invalid database password"
  unset DB_PASS
  pkill -f "keepassxc-cli" 2>/dev/null
  return 1 2>/dev/null || exit 1
fi

HCLOUD_TOKEN=$(echo "$OUTPUT" | awk '/Password:/ {print $2}')
if [ -z "$HCLOUD_TOKEN" ]; then
  echo "ERROR: Failed to load HCLOUD_TOKEN"
  unset DB_PASS
  pkill -f "keepassxc-cli" 2>/dev/null
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
  pkill -f "keepassxc-cli" 2>/dev/null
  return 1 2>/dev/null || exit 1
fi
export CLOUDFLARE_API_TOKEN
export CLOUDFLARE_ZONE_ID

# Cleanup
unset DB_PASS
pkill -f "keepassxc-cli" 2>/dev/null

echo "Environment variables loaded."
