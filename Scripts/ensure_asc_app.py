#!/usr/bin/env python3
"""Ensure Bundle ID and App Store Connect App record exist for Gem ID Scanner.

Authenticates against App Store Connect REST API via JWT (ES256).
Checks if the Bundle ID exists, creates it if missing, and verifies / creates
the App Store Connect App record.

Environment variables supported:
  APPSTORE_API_KEY_ID or APP_STORE_CONNECT_API_KEY_KEY_ID
  APPSTORE_API_ISSUER_ID or APP_STORE_CONNECT_API_KEY_ISSUER_ID
  APPSTORE_API_KEY_BASE64 (base64 of .p8)
  APP_STORE_CONNECT_API_KEY_KEY_FILEPATH (path to .p8 file)
  APP_IDENTIFIER (default: com.gemidscanner.app)
  APP_NAME (default: Gem ID Scanner)
  APP_SKU (default: gem-id-scanner-001)
  PRIMARY_LOCALE (default: en-US)
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import time
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

try:
    import jwt  # PyJWT
except ImportError:
    import subprocess
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "PyJWT", "cryptography", "-q"])
    except subprocess.CalledProcessError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "PyJWT", "cryptography", "--break-system-packages", "-q"])
    import jwt

import urllib.error
import urllib.request

DEFAULT_BUNDLE_ID = "com.gemidscanner.app"
DEFAULT_APP_NAME = "Gem ID Scanner"
DEFAULT_SKU = "gem-id-scanner-001"
DEFAULT_LOCALE = "en-US"
API_BASE_URL = "https://api.appstoreconnect.apple.com"


def load_dotenv(env_path: Optional[Path] = None) -> None:
    """Load simple KEY=VALUE or export KEY=VALUE from .env file into os.environ if not already set."""
    if env_path is None:
        env_path = Path.cwd() / ".env"
    if not env_path.exists():
        return
    try:
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("export "):
                    line = line[7:].strip()
                if "=" not in line:
                    continue
                key, val = line.split("=", 1)
                key = key.strip()
                val = val.strip().strip("\"'")
                if key and key not in os.environ:
                    os.environ[key] = val
    except Exception as e:
        print(f"Warning: Could not read {env_path}: {e}")


def load_credentials(args: argparse.Namespace) -> Tuple[str, str, str]:
    """Resolve key_id, issuer_id, and PEM private key content."""
    key_id = (
        args.key_id
        or os.environ.get("APPSTORE_API_KEY_ID")
        or os.environ.get("APP_STORE_CONNECT_API_KEY_KEY_ID")
        or os.environ.get("APP_STORE_CONNECT_API_KEY_ID")
    )
    issuer_id = (
        args.issuer_id
        or os.environ.get("APPSTORE_API_ISSUER_ID")
        or os.environ.get("APP_STORE_CONNECT_API_KEY_ISSUER_ID")
        or os.environ.get("APP_STORE_CONNECT_ISSUER_ID")
    )

    if not key_id or not issuer_id:
        sys.exit(
            "Error: Missing App Store Connect API credentials. Set APPSTORE_API_KEY_ID "
            "and APPSTORE_API_ISSUER_ID in .env or pass --key-id and --issuer-id."
        )

    pem = None
    key_path = (
        args.key_path
        or os.environ.get("APP_STORE_CONNECT_API_KEY_KEY_FILEPATH")
    )
    key_b64 = (
        args.key_base64
        or os.environ.get("APPSTORE_API_KEY_BASE64")
        or os.environ.get("APP_STORE_CONNECT_API_KEY_KEY")
    )

    if key_path:
        try:
            expanded_path = Path(key_path).expanduser()
            if expanded_path.exists():
                pem = expanded_path.read_text(encoding="utf-8")
            else:
                print(f"Warning: Key file path '{key_path}' does not exist.")
        except Exception as e:
            print(f"Note: Could not read '{key_path}': {e}")

    if not pem and key_b64:
        try:
            decoded = base64.b64decode(key_b64.strip()).decode("utf-8")
            if "PRIVATE KEY" in decoded:
                pem = decoded
            else:
                print("Note: APPSTORE_API_KEY_BASE64 is not a PEM private key (might be a PKCS#12 certificate).")
        except Exception as e:
            print(f"Note: Could not decode APPSTORE_API_KEY_BASE64 as UTF-8 PEM: {e}")

    if not pem:
        search_paths = [
            Path.home() / f".appstoreconnect/private_keys/AuthKey_{key_id}.p8",
            Path.home() / f".private_keys/AuthKey_{key_id}.p8",
            Path.cwd() / f"AuthKey_{key_id}.p8",
        ]
        for candidate in search_paths:
            try:
                if candidate.exists():
                    print(f"Found private key at: {candidate}")
                    pem = candidate.read_text(encoding="utf-8")
                    break
            except Exception:
                pass

    if not pem:
        sys.exit(
            f"Error: No App Store Connect .p8 private key found. Set APPSTORE_API_KEY_BASE64, "
            f"APP_STORE_CONNECT_API_KEY_KEY_FILEPATH, or place AuthKey_{key_id}.p8 in ~/.appstoreconnect/private_keys/"
        )

    return key_id.strip(), issuer_id.strip(), pem.strip()


def generate_jwt_token(key_id: str, issuer_id: str, pem: str) -> str:
    """Generate an ES256 signed JWT for App Store Connect API."""
    now = int(time.time())
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + 1100,  # Max validity 20 minutes
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(
        payload,
        pem,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


def api_request(
    method: str,
    endpoint: str,
    token: str,
    body: Optional[Dict[str, Any]] = None,
) -> Tuple[int, Dict[str, Any]]:
    """Execute HTTP request to App Store Connect API."""
    url = endpoint if endpoint.startswith("http") else f"{API_BASE_URL}{endpoint}"
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read()
            return resp.status, json.loads(raw.decode("utf-8")) if raw else {}
    except urllib.error.HTTPError as e:
        raw_err = e.read().decode("utf-8", errors="replace")
        try:
            err_json = json.loads(raw_err)
        except Exception:
            err_json = {"raw": raw_err}
        return e.code, err_json


def ensure_bundle_id(token: str, bundle_identifier: str, app_name: str) -> Dict[str, Any]:
    """Find or create Bundle ID in Apple Developer Portal."""
    print(f"Checking Developer Portal Bundle ID: {bundle_identifier}...")
    status, res = api_request("GET", f"/v1/bundleIds?filter[identifier]={bundle_identifier}&limit=1", token)
    if status == 200:
        data = res.get("data", [])
        if data:
            bundle_obj = data[0]
            print(f"✓ Found existing Bundle ID: {bundle_identifier} (id: {bundle_obj['id']})")
            return bundle_obj

    # Create new Bundle ID
    clean_name = "".join(c for c in app_name if c.isalnum() or c in (" ", "_", "-"))[:30]
    print(f"Creating new Bundle ID '{bundle_identifier}' with name '{clean_name}'...")
    create_body = {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "identifier": bundle_identifier,
                "name": clean_name,
                "platform": "IOS",
            },
        }
    }
    status, res = api_request("POST", "/v1/bundleIds", token, create_body)
    if status in (200, 201):
        bundle_obj = res["data"]
        print(f"✓ Successfully created Bundle ID: {bundle_identifier} (id: {bundle_obj['id']})")
        return bundle_obj
    else:
        print(f"Warning: Could not create Bundle ID ({status}): {res}")
        # Try finding again in case of race condition
        status, res = api_request("GET", f"/v1/bundleIds?filter[identifier]={bundle_identifier}&limit=1", token)
        if status == 200 and res.get("data"):
            return res["data"][0]
        raise RuntimeError(f"Failed to ensure Bundle ID: {res}")


def ensure_app_record(
    token: str,
    bundle_identifier: str,
    bundle_id_resource_id: str,
    app_name: str,
    sku: str,
    primary_locale: str,
) -> Optional[Dict[str, Any]]:
    """Find or create App Store Connect App record."""
    print(f"Checking App Store Connect App record for bundle ID: {bundle_identifier}...")
    status, res = api_request("GET", f"/v1/apps?filter[bundleId]={bundle_identifier}&limit=1", token)
    if status == 200:
        data = res.get("data", [])
        if data:
            app_obj = data[0]
            print(f"✓ App Store Connect App record already exists: '{app_obj['attributes']['name']}' (id: {app_obj['id']})")
            return app_obj

    print(f"Creating App Store Connect App: '{app_name}' (SKU: {sku}, Locale: {primary_locale})...")
    create_body = {
        "data": {
            "type": "apps",
            "attributes": {
                "name": app_name,
                "sku": sku,
                "primaryLocale": primary_locale,
            },
            "relationships": {
                "bundleId": {
                    "data": {
                        "type": "bundleIds",
                        "id": bundle_id_resource_id,
                    }
                }
            },
        }
    }
    status, res = api_request("POST", "/v1/apps", token, create_body)
    if status in (200, 201):
        app_obj = res["data"]
        print(f"✓ Successfully created App Store Connect App: '{app_obj['attributes']['name']}' (id: {app_obj['id']})")
        return app_obj
    else:
        err_msg = json.dumps(res, indent=2)
        print(f"Note: App creation via API returned status {status}:\n{err_msg}")
        print("\nNote: Some App Store Connect API keys do not have permission to CREATE new apps.")
        print(f"If the app does not exist yet, you can create it once at https://appstoreconnect.apple.com:")
        print(f"  Platform: iOS")
        print(f"  Name: {app_name}")
        print(f"  Bundle ID: {bundle_identifier}")
        print(f"  SKU: {sku}")
        print(f"  Primary Language: {primary_locale}\n")
        return None


def main() -> None:
    # Load .env before parsing arguments
    env_file_parser = argparse.ArgumentParser(add_help=False)
    env_file_parser.add_argument("--env-file", default=".env", help="Path to .env file (default: .env)")
    known_args, _ = env_file_parser.parse_known_args()
    if known_args.env_file:
        load_dotenv(Path(known_args.env_file))

    parser = argparse.ArgumentParser(description="Ensure ASC Bundle ID and App record exist.", parents=[env_file_parser])
    parser.add_argument("--key-id", help="App Store Connect API Key ID")
    parser.add_argument("--issuer-id", help="App Store Connect API Issuer ID")
    parser.add_argument("--key-base64", help="Base64 encoded AuthKey .p8 content")
    parser.add_argument("--key-path", help="Path to AuthKey .p8 file")
    parser.add_argument("--bundle-id", default=os.environ.get("APP_IDENTIFIER", DEFAULT_BUNDLE_ID))
    parser.add_argument("--app-name", default=os.environ.get("APP_NAME", DEFAULT_APP_NAME))
    parser.add_argument("--sku", default=os.environ.get("APP_SKU", DEFAULT_SKU))
    parser.add_argument("--primary-locale", default=os.environ.get("PRIMARY_LOCALE", DEFAULT_LOCALE))

    args = parser.parse_args()

    key_id, issuer_id, pem = load_credentials(args)
    token = generate_jwt_token(key_id, issuer_id, pem)

    print("=" * 60)
    print("Gem ID Scanner — App Store Connect Provisioning Check")
    print(f"Bundle ID:      {args.bundle_id}")
    print(f"App Name:       {args.app_name}")
    print(f"SKU:            {args.sku}")
    print(f"Primary Locale: {args.primary_locale}")
    print("=" * 60)

    # 1. Ensure Bundle ID
    bundle_obj = ensure_bundle_id(token, args.bundle_id, args.app_name)
    bundle_resource_id = bundle_obj["id"]

    # 2. Ensure App Record
    ensure_app_record(
        token=token,
        bundle_identifier=args.bundle_id,
        bundle_id_resource_id=bundle_resource_id,
        app_name=args.app_name,
        sku=args.sku,
        primary_locale=args.primary_locale,
    )

    print("\n✓ App Store Connect requirements verified.")


if __name__ == "__main__":
    main()
