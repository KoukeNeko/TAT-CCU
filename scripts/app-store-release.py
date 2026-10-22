#!/usr/bin/env python3
"""Sends a release's iOS build to TestFlight and App Review.

    scripts/app-store-release.py VERSION BUILD [--no-submit]

Waits for build BUILD of VERSION to finish processing on App Store Connect,
then sets the App Store listing from fastlane/metadata/ios, with the What's
New from distribution/whatsnew, on the iOS version VERSION and attaches the
build. Unless --no-submit, it also gives the build to the external TestFlight
groups with the What's New as what to test, sends it to beta review, and
submits the version to App Review. The internal group gets every build by
itself.
"""

import pathlib
import sys
import time

from asc import BUNDLE_ID, call

ROOT = pathlib.Path(__file__).resolve().parent.parent
METADATA = ROOT / "fastlane/metadata/ios"
WHATSNEW = ROOT / "distribution/whatsnew"
# App Store Connect locale: the Google Play locale whose What's New it uses.
LOCALES = {"zh-Hant": "zh-TW", "en-US": "en-US", "ja": "ja-JP"}
SUPPORT_URL = "https://github.com/KoukeNeko/TAT-CCU"
PRIVACY_URL = "https://github.com/KoukeNeko/TAT-CCU/blob/main/PRIVACY.md"
# A version in one of these states can still be edited.
EDITABLE = "PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED,INVALID_BINARY"


def text(locale, name):
    return (METADATA / locale / f"{name}.txt").read_text().strip()


def whats_new(locale):
    return (WHATSNEW / f"whatsnew-{LOCALES[locale]}").read_text().strip()


def resource(kind, id):
    return {"data": {"type": kind, "id": id}}


def upsert(existing, kind, parent, parent_kind, locale, attributes):
    """Updates the localization of `locale` among `existing`, or adds it."""
    current = next((l for l in existing if l["attributes"]["locale"] == locale), None)
    if current:
        call("PATCH", f"/{kind}/{current['id']}", body={"data": {"type": kind, "id": current["id"], "attributes": attributes}})
    else:
        call(
            "POST",
            f"/{kind}",
            body={
                "data": {
                    "type": kind,
                    "attributes": {"locale": locale, **attributes},
                    "relationships": {parent_kind: resource(f"{parent_kind}s", parent)},
                }
            },
        )


def wait_for_build(app, version, number):
    # Processing usually takes 5 to 20 minutes; the build is not listed until it starts.
    for _ in range(120):
        builds = call(
            "GET",
            "/builds",
            {
                "filter[app]": app,
                "filter[version]": number,
                "filter[preReleaseVersion.version]": version,
                "filter[preReleaseVersion.platform]": "IOS",
            },
        )["data"]
        state = builds[0]["attributes"]["processingState"] if builds else "not listed"
        if state == "VALID":
            return builds[0]["id"]
        if state in ("FAILED", "INVALID"):
            sys.exit(f"build {number} of {version} is {state} on App Store Connect")
        print(f"build {number} of {version}: {state}", flush=True)
        time.sleep(30)
    sys.exit(f"build {number} of {version} did not finish processing in an hour")


