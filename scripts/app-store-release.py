#!/usr/bin/env python3
"""Sends a release's build to TestFlight and App Review.

    scripts/app-store-release.py VERSION BUILD [--platform MAC_OS] [--no-submit]

Waits for build BUILD of VERSION to finish processing on App Store Connect,
then sets the App Store listing from fastlane/metadata/ios, with the What's
New from distribution/whatsnew, on the version VERSION of the platform (IOS
unless given) and attaches the build. Other platforms copy App Review's
contact and notes from the iOS version, so they stay out of the repository. Unless --no-submit, it also gives the build to the external TestFlight
groups with the What's New as what to test, sends it to beta review, and
submits the version to App Review, withdrawing one still waiting there. The
internal group gets every build by itself.
"""

import pathlib
import sys
import time
import unicodedata

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
    text = (WHATSNEW / f"whatsnew-{LOCALES[locale]}").read_text()
    # App Store Connect refuses emoji, which Google Play shows from the same file.
    lines = ("".join(c for c in line if not is_emoji(c)).strip() for line in text.splitlines())
    return "\n".join(lines).strip()


def is_emoji(c):
    return unicodedata.category(c) == "So" or ord(c) > 0xFFFF or c in "️‍"


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


def wait_for_build(app, platform, version, number):
    # Processing usually takes 5 to 20 minutes; the build is not listed until it starts.
    for _ in range(120):
        builds = call(
            "GET",
            "/builds",
            {
                "filter[app]": app,
                "filter[version]": number,
                "filter[preReleaseVersion.version]": version,
                "filter[preReleaseVersion.platform]": platform,
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


def editable_version(app, platform, version):
    """The editable App Store version of `platform`, numbered `version`, if there is one."""
    versions = call(
        "GET",
        f"/apps/{app}/appStoreVersions",
        {"filter[platform]": platform, "filter[appStoreState]": EDITABLE},
    )["data"]
    if not versions:
        return None
    store_version = versions[0]["id"]
    if versions[0]["attributes"]["versionString"] != version:
        call(
            "PATCH",
            f"/appStoreVersions/{store_version}",
            body={"data": {"type": "appStoreVersions", "id": store_version, "attributes": {"versionString": version}}},
        )
    return store_version


def withdraw_from_review(app, platform):
    """Takes back a version still waiting for or in App Review, so the new
    release replaces it. True if there was one."""
    waiting = call(
        "GET",
        "/reviewSubmissions",
        {"filter[app]": app, "filter[platform]": platform, "filter[state]": "WAITING_FOR_REVIEW,IN_REVIEW"},
    )["data"]
    for submission in waiting:
        call(
            "PATCH",
            f"/reviewSubmissions/{submission['id']}",
            body={"data": {"type": "reviewSubmissions", "id": submission["id"], "attributes": {"canceled": True}}},
        )
        print(f"withdrew {platform} submission {submission['id']} from App Review", flush=True)
    return bool(waiting)


def set_listing(app, platform, version, build):
    store_version = editable_version(app, platform, version)
    if store_version is None and withdraw_from_review(app, platform):
        # The withdrawn version becomes editable once the cancellation settles.
        for _ in range(20):
            time.sleep(15)
            store_version = editable_version(app, platform, version)
            if store_version:
                break
        else:
            sys.exit(f"the {platform} version withdrawn from App Review did not become editable")
    if store_version is None:
        store_version = call(
            "POST",
            "/appStoreVersions",
            body={
                "data": {
                    "type": "appStoreVersions",
                    "attributes": {"platform": platform, "versionString": version},
                    "relationships": {"app": resource("apps", app)},
                }
            },
        )["data"]["id"]

    # The first version of an app has no What's New.
    all_versions = call("GET", f"/apps/{app}/appStoreVersions", {"filter[platform]": platform})["data"]
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

    if platform != "IOS":
        copy_review_detail(app, store_version)
    call("PATCH", f"/appStoreVersions/{store_version}/relationships/build", body=resource("builds", build))
    return store_version


def copy_review_detail(app, store_version):
    """Gives `store_version` the App Review contact and notes of the latest iOS version."""
    ios = call("GET", f"/apps/{app}/appStoreVersions", {"filter[platform]": "IOS", "limit": 1})["data"]
    source = ios and call("GET", f"/appStoreVersions/{ios[0]['id']}/appStoreReviewDetail")["data"]
    if not source:
        sys.exit("the iOS version has no App Review details to copy")
    fields = ("contactFirstName", "contactLastName", "contactPhone", "contactEmail", "demoAccountRequired", "notes")
    attributes = {k: source["attributes"][k] for k in fields}
    current = call("GET", f"/appStoreVersions/{store_version}/appStoreReviewDetail")["data"]
    if current:
        call("PATCH", f"/appStoreReviewDetails/{current['id']}", body={"data": {"type": "appStoreReviewDetails", "id": current["id"], "attributes": attributes}})
    else:
        call(
            "POST",
            "/appStoreReviewDetails",
            body={
                "data": {
                    "type": "appStoreReviewDetails",
                    "attributes": attributes,
                    "relationships": {"appStoreVersion": resource("appStoreVersions", store_version)},
                }
            },
        )


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
    # A rerun of a failed release finds the build already sent.
    if call("GET", f"/builds/{build}/betaAppReviewSubmission")["data"] is None:
        call(
            "POST",
            "/betaAppReviewSubmissions",
            body={"data": {"type": "betaAppReviewSubmissions", "relationships": {"build": resource("builds", build)}}},
        )


def submit_for_review(app, platform, store_version):
    open_submissions = call(
        "GET",
        "/reviewSubmissions",
        {"filter[app]": app, "filter[platform]": platform, "filter[state]": "READY_FOR_REVIEW", "include": "items"},
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
                    "attributes": {"platform": platform},
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
    version, number, *flags = sys.argv[1:]
    platform = flags[flags.index("--platform") + 1] if "--platform" in flags else "IOS"
    submit = "--no-submit" not in flags
    apps = call("GET", "/apps", {"filter[bundleId]": BUNDLE_ID})["data"]
    if not apps:
        sys.exit(f"no app on App Store Connect has the bundle ID {BUNDLE_ID}")
    app = apps[0]["id"]

    build = wait_for_build(app, platform, version, number)
    store_version = set_listing(app, platform, version, build)
    print(f"{platform} listing of {version} set, build {number} attached")
    if submit:
        send_to_testflight(app, build)
        print("sent to TestFlight beta review")
        submit_for_review(app, platform, store_version)
        print("submitted to App Review")


if __name__ == "__main__":
    main()
