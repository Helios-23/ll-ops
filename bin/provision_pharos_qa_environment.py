#!/usr/bin/env python3
"""Plan or provision private Pharos QA keys and loopback integration settings."""

import argparse
import os
from pathlib import Path
import secrets
import stat
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--env-file", type=Path, default=Path("/etc/pharos/pharos.env"))
    args = parser.parse_args()
    path = args.env_file
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
        raise SystemExit("environment must be a regular, unlinked private file")
    text = path.read_text()
    names = {}
    for line in text.splitlines():
        if "=" not in line or line.lstrip().startswith("#"):
            continue
        key, value = line.split("=", 1)
        if key in names:
            raise SystemExit("duplicate environment key; resolve before provisioning")
        names[key] = value
    generators = {
        "PHAROS_PAYMENT_PROVIDER_STATE_KEY": lambda: secrets.token_hex(32),
        "PHAROS_PAYMENT_PROVIDER_SECRET_KEY": lambda: secrets.token_hex(32),
        "PHAROS_DYNAMIC_APP_LOCAL_ECHO_URL": lambda: "http://127.0.0.1:18085/echo",
        "PHAROS_DYNAMIC_APP_BOARD_WEBHOOK_URL": lambda: "http://127.0.0.1:18085/board",
        "PHAROS_DYNAMIC_APP_BOARD_WEBHOOK_TOKEN": lambda: secrets.token_hex(32),
        "PHAROS_DYNAMIC_APP_BOARD_FORM_TOKEN": lambda: secrets.token_hex(32),
        "PHAROS_DYNAMIC_APP_APPROVAL_WEBHOOK_URL": lambda: "http://127.0.0.1:18085/approval",
    }
    missing = [key for key in generators if not names.get(key)]
    print("Keys/settings to provision: " + ", ".join(missing))
    print("Existing nonempty values retained; secret values never printed")
    if not args.apply or not missing:
        return
    lines = [line for line in text.splitlines() if line.split("=", 1)[0] not in missing]
    lines.extend(f"{key}={generators[key]()}" for key in missing)
    descriptor, temporary = tempfile.mkstemp(prefix=".pharos-env-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as output:
            os.fchmod(output.fileno(), 0o640)
            os.fchown(output.fileno(), info.st_uid, info.st_gid)
            output.write("\n".join(lines) + "\n")
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == "__main__":
    main()
