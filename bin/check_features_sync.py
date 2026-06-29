#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

OPS_DIR = Path(__file__).resolve().parents[1]
DOCS_DIR = OPS_DIR / "docs"
FEATURES_MD = DOCS_DIR / "FEATURES.md"
RUNBOOK_MD = DOCS_DIR / "OPERATOR_RUNBOOK.md"
DOCS_INDEX_MD = DOCS_DIR / "README.md"
AI_SERVER_MD = DOCS_DIR / "AI_SERVER.md"
OPS_README_MD = OPS_DIR / "README.md"
ROLES_DIR = OPS_DIR / "roles"
AI_DEFAULTS_YML = ROLES_DIR / "ai_rig" / "defaults" / "main.yml"

BLOCK_TAG_RE = re.compile(r"^\s*-\s*([A-Za-z0-9_:-]+)\s*$")
INLINE_TAGS_RE = re.compile(r"\btags:\s*([^#\n]+)")
BACKTICK_RE = re.compile(r"`([A-Za-z0-9_:./-]+)`")
DOUBLE_QUOTED_LIST_ITEM_RE = re.compile(r'^\s*-\s*"([^"]+)"')
AI_MODELS_SECTION_RE = re.compile(
    r"<!-- ai_models:start -->(.*?)<!-- ai_models:end -->", re.S
)
AI_MODELS_REMOVE_SECTION_RE = re.compile(
    r"<!-- ai_models_remove:start -->(.*?)<!-- ai_models_remove:end -->", re.S
)

DOCUMENTED_SECTIONS = {
    "tag index": {
        "start": "## Complete Tag Index",
        "end": "## Role Notes",
        "include": lambda token: "/" not in token and not token.endswith(".yml"),
    },
    "playbook list": {
        "start": "## Playbook Quick Map",
        "end": "## Examples",
        "include": lambda token: token.endswith(".yml") or token.endswith(".yaml"),
    },
    "role list": {
        "start": "## Role Notes",
        "end": None,
        "include": lambda token: token.startswith("roles/"),
    },
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def require_file(path: Path) -> None:
    if not path.is_file():
        raise SystemExit(f"Required documentation file is missing: {path}")


def extract_yaml_list(path: Path, key: str) -> list[str]:
    lines = read_text(path).splitlines()
    items: list[str] = []
    in_section = False

    for line in lines:
        if not in_section:
            if re.match(rf"^{re.escape(key)}:\s*$", line):
                in_section = True
            continue

        if line and not line.startswith((" ", "\t")):
            break

        match = DOUBLE_QUOTED_LIST_ITEM_RE.match(line)
        if match:
            items.append(match.group(1))

    return items


def extract_marked_models(text: str, pattern: re.Pattern[str], label: str) -> list[str]:
    match = pattern.search(text)
    if not match:
        raise SystemExit(f"Could not find required {label} markers in {AI_SERVER_MD}")
    return BACKTICK_RE.findall(match.group(1))


def report_ordered_diff(label: str, actual: list[str], documented: list[str]) -> bool:
    if actual == documented:
        return False

    print(f"{label} is out of sync.", file=sys.stderr)
    print("\nConfigured:", file=sys.stderr)
    for item in actual:
        print(f"  - {item}", file=sys.stderr)
    print("\nDocumented:", file=sys.stderr)
    for item in documented:
        print(f"  - {item}", file=sys.stderr)
    return True


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
    yaml_files = (
        list(OPS_DIR.glob("*.yml"))
        + list(OPS_DIR.glob("*.yaml"))
        + list(ROLES_DIR.rglob("*.yml"))
        + list(ROLES_DIR.rglob("*.yaml"))
    )
    tags: set[str] = set()
    for path in sorted(yaml_files):
        tags.update(extract_tags_from_yaml(path))
    return tags


def actual_playbooks() -> set[str]:
    return {
        path.name
        for path in list(OPS_DIR.glob("*.yml")) + list(OPS_DIR.glob("*.yaml"))
    }


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
    for path in (FEATURES_MD, RUNBOOK_MD, DOCS_INDEX_MD, AI_SERVER_MD, OPS_README_MD, AI_DEFAULTS_YML):
        require_file(path)

    text = read_text(FEATURES_MD)
    docs_index_text = read_text(DOCS_INDEX_MD)
    ai_server_text = read_text(AI_SERVER_MD)
    ops_readme_text = read_text(OPS_README_MD)
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

    ai_models_failed = any(
        [
            report_ordered_diff(
                "AI model inventory in AI_SERVER.md",
                extract_yaml_list(AI_DEFAULTS_YML, "ai_models"),
                extract_marked_models(ai_server_text, AI_MODELS_SECTION_RE, "ai_models"),
            ),
            report_ordered_diff(
                "AI model removal inventory in AI_SERVER.md",
                extract_yaml_list(AI_DEFAULTS_YML, "ai_models_remove"),
                extract_marked_models(
                    ai_server_text, AI_MODELS_REMOVE_SECTION_RE, "ai_models_remove"
                ),
            ),
        ]
    )
    if ai_models_failed:
        return 1

    missing_links: list[str] = []
    if (
        "OPERATOR_RUNBOOK.md" not in docs_index_text
        or "FEATURES.md" not in docs_index_text
        or "AI_SERVER.md" not in docs_index_text
    ):
        missing_links.append(
            "ops/docs/README.md must link OPERATOR_RUNBOOK.md, FEATURES.md, and AI_SERVER.md"
        )
    if "docs/OPERATOR_RUNBOOK.md" not in ops_readme_text or "docs/FEATURES.md" not in ops_readme_text:
        missing_links.append("ops/README.md must link docs/OPERATOR_RUNBOOK.md and docs/FEATURES.md")
    if missing_links:
        print("Documentation links are out of sync.", file=sys.stderr)
        for item in missing_links:
            print(f"  - {item}", file=sys.stderr)
        return 1

    print(
        "ops docs guard passed: FEATURES.md matches ops automation "
        f"({len(checks[1][1])} playbooks, {len(checks[2][1])} roles, {len(checks[0][1])} tags)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
