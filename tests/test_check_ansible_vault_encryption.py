from __future__ import annotations

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "check_ansible_vault_encryption.py"
SPEC = importlib.util.spec_from_file_location("vault_guard", SCRIPT)
assert SPEC and SPEC.loader
VAULT_GUARD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VAULT_GUARD)

VALID_VAULT = b"$ANSIBLE_VAULT;1.2;AES256;devops\n" + (b"ab" * 40) + b"\n" + (b"01" * 8) + b"\n"


class VaultEnvelopeTests(unittest.TestCase):
    def test_valid_vault_with_identity_passes(self) -> None:
        self.assertIsNone(VAULT_GUARD.validate_vault(VALID_VAULT))

    def test_plaintext_yaml_fails(self) -> None:
        self.assertIn("header", VAULT_GUARD.validate_vault(b"password: secret\n"))

    def test_plaintext_after_header_fails(self) -> None:
        failure = VAULT_GUARD.validate_vault(
            b"$ANSIBLE_VAULT;1.2;AES256;devops\npassword: secret\n"
        )
        self.assertIn("non-hexadecimal", failure)

    def test_empty_file_fails(self) -> None:
        self.assertEqual(VAULT_GUARD.validate_vault(b""), "file is empty")

    def test_unrelated_path_is_not_protected(self) -> None:
        patterns = ["group_vars/**/vault.yml"]
        self.assertFalse(VAULT_GUARD.matches_policy("group_vars/all/main.yml", patterns))

    def test_group_vars_vault_pattern_matches(self) -> None:
        patterns = ["group_vars/**/vault.yml"]
        self.assertTrue(VAULT_GUARD.matches_policy("group_vars/all/vault.yml", patterns))
        self.assertFalse(VAULT_GUARD.matches_policy("keys/ssh/devops.vault", patterns))


class StagedContentTests(unittest.TestCase):
    def git(self, root: Path, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *args],
            cwd=root,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def test_staged_mode_reads_index_instead_of_working_tree(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.git(root, "init")
            self.git(root, "config", "user.name", "Vault Guard Test")
            self.git(root, "config", "user.email", "vault-guard@example.invalid")
            (root / "config").mkdir()
            (root / "group_vars" / "all").mkdir(parents=True)
            (root / "config" / "ansible-vault-required-files.txt").write_text(
                "group_vars/**/vault.yml\n", encoding="utf-8"
            )
            vault = root / "group_vars" / "all" / "vault.yml"
            vault.write_bytes(b"password: staged-plaintext\n")
            self.git(root, "add", ".")
            vault.write_bytes(VALID_VAULT)

            paths = VAULT_GUARD.protected_files(
                root, VAULT_GUARD.load_patterns(root), staged=True
            )
            self.assertEqual(paths, ["group_vars/all/vault.yml"])
            staged = VAULT_GUARD.read_content(root, paths[0], staged=True)
            working = VAULT_GUARD.read_content(root, paths[0], staged=False)
            self.assertIsNotNone(VAULT_GUARD.validate_vault(staged))
            self.assertIsNone(VAULT_GUARD.validate_vault(working))


if __name__ == "__main__":
    unittest.main()
