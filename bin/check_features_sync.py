#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

OPS_DIR = Path(__file__).resolve().parents[1]
FEATURES_MD = OPS_DIR / "FEATURES.md"
ROLES_DIR = OPS_DIR / "roles"

BLOCK_TAG_RE = re.compile(r"^\s*-\s*([A-Za-z0-9_:-]+)\s*$")
INLINE_TAGS_RE = re.compile(r"\btags:\s*([^#\n]+)")
BACKTICK_RE = re.compile(r"`([A-Za-z0-9_./-]+)`")

DOCUMENTED_SECTIONS = {
    "tag index": {
        "start": "## Complete Tag Index",
        "end": "## Role Notes",
        "include": lambda token: "/" not in token and not token.endswith(".yml"),
    },
    "playbook list": {
        "start": "## Playbook Quick Map",
        "end": "## Examples",
        "include": lambda token: token.endswith(".yml"),
    },
    "role list": {
        "start": "## Role Notes",
        "end": None,
        "include": lambda token: token.startswith("roles/"),
    },
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def section_between(text: str, start: str, end: str | None) -> str:
    try:
        section_start = text.index(start)
        section_end = len(text) if end is None else text.index(end, section_start)
    except ValueError as exc:
        raise SystemExit(
            f"Could not find required section markers in {FEATURES_MD}: {exc}"
        )
    return text[section_start:section_end]


def extract_tags_from_yaml(path: Path) -> set[str]:
    tags: set[str] = set()
    lines = read_text(path).splitlines()
    i = 0

    while i < len(lines):
        line = lines[i]

        if re.search(r"\btags:\s*$", line):
            i += 1
            while i < len(lines):
                match = BLOCK_TAG_RE.match(lines[i])
                if not match:
                    break
                tags.add(match.group(1))
                i += 1
            continue

        match = INLINE_TAGS_RE.search(line)
        if match:
            tags.update(
                part.strip() for part in match.group(1).split(",") if part.strip()
            )

        i += 1

    return tags


def actual_tags() -> set[str]:
    yaml_files = list(OPS_DIR.glob("*.yml")) + list(ROLES_DIR.rglob("*.yml"))
    tags: set[str] = set()
    for path in sorted(yaml_files):
        tags.update(extract_tags_from_yaml(path))
    return tags


def actual_playbooks() -> set[str]:
    return {path.name for path in OPS_DIR.glob("*.yml")}


def actual_roles() -> set[str]:
    return {f"roles/{path.name}" for path in ROLES_DIR.iterdir() if path.is_dir()}


def documented_items(text: str, label: str) -> set[str]:
    config = DOCUMENTED_SECTIONS[label]
    section = section_between(text, config["start"], config["end"])
    return {token for token in BACKTICK_RE.findall(section) if config["include"](token)}


def report_diff(label: str, actual: set[str], documented: set[str]) -> bool:
    missing = sorted(actual - documented)
    extra = sorted(documented - actual)

    if not missing and not extra:
        return False

    print(f"FEATURES.md {label} is out of sync.", file=sys.stderr)
    if missing:
        print(f"\nMissing {label} in FEATURES.md:", file=sys.stderr)
        for item in missing:
            print(f"  - {item}", file=sys.stderr)
    if extra:
        print(f"\nDocumented {label} not found in ops:", file=sys.stderr)
        for item in extra:
            print(f"  - {item}", file=sys.stderr)
    return True


def main() -> int:
    text = read_text(FEATURES_MD)
    checks = [
        ("tag index", actual_tags()),
        ("playbook list", actual_playbooks()),
        ("role list", actual_roles()),
    ]

    failed = any(
        report_diff(label, actual, documented_items(text, label))
        for label, actual in checks
    )
    if failed:
        return 1

    print(
        "FEATURES.md matches ops automation "
        f"({len(checks[1][1])} playbooks, {len(checks[2][1])} roles, {len(checks[0][1])} tags)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
