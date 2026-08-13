#!/usr/bin/env python3
"""Reject tracked or staged policy files that are not Ansible Vault ciphertext."""

from __future__ import annotations

import argparse
import fnmatch
import re
import subprocess
import sys
from pathlib import Path

POLICY_PATH = Path("config/ansible-vault-required-files.txt")
VAULT_HEADER = re.compile(
    rb"^\$ANSIBLE_VAULT;[0-9]+\.[0-9]+;[A-Z0-9_]+(?:;[^;\r\n]+)?$"
)
HEX_PAYLOAD = re.compile(rb"^[0-9a-fA-F]+$")


def git(repo_root: Path, *args: str, check: bool = True) -> bytes:
    result = subprocess.run(
        ["git", *args],
        cwd=repo_root,
        check=check,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout


def repository_root() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    return Path(result.stdout.strip())


def load_patterns(repo_root: Path) -> list[str]:
    policy = repo_root / POLICY_PATH
    try:
        lines = policy.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise RuntimeError(f"cannot read policy file {POLICY_PATH}: {error}") from error

    patterns = [line.strip() for line in lines if line.strip() and not line.lstrip().startswith("#")]
    if not patterns:
        raise RuntimeError(f"policy file {POLICY_PATH} contains no protected patterns")
    return patterns


def matches_policy(path: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns)


def nul_paths(output: bytes) -> list[str]:
    return [item.decode("utf-8", "surrogateescape") for item in output.split(b"\0") if item]


def protected_files(repo_root: Path, patterns: list[str], staged: bool) -> list[str]:
    if staged:
        paths = nul_paths(
            git(repo_root, "diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z")
        )
    else:
        paths = nul_paths(git(repo_root, "ls-files", "-z"))
    return sorted(path for path in paths if matches_policy(path, patterns))


def read_content(repo_root: Path, path: str, staged: bool) -> bytes:
    if staged:
        return git(repo_root, "show", f":{path}")
    return (repo_root / path).read_bytes()


def validate_vault(content: bytes) -> str | None:
    lines = content.splitlines()
    if not lines:
        return "file is empty"
    if not VAULT_HEADER.fullmatch(lines[0]):
        return "first line is not a valid Ansible Vault header"
    if len(lines) == 1:
        return "vault payload is missing"
    for line in lines[1:]:
        if not line:
            return "vault payload contains a blank line"
        if not HEX_PAYLOAD.fullmatch(line):
            return "vault payload contains non-hexadecimal data"
        if len(line) % 2:
            return "vault payload contains an odd-length hexadecimal line"
    return None


def remediation(path: str) -> str:
    return f"ansible-vault encrypt {path} --vault-id devops@.vault_devops"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify that policy-protected files contain Ansible Vault ciphertext."
    )
    parser.add_argument(
        "--staged",
        action="store_true",
        help="validate protected files in the Git index instead of the working tree",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        repo_root = repository_root()
        patterns = load_patterns(repo_root)
        paths = protected_files(repo_root, patterns, args.staged)
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f"vault guard error: {error}", file=sys.stderr)
        return 2

    failures = 0
    for path in paths:
        try:
            failure = validate_vault(read_content(repo_root, path, args.staged))
        except (OSError, subprocess.CalledProcessError) as error:
            failure = f"cannot read file: {error}"
        if failure:
            failures += 1
            print(f"vault guard failed: {path}: {failure}", file=sys.stderr)
            print(f"remediation: {remediation(path)}", file=sys.stderr)

    if failures:
        print(f"vault guard rejected {failures} file(s); file contents were not displayed", file=sys.stderr)
        return 1

    scope = "staged" if args.staged else "tracked"
    print(f"vault guard passed: {len(paths)} protected {scope} file(s) are encrypted")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
