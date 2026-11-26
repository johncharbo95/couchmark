// ============================================================================
// tools/release-assets.js — `npm run dist`: everything a release publishes.
//
// Runs after `npm run package` (which writes out/couchmark.zip) and writes
// out/release/:
//
//   couchmark-v0.2.0.zip          the app: upload it on the Roku's web page
//   couchmark-usb-starter.zip     empty Movies/Shows/Other folders + a guide,
//                                 to unzip onto a USB drive
//   SHA256SUMS.txt                checksums of both zips
//   NOTES.md                      install steps for the release page
//
// It also checks the app zip before anything is published: manifest at the
// top, the version inside matches, and no dev-only files (build-info.json,
// tests, tools, docs) slipped in.
// ============================================================================

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { execFileSync } = require("child_process");
const JSZip = require("jszip");

const root = path.resolve(__dirname, "..");
const appZipPath = path.join(root, "out", "couchmark.zip");
const releaseDir = path.join(root, "out", "release");
const repoUrl = "https://github.com/johncharbo95/couchmark";

function fail(message) {
    console.error(`release-assets: ${message}`);
    process.exit(1);
}

function appVersion() {
    return execFileSync(process.execPath, [path.join(root, "tools", "version.js")], { encoding: "utf8" }).trim();
}

// Throws (fails the build) if the sideload zip isn't what a Roku expects.
async function checkAppZip(zip, version) {
    const manifestFile = zip.file("manifest");
    if (!manifestFile) fail("couchmark.zip has no manifest at its top level");
    const manifest = await manifestFile.async("string");
    const number = (key) => (manifest.match(new RegExp(`^${key}=(\\d+)`, "m")) || [])[1];
    const zipped = [number("major_version"), number("minor_version"), number("build_version")].join(".");
    if (zipped !== version) fail(`couchmark.zip contains version ${zipped}, expected ${version}`);
    if (!zip.file("source/main.brs")) fail("couchmark.zip has no source/main.brs");

    const forbidden = /^(build-info\.json|tests\/|tools\/|docs\/|node_modules\/|\.env)/;
    const bad = Object.keys(zip.files).filter((name) => forbidden.test(name));
    if (bad.length > 0) fail(`couchmark.zip contains dev-only files: ${bad.join(", ")}`);
}

const starterGuide = `COUCHMARK USB DRIVE
===================

Put your files in these three folders. You don't need all of them.

Movies   One folder per movie, with the video file(s) inside.
           Movies/The Matrix (1999)/The Matrix.mp4

Shows    One folder per show, then one folder per season.
           Shows/The Office/Season 1/S01E01 Pilot.mp4

Other    Any folders of photos and videos, played as slideshows.
           Other/Summer 2025/IMG_0001.jpg

Video files must be inside a movie or show folder: a video placed
directly in "Movies" or "Shows" is not shown.

The full guide, with more examples and common mistakes:
${repoUrl}/blob/main/docs/USB-SETUP.md

You can delete this file.
`;

function buildStarterZip() {
    const zip = new JSZip();
    // Fixed dates so the same input always gives the same zip (and checksum).
    const date = new Date("2026-01-01T00:00:00Z");
    for (const folder of ["Movies", "Shows", "Other"]) zip.folder(folder, { date });
    zip.file("Couchmark USB guide.txt", starterGuide.replace(/\n/g, "\r\n"), { date });
    return zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE" });
}

function notes(version, appName) {
    return `## Install

1. **Turn on developer mode** on your Roku (one time): on the remote press **Home ×3, Up ×2, Right, Left, Right, Left, Right**, pick a password and write down the IP address.
2. **Download \`${appName}\`** below (don't unzip it).
3. On a computer on the same Wi-Fi, open \`http://<your-roku-ip>\`, sign in as \`rokudev\` with your password, click **Upload**, pick the zip and click **Install with zip** (or **Replace** when updating).

Updating keeps your watch progress and settings. Don't press **Delete** on that page: it erases them.

**New to Couchmark?** Download \`couchmark-usb-starter.zip\` too and unzip it onto your USB drive to get the right folders. Full guides: [Installing](${repoUrl}/blob/v${version}/docs/INSTALL.md) · [Setting up the USB drive](${repoUrl}/blob/v${version}/docs/USB-SETUP.md) · [Using Couchmark](${repoUrl}/blob/v${version}/docs/USER-GUIDE.md)

Checksums are in \`SHA256SUMS.txt\`.
`;
}

const sha256 = (buffer) => crypto.createHash("sha256").update(buffer).digest("hex");

async function main() {
    if (!fs.existsSync(appZipPath)) fail("out/couchmark.zip not found. Run `npm run package` first (or `npm run dist`).");
    const version = appVersion();
    const appName = `couchmark-v${version}.zip`;

    const appBuffer = fs.readFileSync(appZipPath);
    await checkAppZip(await JSZip.loadAsync(appBuffer), version);
    const starterBuffer = await buildStarterZip();

    fs.rmSync(releaseDir, { recursive: true, force: true });
    fs.mkdirSync(releaseDir, { recursive: true });
    fs.writeFileSync(path.join(releaseDir, appName), appBuffer);
    fs.writeFileSync(path.join(releaseDir, "couchmark-usb-starter.zip"), starterBuffer);
    fs.writeFileSync(
        path.join(releaseDir, "SHA256SUMS.txt"),
        `${sha256(appBuffer)}  ${appName}\n${sha256(starterBuffer)}  couchmark-usb-starter.zip\n`
    );
    fs.writeFileSync(path.join(releaseDir, "NOTES.md"), notes(version, appName));

    for (const name of fs.readdirSync(releaseDir)) {
        const size = fs.statSync(path.join(releaseDir, name)).size;
        console.log(`out/release/${name}  (${(size / 1024).toFixed(1)} KB)`);
    }
}

main().catch((error) => fail(error.message));
