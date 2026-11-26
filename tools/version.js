// ============================================================================
// tools/version.js — the app version, read from manifest.
//
//   node tools/version.js          prints e.g. "0.2.0"
//   node tools/version.js v0.2.0   also checks that a release tag matches
//
// Fails if manifest and package.json disagree, or the tag doesn't match, so a
// release can't be published with the wrong version number.
// ============================================================================

const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const manifest = fs.readFileSync(path.join(root, "manifest"), "utf8");

function manifestNumber(key) {
    const match = manifest.match(new RegExp(`^${key}=(\\d+)\\s*$`, "m"));
    if (!match) fail(`manifest has no numeric ${key}`);
    return parseInt(match[1], 10);
}

function fail(message) {
    console.error(message);
    process.exit(1);
}

const version = [manifestNumber("major_version"), manifestNumber("minor_version"), manifestNumber("build_version")].join(".");

const packageVersion = require(path.join(root, "package.json")).version;
if (packageVersion !== version) {
    fail(`package.json version ${packageVersion} doesn't match manifest version ${version}. Update both.`);
}

const tag = process.argv[2];
if (tag && tag.replace(/^v/, "") !== version) {
    fail(`Tag ${tag} doesn't match manifest version ${version}. Update manifest and package.json, then tag again.`);
}

console.log(version);
