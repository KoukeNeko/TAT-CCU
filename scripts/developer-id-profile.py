#!/usr/bin/env python3
"""Fetches or makes the Developer ID provisioning profile of the macOS app.

    scripts/developer-id-profile.py SERIAL

The app's keychain entitlement needs a profile even outside the App Store,
and Xcode only makes one itself through cloud-managed certificates, which the
release's API key may not use. This asks App Store Connect for a profile for
the bundle ID and the Developer ID certificate with SERIAL (the one the
release signs with), reusing the one made before while it is valid, installs
it where Xcode looks, and prints its name for the export options.
"""

import base64
import pathlib
import sys

from asc import BUNDLE_ID, call

NAME = "TAT CCU Developer ID"


def main():
    serial = sys.argv[1].upper().lstrip("0")

    bundles = call("GET", "/bundleIds", {"filter[identifier]": BUNDLE_ID, "limit": 200})["data"]
    bundle = next((b for b in bundles if b["attributes"]["identifier"] == BUNDLE_ID), None)
    if bundle is None:
        sys.exit(f"the bundle ID {BUNDLE_ID} is not registered")

    certificates = call(
        "GET",
        "/certificates",
        # Certificates made since 2021 are of the G2 type.
        {"filter[certificateType]": "DEVELOPER_ID_APPLICATION,DEVELOPER_ID_APPLICATION_G2", "limit": 200},
    )["data"]
    certificate = next(
        (c for c in certificates if c["attributes"]["serialNumber"].upper().lstrip("0") == serial), None
    )
    if certificate is None:
        sys.exit(f"no Developer ID Application certificate on the team has the serial {serial}")

    existing = call(
        "GET",
        "/profiles",
        {"filter[name]": NAME, "filter[profileType]": "MAC_APP_DIRECT", "include": "certificates", "limit": 200},
    )
    profile = None
    for p in existing["data"]:
        signs_with = {c["id"] for c in p["relationships"]["certificates"]["data"]}
        if p["attributes"]["profileState"] == "ACTIVE" and certificate["id"] in signs_with:
            profile = p
        else:
            # Expired, or for another certificate: the name is needed for the new one.
            call("DELETE", "/profiles/" + p["id"])
    if profile is None:
        profile = call(
            "POST",
            "/profiles",
            body={
                "data": {
                    "type": "profiles",
                    "attributes": {"name": NAME, "profileType": "MAC_APP_DIRECT"},
                    "relationships": {
                        "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}},
                        "certificates": {"data": [{"type": "certificates", "id": certificate["id"]}]},
                    },
                }
            },
        )["data"]

    content = base64.b64decode(profile["attributes"]["profileContent"])
    uuid = profile["attributes"]["uuid"]
    for folder in (
        pathlib.Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles",
        pathlib.Path.home() / "Library/MobileDevice/Provisioning Profiles",
    ):
        folder.mkdir(parents=True, exist_ok=True)
        (folder / f"{uuid}.provisionprofile").write_bytes(content)
    print(NAME)


if __name__ == "__main__":
    main()
