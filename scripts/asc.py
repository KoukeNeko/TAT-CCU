"""App Store Connect API calls with the release's API key.

Reads the key from ASC_KEY (the .p8 file), ASC_KEY_ID and ASC_ISSUER.
"""

import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BUNDLE_ID = "io.github.koukeneko.tatCcu"
API = "https://api.appstoreconnect.apple.com/v1"


def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(der):
    """An ECDSA signature as openssl writes it (DER) to the r || s of a JWT."""
    assert der[0] == 0x30, "not a DER sequence"
    i = 3 if der[1] & 0x80 else 2
    parts = []
    for _ in range(2):
        assert der[i] == 0x02, "not a DER integer"
        length = der[i + 1]
        parts.append(der[i + 2 : i + 2 + length].lstrip(b"\0").rjust(32, b"\0"))
        i += 2 + length
    return b"".join(parts)


def token():
    # Signed by openssl so the release job runs no package from PyPI next to
    # the signing key.
    now = int(time.time())
    header = {"alg": "ES256", "kid": os.environ["ASC_KEY_ID"], "typ": "JWT"}
    claims = {"iss": os.environ["ASC_ISSUER"], "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    signing_input = b64url(json.dumps(header).encode()) + "." + b64url(json.dumps(claims).encode())
    der = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", os.environ["ASC_KEY"]],
        input=signing_input.encode(),
        capture_output=True,
        check=True,
    ).stdout
    return signing_input + "." + b64url(der_to_raw(der))


def call(method, path, query=None, body=None):
    url = API + path + ("?" + urllib.parse.urlencode(query) if query else "")
    request = urllib.request.Request(
        url,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request) as response:
            raw = response.read()
    except urllib.error.HTTPError as e:
        sys.exit(f"App Store Connect answered {e.code} to {method} {path}: {e.read().decode()}")
    return json.loads(raw) if raw else None
