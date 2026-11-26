// ============================================================================
// tools/build-info.js — writes build-info.json for development builds.
//
// VS Code runs this before every launch (see .vscode/tasks.json and the
// preLaunchTask in .vscode/launch.json). The launch config packages
// build-info.json with the app, and the home screen shows it as
//   DEV  9ad7f63  <commit message>  ·  dev  ·  built 2026-10-12 11:42
// Release zips (npm run package, GitHub Releases) never include it.
// The file is git-ignored. This script never fails the launch: without git,
// it writes an empty object and nothing is shown.
// ============================================================================

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const root = path.resolve(__dirname, "..");
const target = path.join(root, "build-info.json");

function git(args) {
    return execSync(`git ${args}`, { cwd: root, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
}

function localTime(date) {
    const pad = (n) => String(n).padStart(2, "0");
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

let info = {};
try {
    info = {
        commit: git("rev-parse --short HEAD"),
        message: git("log -1 --format=%s"),
        branch: git("rev-parse --abbrev-ref HEAD"),
        dirty: git("status --porcelain") !== "",
        builtAt: localTime(new Date()),
    };
} catch (err) {
    console.warn("build-info: git not available, writing empty build info");
}

fs.writeFileSync(target, JSON.stringify(info, null, 2) + "\n");
console.log("build-info:", info.commit ? `${info.commit} ${info.message}${info.dirty ? " (+ uncommitted changes)" : ""}` : "(none)");
