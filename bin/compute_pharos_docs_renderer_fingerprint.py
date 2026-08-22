#!/usr/bin/env python3
"""Compute the narrow source fingerprint for the host-native docs renderer."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
from typing import Protocol


FINGERPRINT_VERSION = "v2"
MAX_INPUT_FILES = 1_000
MAX_INPUT_BYTES = 64 * 1024 * 1024
WHOLE_FILE_INPUTS = (
    "scripts/build_docs.sh",
    "scripts/build_native.sh",
    "src/runtime/docs.rs",
)
DIRECTORY_INPUTS = ("src/crates/pharos_runtime_docs",)
RUNTIME_REGIONS = (
    (
        "app-build-command-entry",
        "pub fn handle_runtime_app_command_direct(",
        "/// Clears owned app-runtime fields after a clone leaves its request scope.",
    ),
    (
        "app-build-render-entry",
        "/// Builds one app artifact directly from the app-owned source root.",
        "fn finalize_artifact_manifest(",
    ),
    (
        "dev-docs-renderer",
        "fn docs_manifest_string<'a>(",
        "fn remove_non_manifest_yaml_from_artifact(",
    ),
)


class FingerprintError(RuntimeError):
    """Raised when the fingerprint contract cannot be evaluated safely."""


class Digest(Protocol):
    """Minimal interface shared by hashlib digest implementations."""

    def update(self, data: bytes) -> None:
        """Add bytes to the digest state."""


def _safe_file(repo_root: Path, relative_path: str) -> Path:
    path = repo_root / relative_path
    try:
        resolved = path.resolve(strict=True)
    except OSError as error:
        raise FingerprintError(
            f"required fingerprint input is unavailable: {relative_path}"
        ) from error
    if path.is_symlink() or not resolved.is_file() or not resolved.is_relative_to(repo_root):
        raise FingerprintError(f"unsafe fingerprint input: {relative_path}")
    return resolved


def _read_bounded(path: Path, relative_path: str, remaining_bytes: int) -> bytes:
    size = path.stat().st_size
    if size > remaining_bytes:
        raise FingerprintError(
            f"docs-renderer fingerprint input exceeds the safety limit: {relative_path}"
        )
    content = path.read_bytes()
    if len(content) > remaining_bytes:
        raise FingerprintError(
            f"docs-renderer fingerprint input grew beyond the safety limit: {relative_path}"
        )
    return content


def _update_digest(digest: Digest, label: str, content: bytes) -> int:
    digest.update(label.encode("utf-8"))
    digest.update(b"\0")
    digest.update(content)
    digest.update(b"\0")
    return len(content)


def _extract_unique_region(source: str, label: str, start: str, end: str) -> str:
    if source.count(start) != 1 or source.count(end) != 1:
        raise FingerprintError(f"docs-renderer source markers are not unique: {label}")
    start_index = source.index(start)
    end_index = source.index(end, start_index + len(start))
    if end_index <= start_index:
        raise FingerprintError(f"docs-renderer source markers are out of order: {label}")
    return source[start_index:end_index]


def compute_fingerprint(repo_path: Path) -> str:
    """Return a versioned digest of inputs that can alter docs-renderer behavior."""
    try:
        repo_root = repo_path.resolve(strict=True)
    except OSError as error:
        raise FingerprintError(f"Pharos repository is unavailable: {repo_path}") from error
    if not repo_root.is_dir():
        raise FingerprintError(f"Pharos repository is not a directory: {repo_path}")

    input_paths = set(WHOLE_FILE_INPUTS)
    for directory_text in DIRECTORY_INPUTS:
        directory = repo_root / directory_text
        try:
            resolved_directory = directory.resolve(strict=True)
        except OSError as error:
            raise FingerprintError(
                f"required fingerprint directory is unavailable: {directory_text}"
            ) from error
        if (
            directory.is_symlink()
            or not resolved_directory.is_dir()
            or not resolved_directory.is_relative_to(repo_root)
        ):
            raise FingerprintError(f"unsafe fingerprint directory: {directory_text}")
        for path in resolved_directory.rglob("*"):
            if path.is_symlink():
                raise FingerprintError(
                    f"symlinks are not allowed in fingerprint inputs: {path.relative_to(repo_root)}"
                )
            if path.is_file():
                input_paths.add(path.relative_to(repo_root).as_posix())

    if len(input_paths) > MAX_INPUT_FILES:
        raise FingerprintError("docs-renderer fingerprint input count exceeds the safety limit")

    digest = hashlib.sha256()
    total_bytes = 0
    for relative_path in sorted(input_paths):
        path = _safe_file(repo_root, relative_path)
        content = _read_bounded(path, relative_path, MAX_INPUT_BYTES - total_bytes)
        total_bytes += _update_digest(digest, f"file:{relative_path}", content)

    runtime_path = _safe_file(repo_root, "src/runtime/mod.rs")
    try:
        runtime_content = _read_bounded(
            runtime_path,
            "src/runtime/mod.rs",
            MAX_INPUT_BYTES - total_bytes,
        )
        runtime_source = runtime_content.decode("utf-8")
    except UnicodeDecodeError as error:
        raise FingerprintError("src/runtime/mod.rs is not valid UTF-8") from error
    for label, start, end in RUNTIME_REGIONS:
        region = _extract_unique_region(runtime_source, label, start, end)
        total_bytes += _update_digest(digest, f"region:{label}", region.encode("utf-8"))
        if total_bytes > MAX_INPUT_BYTES:
            raise FingerprintError("docs-renderer fingerprint inputs exceed the safety limit")

    return f"{FINGERPRINT_VERSION}:{digest.hexdigest()}"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compute the Pharos host-native docs-renderer fingerprint."
    )
    parser.add_argument("repo", type=Path, help="path to the Pharos repository root")
    args = parser.parse_args()
    try:
        print(compute_fingerprint(args.repo))
    except FingerprintError as error:
        parser.error(str(error))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
