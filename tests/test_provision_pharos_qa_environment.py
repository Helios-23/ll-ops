"""Checks private QA provisioning preservation, idempotency and unsafe-file rejection."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class ProvisionTests(unittest.TestCase):
    def run_helper(self, path, apply=False):
        command = [sys.executable, str(Path(__file__).parents[1] / "bin/provision_pharos_qa_environment.py"), "--env-file", str(path)]
        if apply:
            command.append("--apply")
        return subprocess.run(command, text=True, capture_output=True)

    def test_plan_preservation_idempotency_and_redaction(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "private.env"
            path.write_text("OTHER=keep\nPHAROS_PAYMENT_PROVIDER_STATE_KEY=existing-private-value\n")
            initial = path.read_bytes()
            planned = self.run_helper(path)
            self.assertEqual(planned.returncode, 0)
            self.assertEqual(path.read_bytes(), initial)
            applied = self.run_helper(path, True)
            self.assertEqual(applied.returncode, 0, applied.stderr)
            final = path.read_bytes()
            self.assertIn(initial, final)
            values = dict(line.split("=", 1) for line in path.read_text().splitlines())
            self.assertEqual(len(values["PHAROS_PAYMENT_PROVIDER_SECRET_KEY"]), 64)
            self.assertEqual(path.stat().st_mode & 0o777, 0o640)
            repeated = self.run_helper(path, True)
            self.assertEqual(repeated.returncode, 0)
            self.assertEqual(path.read_bytes(), final)
            for result in (planned, applied, repeated):
                self.assertNotIn("existing-private-value", result.stdout + result.stderr)
                self.assertNotIn(values["PHAROS_PAYMENT_PROVIDER_SECRET_KEY"], result.stdout + result.stderr)

    def test_rejects_symlinks_and_duplicate_keys(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "private.env"
            path.write_text("OTHER=one\nOTHER=two\n")
            self.assertNotEqual(self.run_helper(path, True).returncode, 0)
            link = Path(directory) / "linked.env"
            link.symlink_to(path)
            self.assertNotEqual(self.run_helper(link, True).returncode, 0)
            self.assertEqual(path.read_text(), "OTHER=one\nOTHER=two\n")


if __name__ == "__main__":
    unittest.main()
