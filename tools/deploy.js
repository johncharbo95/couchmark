// ============================================================================
// tools/deploy.js — `npm run deploy`: sideloads the app to the TV from a
// terminal, like the F5 launch config but without the debugger.
//
// Reads ROKU_HOST / ROKU_PASSWORD from .env, writes build-info.json, zips the
// same files as .vscode/launch.json and installs them over the current app.
//
// IMPORTANT: deleteInstalledChannel must stay false. roku-deploy defaults it
// to true, and deleting the dev channel also erases its registry, i.e. all
// saved watch progress and settings. Installing over it keeps them.
// ============================================================================

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const { RokuDeploy } = require("roku-deploy");

const root = path.resolve(__dirname, "..");

function readEnv(file) {
    const env = {};
    if (!fs.existsSync(file)) return env;
    for (const line of fs.readFileSync(file, "utf8").split(/\r?\n/)) {
        const match = line.match(/^\s*([A-Z_]+)\s*=\s*(.*?)\s*$/);
        if (match) env[match[1]] = match[2];
    }
    return env;
}

const env = { ...readEnv(path.join(root, ".env")), ...process.env };
if (!env.ROKU_HOST || !env.ROKU_PASSWORD) {
    console.error("Set ROKU_HOST and ROKU_PASSWORD in .env (see .env.example).");
    process.exit(1);
}

execFileSync(process.execPath, [path.join(root, "tools", "build-info.js")], { stdio: "inherit" });

new RokuDeploy()
    .deploy({
        host: env.ROKU_HOST,
        password: env.ROKU_PASSWORD,
        rootDir: root,
        outDir: path.join(os.tmpdir(), "couchmark-deploy"),
        files: ["manifest", "source/**/*", "components/**/*", "images/**/*", "build-info.json"],
        deleteInstalledChannel: false
    })
    .then(() => console.log(`Installed on ${env.ROKU_HOST} (saved progress kept).`))
    .catch((error) => {
        console.error(`Deploy failed: ${error.message}`);
        process.exit(1);
    });