def set_listing(app, version, build):
    versions = call(
        "GET",
        f"/apps/{app}/appStoreVersions",
        {"filter[platform]": "IOS", "filter[appStoreState]": EDITABLE},
    )["data"]
    if versions:
        store_version = versions[0]["id"]
        if versions[0]["attributes"]["versionString"] != version:
            call(
                "PATCH",
                f"/appStoreVersions/{store_version}",
                body={"data": {"type": "appStoreVersions", "id": store_version, "attributes": {"versionString": version}}},
            )
    else:
        # Fails while an earlier version is still waiting for or in review.
        store_version = call(
            "POST",
            "/appStoreVersions",
            body={
                "data": {
                    "type": "appStoreVersions",
                    "attributes": {"platform": "IOS", "versionString": version},
                    "relationships": {"app": resource("apps", app)},
                }
            },
        )["data"]["id"]

    # The first version of an app has no What's New.
    all_versions = call("GET", f"/apps/{app}/appStoreVersions", {"filter[platform]": "IOS"})["data"]
    first = all(v["id"] == store_version for v in all_versions)
    existing = call("GET", f"/appStoreVersions/{store_version}/appStoreVersionLocalizations")["data"]
    for locale in LOCALES:
        attributes = {
            "description": text(locale, "description"),
            "keywords": text(locale, "keywords"),
            "supportUrl": SUPPORT_URL,
        }
        if not first:
            attributes["whatsNew"] = whats_new(locale)
        upsert(existing, "appStoreVersionLocalizations", store_version, "appStoreVersion", locale, attributes)

    # The app's name and subtitle can change only alongside an editable version.
    infos = call("GET", f"/apps/{app}/appInfos")["data"]
    info = next((i for i in infos if (i["attributes"].get("state") or i["attributes"].get("appStoreState")) not in ("READY_FOR_DISTRIBUTION", "READY_FOR_SALE")), None)
    if info:
        existing = call("GET", f"/appInfos/{info['id']}/appInfoLocalizations")["data"]
        for locale in LOCALES:
            attributes = {"name": text(locale, "name"), "subtitle": text(locale, "subtitle"), "privacyPolicyUrl": PRIVACY_URL}
            upsert(existing, "appInfoLocalizations", info["id"], "appInfo", locale, attributes)

    call("PATCH", f"/appStoreVersions/{store_version}/relationships/build", body=resource("builds", build))
    return store_version


def send_to_testflight(app, build):
    existing = call("GET", f"/builds/{build}/betaBuildLocalizations")["data"]
    for locale in LOCALES:
        upsert(existing, "betaBuildLocalizations", build, "build", locale, {"whatsNew": whats_new(locale)})
    groups = [
        g for g in call("GET", f"/apps/{app}/betaGroups")["data"] if not g["attributes"]["isInternalGroup"]
    ]
    if not groups:
        sys.exit("the app has no external TestFlight group")
    for group in groups:
        call("POST", f"/betaGroups/{group['id']}/relationships/builds", body={"data": [{"type": "builds", "id": build}]})
    call(
        "POST",
        "/betaAppReviewSubmissions",
        body={"data": {"type": "betaAppReviewSubmissions", "relationships": {"build": resource("builds", build)}}},
    )


def submit_for_review(app, store_version):
    open_submissions = call(
        "GET",
        "/reviewSubmissions",
        {"filter[app]": app, "filter[platform]": "IOS", "filter[state]": "READY_FOR_REVIEW", "include": "items"},
    )["data"]
    if open_submissions:
        submission = open_submissions[0]["id"]
        has_items = bool(open_submissions[0]["relationships"]["items"]["data"])
    else:
        submission = call(
            "POST",
            "/reviewSubmissions",
            body={
                "data": {
                    "type": "reviewSubmissions",
                    "attributes": {"platform": "IOS"},
                    "relationships": {"app": resource("apps", app)},
                }
            },
        )["data"]["id"]
        has_items = False
    if not has_items:
        call(
            "POST",
            "/reviewSubmissionItems",
            body={
                "data": {
                    "type": "reviewSubmissionItems",
                    "relationships": {
                        "reviewSubmission": resource("reviewSubmissions", submission),
                        "appStoreVersion": resource("appStoreVersions", store_version),
                    },
                }
            },
        )
    call(
        "PATCH",
        f"/reviewSubmissions/{submission}",
        body={"data": {"type": "reviewSubmissions", "id": submission, "attributes": {"submitted": True}}},
    )


def main():
    version, number = sys.argv[1], sys.argv[2]
    submit = "--no-submit" not in sys.argv[3:]
    apps = call("GET", "/apps", {"filter[bundleId]": BUNDLE_ID})["data"]
    if not apps:
        sys.exit(f"no app on App Store Connect has the bundle ID {BUNDLE_ID}")
    app = apps[0]["id"]

    build = wait_for_build(app, version, number)
    store_version = set_listing(app, version, build)
    print(f"listing of {version} set, build {number} attached")
    if submit:
        send_to_testflight(app, build)
        print("sent to TestFlight beta review")
        submit_for_review(app, store_version)
        print("submitted to App Review")


if __name__ == "__main__":
    main()
