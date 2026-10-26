"""Sign with the persistent GitHub secret; refuse missing or rotated keys."""

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


def run(command, env=None):
    result = subprocess.run(command, env=env, capture_output=True)
    if result.returncode:
        # Command arguments contain only password-file paths, never passwords.
        raise RuntimeError(f"{Path(command[0]).name} failed (exit {result.returncode})")
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--apksigner", required=True)
    parser.add_argument("--aapt", required=True)
    parser.add_argument("--version-code", type=int, required=True)
    args = parser.parse_args()
    if not 0 < args.version_code <= 2100000000:
        raise ValueError("Android versionCode is outside the supported range")
    encoded = os.environ.get("WEEKENDSWAY_SIGNING_JSON", "")
    if not encoded:
        raise ValueError("Missing WEEKENDSWAY_SIGNING_JSON secret; refusing a new random signing key")
    try:
        secret = json.loads(encoded)
        keystore = base64.b64decode(secret["keystore"], validate=True)
        password = secret["password"]
        if secret["alias"] != "weekendsway" or not isinstance(password, str) or not password:
            raise ValueError()
        if "\n" in password or "\r" in password:
            raise ValueError()
    except (KeyError, TypeError, ValueError):
        raise ValueError("Invalid WEEKENDSWAY_SIGNING_JSON secret") from None
    expected = (Path(__file__).resolve().parents[1] / "android/signing-certificate.sha256").read_text().strip().lower()
    if not re.fullmatch(r"[0-9a-f]{64}", expected):
        raise ValueError("Invalid pinned signing-certificate fingerprint")

    with tempfile.TemporaryDirectory(prefix="weekendsway-signing-", dir=os.environ.get("RUNNER_TEMP")) as directory:
        private = Path(directory)
        key = private / "signing.p12"
        key.write_bytes(keystore)
        key.chmod(0o600)
        password_file = private / "password"
        password_file.write_text(password + "\n")
        password_file.chmod(0o600)
        env = os.environ.copy()
        env["WW_KEY_PASSWORD"] = password
        certificate = run(["keytool", "-exportcert", "-keystore", str(key), "-alias", "weekendsway",
                           "-storepass:env", "WW_KEY_PASSWORD"], env=env)
        if hashlib.sha256(certificate).hexdigest() != expected:
            raise ValueError("Signing certificate differs from android/signing-certificate.sha256; refusing key rotation")
        args.output.parent.mkdir(parents=True, exist_ok=True)
        run([args.apksigner, "sign", "--ks", str(key), "--ks-key-alias", "weekendsway",
             "--ks-pass", "file:" + str(password_file), "--key-pass", "file:" + str(password_file),
             "--out", str(args.output), str(args.input)])
        verification = run([args.apksigner, "verify", "--verbose", "--print-certs", str(args.output)]).decode()
        fingerprints = re.findall(r"Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]+)", verification)
        if [fingerprint.lower() for fingerprint in fingerprints] != [expected]:
            raise ValueError("Signed APK does not contain exactly the pinned signer")
        badging = run([args.aapt, "dump", "badging", str(args.output)]).decode()
        package = re.search(r"^package: name='([^']+)' versionCode='([0-9]+)'", badging)
        if not package or package.group(1) != "org.qtproject.example.WeekendsWay" or int(package.group(2)) != args.version_code:
            raise ValueError("APK package/versionCode differs from the expected update identity")
        print(verification.strip())
        print(f"Verified update identity: {package.group(1)}, versionCode={args.version_code}, SHA-256={expected}")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError) as error:
        raise SystemExit(str(error)) from None
