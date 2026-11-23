#!/usr/bin/env python3
import json
import os
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
config_path = root / "google-sign-in.json"

try:
    config = json.loads(config_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    sys.exit(f"Could not read {config_path}: {error}")

for name in ("GOOGLE_IOS_CLIENT_ID", "GOOGLE_SERVER_CLIENT_ID"):
    value = config.get(name) if isinstance(config, dict) else None
    if not isinstance(value, str) or not re.fullmatch(
        r"[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com", value
    ):
        sys.exit(f"{name} must be a valid Google OAuth client ID")

scheme = ".".join(reversed(config["GOOGLE_IOS_CLIENT_ID"].split("."))).lower()
os.umask(0o077)
(root / "ios/Flutter/GoogleSignIn.xcconfig").write_text(
    f"GOOGLE_IOS_URL_SCHEME = {scheme}\n", encoding="utf-8"
)
