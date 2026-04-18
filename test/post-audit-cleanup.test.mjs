import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

const rootDir = process.cwd();

function readFile(relativePath) {
  return fs.readFileSync(path.join(rootDir, relativePath), "utf8");
}

function readBuiltFile(relativePath) {
  return fs.readFileSync(path.join(rootDir, "_site", relativePath), "utf8");
}

function walkFiles(dirPath) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });

  return entries.flatMap((entry) => {
    const fullPath = path.join(dirPath, entry.name);

    if (entry.isDirectory()) {
      return walkFiles(fullPath);
    }

    return [fullPath];
  });
}

test("post listings do not nest aside elements inside links", () => {
  const blogIndex = readBuiltFile(path.join("blog", "index.html"));
  const tagsIndex = readBuiltFile(path.join("tags", "index.html"));

  assert.doesNotMatch(
    blogIndex,
    /<a class="url"[\s\S]*?<aside class="date">/,
    "expected blog listing rows to use non-aside date markup inside links",
  );
  assert.doesNotMatch(
    tagsIndex,
    /<a class="url"[\s\S]*?<aside class="date">/,
    "expected tag listing rows to use non-aside date markup inside links",
  );
});

test("animated helpers respect reduced-motion preferences", () => {
  const helpers = readFile(path.join("_sass", "base", "helpers.sass"));

  assert.match(
    helpers,
    /@media\s*\(prefers-reduced-motion:\s*no-preference\)/,
    "expected animation helper to be guarded by prefers-reduced-motion",
  );
});

test("compiled CSS includes a dedicated print stylesheet for content pages", () => {
  const html = readBuiltFile(path.join("code-execution-for-mcp", "index.html"));

  assert.match(html, /@media print\{/, "expected built CSS to include print rules");
  assert.match(
    html,
    /\.share\{display:none/,
    "expected print rules to hide share controls",
  );
  assert.match(
    html,
    /\.footer-main\{display:none/,
    "expected print rules to hide the footer",
  );
});

test("syntax highlighting uses CSS custom properties instead of hardcoded colors", () => {
  const syntax = readFile(path.join("_sass", "base", "syntax.sass"));

  assert.match(
    syntax,
    /var\(--code-comment\)/,
    "expected syntax colors to read from CSS custom properties",
  );
  assert.doesNotMatch(
    syntax,
    /#dd1144|#999988|#009999/,
    "expected syntax palette to stop hardcoding legacy light-theme hex values",
  );
});

test("Sass source no longer uses legacy Greek design tokens", () => {
  const sassFiles = walkFiles(path.join(rootDir, "_sass"));
  const greekTokenPattern =
    /tokens\.\$(alpha|beta|gama|delta|epsilon|prose)\b/;

  const offenders = sassFiles
    .filter((filePath) => /\.(sass|scss)$/.test(filePath))
    .filter((filePath) => greekTokenPattern.test(fs.readFileSync(filePath, "utf8")))
    .map((filePath) => path.relative(rootDir, filePath));

  assert.deepEqual(
    offenders,
    [],
    `expected semantic token names everywhere under _sass, found: ${offenders.join(", ")}`,
  );
});
