// ============================================================================
// tests/run.js — runs the BrightScript unit tests on your computer (no Roku).
//
//   npm test                 run every tests/*.test.brs
//   npm test -- Format       run only test files whose name contains "Format"
//
// Each test file starts with directives (BrightScript comments):
//   ' @include components/lib/Format.brs     app code under test
//   ' @double  tests/doubles/Registry.brs    replaces same-named functions in
//                                            the included code (registry,
//                                            files, clock: things that need a
//                                            real Roku)
//   ' @fixture tests/fixtures/x.mp4          file bytes, readable in the test
//                                            through the File double
//
// The test is assembled in out/tests/<name>/ and run with the `brs`
// interpreter. A test fails if it prints a "FAIL:" line, prints a brs
// runtime error ("File.brs(12,4-10): ..."), or never reaches
// finishTests() (e.g. it crashed).
// ============================================================================

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const root = path.resolve(__dirname, "..");
const outRoot = path.join(root, "out", "tests");
const brsCli = path.join(root, "node_modules", "brs", "bin", "cli.js");
const assertLib = path.join(__dirname, "lib", "Assert.brs");

const filter = process.argv[2] || "";
const testFiles = fs
    .readdirSync(__dirname)
    .filter((f) => f.endsWith(".test.brs") && f.includes(filter))
    .sort();

if (!fs.existsSync(brsCli)) {
    console.error("brs is not installed. Run `npm install` first.");
    process.exit(1);
}

let failedFiles = 0;
for (const file of testFiles) {
    const ok = runTest(file);
    if (!ok) failedFiles++;
}
console.log(`\n${testFiles.length - failedFiles}/${testFiles.length} test files passed`);
process.exit(failedFiles === 0 ? 0 : 1);

// ----------------------------------------------------------------------------

function runTest(file) {
    const testPath = path.join(__dirname, file);
    const source = fs.readFileSync(testPath, "utf8");
    const directive = (name) =>
        [...source.matchAll(new RegExp(`^'\\s*@${name}\\s+(\\S+)`, "gm"))].map((m) => path.join(root, m[1]));

    const includes = directive("include");
    const doubles = directive("double");
    const fixtures = directive("fixture");

    // Functions defined by the doubles replace the app's versions.
    const replaced = new Set(doubles.flatMap((d) => functionNames(fs.readFileSync(d, "utf8"))));

    const outDir = path.join(outRoot, file.replace(/\.test\.brs$/, ""));
    fs.rmSync(outDir, { recursive: true, force: true });
    fs.mkdirSync(outDir, { recursive: true });

    const files = [];
    const write = (name, text) => {
        const target = path.join(outDir, name);
        fs.writeFileSync(target, text);
        files.push(target);
    };

    write(file, source);
    write("Assert.brs", fs.readFileSync(assertLib, "utf8"));
    for (const inc of includes) {
        write(path.basename(inc), removeFunctions(fs.readFileSync(inc, "utf8"), replaced));
    }
    for (const dbl of doubles) {
        write("double_" + path.basename(dbl), fs.readFileSync(dbl, "utf8"));
    }
    write("Fixtures.brs", fixtureSource(fixtures));

    const result = spawnSync(process.execPath, [brsCli, ...files], { encoding: "utf8" });
    const output = (result.stdout || "") + (result.stderr || "");
    // Assertion failures, plus interpreter errors such as
    // "Library.brs(80,4-10): Attempting to return ..." (brs may print these
    // and carry on, so they must not be mistaken for a pass).
    const failures = output
        .split(/\r?\n/)
        .filter((l) => l.startsWith("FAIL:") || /\.brs\(\d+,\d+-\d+\):/.test(l));
    const finished = output.match(/^RESULT:\s+(\d+)\s+checks/m);
    const ok = result.status === 0 && finished && failures.length === 0;

    if (ok) {
        console.log(`PASS  ${file}  (${finished[1]} checks)`);
    } else {
        console.log(`FAIL  ${file}`);
        // A crash can repeat the same error many times; show the start.
        const details = finished ? failures : [...new Set(output.trim().split(/\r?\n/))].slice(0, 20);
        console.log(indent(details.join("\n")));
    }
    return ok;
}

// Names of every function/sub defined in a BrightScript source.
function functionNames(text) {
    return [...text.matchAll(/^\s*(?:function|sub)\s+(\w+)\s*\(/gim)].map((m) => m[1].toLowerCase());
}

// Removes the named function/sub blocks from a BrightScript source.
function removeFunctions(text, names) {
    const lines = text.split(/\r?\n/);
    const kept = [];
    let skipping = false;
    for (const line of lines) {
        const start = line.match(/^\s*(?:function|sub)\s+(\w+)\s*\(/i);
        if (!skipping && start && names.has(start[1].toLowerCase())) {
            skipping = true;
            continue;
        }
        if (skipping) {
            if (/^\s*end\s+(function|sub)\b/i.test(line)) skipping = false;
            continue;
        }
        kept.push(line);
    }
    return kept.join("\n");
}

// loadFixtures() puts each fixture's bytes in GetGlobalAA().files[name].
function fixtureSource(fixtures) {
    const lines = ["sub loadFixtures()", "    g = GetGlobalAA()", "    g.files = {}"];
    for (const f of fixtures) {
        const bytes = [...fs.readFileSync(f)].join(", ");
        lines.push(`    g.files["${path.basename(f)}"] = [${bytes}]`);
    }
    lines.push("end sub");
    return lines.join("\n") + "\n";
}

function indent(text) {
    return text
        .split(/\r?\n/)
        .map((l) => "      " + l)
        .join("\n");
}
