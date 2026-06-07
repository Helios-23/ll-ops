#!/usr/bin/env bash
set -euo pipefail

FORGEJO_WEB_URL="https://repo.epytype.org"
FORGEJO_HOST="repo.epytype.org"
FORGEJO_HOST_IP="195.201.226.77"
FORGEJO_PORT="2222"
FORGEJO_GIT_USER="git"
DEFAULT_KEY_PATH="~/.ssh/r.epytype.org"
REPOS=(ops epytype docstore kernel lang spec)

usage() {
  cat <<'EOF'
Bootstrap Forgejo SSH access and clone Epytype repositories.

Run this from the root of your local Epytype workspace.

Usage:
  bash ./bootstrap_user_setup.sh --user <forgejo_username> --key <private_key_path> [options]

Required:
  --user USER        Your Forgejo username. Used for guidance output.
  --key PATH         Private SSH key path to use for repo.epytype.org.

Options:
  --skip-clone       Configure SSH and test auth, but do not clone repositories
  --no-open          Do not open the Forgejo SSH key page on macOS when auth is missing
  --help             Show this help text

Example:
  bash ./bootstrap_user_setup.sh --user alice --key ~/.ssh/r.epytype.org
EOF
}

expand_path() {
  case "$1" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${1#~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

log() {
  printf '\n==> %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1" >&2
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

backup_file_once() {
  local file="$1"
  local backup="$file.bak"
  if [ -f "$file" ] && [ ! -f "$backup" ]; then
    cp "$file" "$backup"
  fi
}

replace_managed_block() {
  local file="$1"
  local start_marker="$2"
  local end_marker="$3"
  local block_content="$4"
  local tmp
  tmp="$(mktemp)"

  if [ -f "$file" ] && grep -Fq "$start_marker" "$file"; then
    awk -v start="$start_marker" -v end="$end_marker" '
      $0 == start { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "$file" > "$tmp"
  elif [ -f "$file" ]; then
    cat "$file" > "$tmp"
  fi

  {
    [ -s "$tmp" ] && cat "$tmp"
    [ -s "$tmp" ] && printf '\n'
    printf '%s\n' "$block_content"
  } > "$file"

  rm -f "$tmp"
}

ensure_workspace_root() {
  WORKSPACE_DIR="$PWD"
  [ "$(basename "$WORKSPACE_DIR")" = "Epytype" ] || die "Run this script from the root of your local Epytype workspace"
}

ensure_ssh_layout() {
  log "Ensuring SSH directories exist"
  mkdir -p "$HOME/.ssh" "$HOME/.ssh/socket"
  chmod 700 "$HOME/.ssh" "$HOME/.ssh/socket"
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
}

ensure_ssh_config() {
  log "Writing managed SSH config blocks"
  backup_file_once "$SSH_CONFIG"

  replace_managed_block "$SSH_CONFIG" \
    "# BEGIN EPYTYPE GLOBAL SSH SETTINGS" \
    "# END EPYTYPE GLOBAL SSH SETTINGS" \
    "# BEGIN EPYTYPE GLOBAL SSH SETTINGS
IgnoreUnknown UseKeychain
Host *
    AddressFamily inet
    Protocol 2
    ControlMaster auto
    ControlPath ~/.ssh/socket/%r@%h-%p
    ControlPersist 600
    PreferredAuthentications publickey,password
    UseKeychain yes
    AddKeysToAgent yes
    Ciphers aes256-ctr,aes256-gcm@openssh.com,aes192-ctr,aes128-ctr,aes128-gcm@openssh.com
    MACs hmac-sha2-256,hmac-sha2-512,hmac-sha1
    KexAlgorithms diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256,ecdh-sha2-nistp256,ecdh-sha2-nistp384
    PubkeyAcceptedAlgorithms ssh-ed25519,rsa-sha2-256,rsa-sha2-512,ecdsa-sha2-nistp256
    HostKeyAlgorithms ssh-ed25519,rsa-sha2-256,rsa-sha2-512,ecdsa-sha2-nistp256
# END EPYTYPE GLOBAL SSH SETTINGS"

  replace_managed_block "$SSH_CONFIG" \
    "# BEGIN EPYTYPE FORGEJO SSH SETTINGS" \
    "# END EPYTYPE FORGEJO SSH SETTINGS" \
    "# BEGIN EPYTYPE FORGEJO SSH SETTINGS
# Managed by bootstrap_user_setup.sh
Host ${FORGEJO_HOST}
    HostName ${FORGEJO_HOST_IP}
    Port ${FORGEJO_PORT}
    User ${FORGEJO_GIT_USER}
    IdentityFile ${KEY_PATH}
    IdentitiesOnly yes
# END EPYTYPE FORGEJO SSH SETTINGS"
}

ensure_key_exists() {
  log "Checking SSH key files"
  [ -f "$KEY_PATH" ] || die "Private key not found: $KEY_PATH"
  [ -f "$PUBKEY_PATH" ] || die "Public key not found: $PUBKEY_PATH"
}

try_add_key_to_agent() {
  if ! command -v ssh-add >/dev/null 2>&1; then
    return
  fi

  log "Adding key to SSH agent when available"
  if [ "$(uname -s)" = "Darwin" ]; then
    ssh-add --apple-use-keychain "$KEY_PATH" >/dev/null 2>&1 || true
  else
    ssh-add "$KEY_PATH" >/dev/null 2>&1 || true
  fi
}

copy_pubkey_to_clipboard() {
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$PUBKEY_PATH"
    printf 'Copied %s to clipboard.\n' "$PUBKEY_PATH"
  fi
}

open_forgejo_key_page() {
  if [ "$OPEN_BROWSER" -eq 1 ] && [ "$(uname -s)" = "Darwin" ] && command -v open >/dev/null 2>&1; then
    open "${FORGEJO_WEB_URL}/user/settings/keys" >/dev/null 2>&1 || true
  fi
}

test_ssh_auth() {
  log "Testing SSH authentication"
  set +e
  SSH_TEST_OUTPUT="$(ssh -T -o BatchMode=yes "${FORGEJO_GIT_USER}@${FORGEJO_HOST}" 2>&1)"
  SSH_TEST_RC=$?
  set -e

  printf '%s\n' "$SSH_TEST_OUTPUT"

  case "$SSH_TEST_OUTPUT" in
    *"successfully authenticated over SSH"*) SSH_READY=1 ;;
    *) SSH_READY=0 ;;
  esac

  if [ "$SSH_READY" -eq 1 ]; then
    log "SSH authentication is ready"
  else
    warn "SSH authentication is not ready yet"
  fi
}

print_manual_key_step() {
  log "Continue with the Forgejo key-registration step"
  printf '1. Sign in to %s as %s\n' "$FORGEJO_WEB_URL" "$FORGEJO_USERNAME"
  printf '2. Open: %s/user/settings/keys\n' "$FORGEJO_WEB_URL"
  printf '3. Add this public key:\n\n'
  cat "$PUBKEY_PATH"
  printf '\n'
  copy_pubkey_to_clipboard
  open_forgejo_key_page
  printf '\n4. Save the key in Forgejo\n'
  printf '5. Rerun this script from %s\n' "$WORKSPACE_DIR"
}

clone_repositories() {
  [ "$SKIP_CLONE" -eq 0 ] || return

  log "Cloning repositories into $WORKSPACE_DIR"

  local repo target
  for repo in "${REPOS[@]}"; do
    target="$WORKSPACE_DIR/$repo"
    if [ -d "$target/.git" ]; then
      printf 'Skipping %s (already cloned)\n' "$repo"
      continue
    fi
    if [ -e "$target" ]; then
      warn "Skipping $repo because $target already exists and is not a git checkout"
      continue
    fi
    git clone "git@${FORGEJO_HOST}:Epytype/${repo}.git" "$target"
  done
}

verify_remote() {
  local repo_dir="$WORKSPACE_DIR/epytype"
  [ -d "$repo_dir/.git" ] || return

  log "Verifying origin remote for epytype"
  git -C "$repo_dir" remote -v
}

FORGEJO_USERNAME=""
KEY_PATH=""
SKIP_CLONE=0
OPEN_BROWSER=1
SSH_CONFIG="$HOME/.ssh/config"
SSH_READY=0
SSH_TEST_OUTPUT=""
SSH_TEST_RC=0
WORKSPACE_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --user)
      [ $# -ge 2 ] || die "--user requires a value"
      FORGEJO_USERNAME="$2"
      shift 2
      ;;
    --key)
      [ $# -ge 2 ] || die "--key requires a value"
      KEY_PATH="$2"
      shift 2
      ;;
    --skip-clone)
      SKIP_CLONE=1
      shift
      ;;
    --no-open)
      OPEN_BROWSER=0
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[ -n "$FORGEJO_USERNAME" ] || die "--user is required"
[ -n "$KEY_PATH" ] || KEY_PATH="$DEFAULT_KEY_PATH"

ensure_workspace_root
KEY_PATH="$(expand_path "$KEY_PATH")"
PUBKEY_PATH="${KEY_PATH}.pub"

ensure_ssh_layout
ensure_key_exists
ensure_ssh_config
try_add_key_to_agent
test_ssh_auth

if [ "$SSH_READY" -ne 1 ]; then
  print_manual_key_step
  exit 1
fi

clone_repositories
verify_remote

log "Bootstrap complete"
printf 'Workspace: %s\n' "$WORKSPACE_DIR"
printf 'SSH key: %s\n' "$KEY_PATH"
