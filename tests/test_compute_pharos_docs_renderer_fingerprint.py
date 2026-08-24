from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "bin"
    / "compute_pharos_docs_renderer_fingerprint.py"
)
SPEC = importlib.util.spec_from_file_location("docs_fingerprint", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


RUNTIME_SOURCE = """
pub fn handle_runtime_app_command_direct() {
    build_app_from_root();
}
/// Clears owned app-runtime fields after a clone leaves its request scope.
pub fn clear_cloned_app() {}

/// Builds one app artifact directly from the app-owned source root.
pub fn build_app_from_root() {
    build_dev_docs_pages();
}
fn finalize_artifact_manifest() {}

fn unrelated_runtime_function() {}

fn docs_manifest_string<'a>() {
    render_docs();
}
fn build_dev_docs_pages() {}
fn remove_non_manifest_yaml_from_artifact() {}
""".lstrip()


class DocsRendererFingerprintTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp_dir.name)
        inputs = {
            "Cargo.lock": "version = 4\n",
            "Cargo.toml": "[workspace]\n",
            "rust-toolchain.toml": "[toolchain]\nchannel = 'stable'\n",
            "scripts/build_docs.sh": "build docs\n",
            "scripts/build_native.sh": "build native\n",
            "src/runtime/docs.rs": "pub use docs::*;\n",
            "src/runtime/mod.rs": RUNTIME_SOURCE,
            "src/crates/pharos_runtime_docs/Cargo.toml": "[package]\nname = 'docs'\n",
            "src/crates/pharos_runtime_docs/src/lib.rs": "pub mod docs;\n",
            "src/crates/pharos_runtime_docs/src/docs.rs": "pub fn render() {}\n",
        }
        for relative_path, content in inputs.items():
            path = self.repo / relative_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def fingerprint(self) -> str:
        return MODULE.compute_fingerprint(self.repo)

    def test_fingerprint_is_stable(self) -> None:
        self.assertEqual(self.fingerprint(), self.fingerprint())
        self.assertTrue(self.fingerprint().startswith("v3:"))

    def test_unrelated_rust_file_does_not_change_fingerprint(self) -> None:
        before = self.fingerprint()
        unrelated = self.repo / "src/runtime/unrelated.rs"
        unrelated.write_text("pub fn unrelated() {}\n", encoding="utf-8")
        self.assertEqual(before, self.fingerprint())

    def test_unrelated_runtime_region_does_not_change_fingerprint(self) -> None:
        before = self.fingerprint()
        runtime = self.repo / "src/runtime/mod.rs"
        runtime.write_text(
            runtime.read_text(encoding="utf-8").replace(
                "fn unrelated_runtime_function() {}",
                "fn unrelated_runtime_function() { changed(); }",
            ),
            encoding="utf-8",
        )
        self.assertEqual(before, self.fingerprint())

    def test_native_release_orchestration_does_not_change_fingerprint(self) -> None:
        before = self.fingerprint()
        build_native = self.repo / "scripts/build_native.sh"
        build_native.write_text("build native with new release target\n", encoding="utf-8")
        self.assertEqual(before, self.fingerprint())

    def test_root_build_manifest_change_updates_fingerprint(self) -> None:
        before = self.fingerprint()
        cargo_manifest = self.repo / "Cargo.toml"
        cargo_manifest.write_text("[workspace]\nmembers = ['docs']\n", encoding="utf-8")
        self.assertNotEqual(before, self.fingerprint())

    def test_docs_crate_change_updates_fingerprint(self) -> None:
        before = self.fingerprint()
        docs = self.repo / "src/crates/pharos_runtime_docs/src/docs.rs"
        docs.write_text("pub fn render() { changed(); }\n", encoding="utf-8")
        self.assertNotEqual(before, self.fingerprint())

    def test_docs_entry_region_change_updates_fingerprint(self) -> None:
        before = self.fingerprint()
        runtime = self.repo / "src/runtime/mod.rs"
        runtime.write_text(
            runtime.read_text(encoding="utf-8").replace(
                "    render_docs();",
                "    render_docs_changed();",
            ),
            encoding="utf-8",
        )
        self.assertNotEqual(before, self.fingerprint())

    def test_missing_source_marker_fails_closed(self) -> None:
        runtime = self.repo / "src/runtime/mod.rs"
        runtime.write_text(
            runtime.read_text(encoding="utf-8").replace(
                "fn remove_non_manifest_yaml_from_artifact() {}",
                "fn renamed_cleanup() {}",
            ),
            encoding="utf-8",
        )
        with self.assertRaises(MODULE.FingerprintError):
            self.fingerprint()


if __name__ == "__main__":
    unittest.main()
