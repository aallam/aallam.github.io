import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

const rootDir = process.cwd();

function readBuiltFile(relativePath) {
  return fs.readFileSync(path.join(rootDir, "_site", relativePath), "utf8");
}

test("built pages serve JetBrains Mono locally", () => {
  const html = readBuiltFile(path.join("index.html"));

  assert.match(
    html,
    /src:url\(["']?\/assets\/fonts\/jetbrains-mono-[^)]*\.woff2/,
    "expected built CSS to declare the locally served JetBrains Mono font",
  );
});

test("compiled code styles use JetBrains Mono as the primary monospace font", () => {
  const html = readBuiltFile(path.join("index.html"));

  assert.match(
    html,
    /code,tt\{[^}]*font-family:"JetBrains Mono"/,
    "expected compiled inline code styles to use JetBrains Mono first",
  );
  assert.match(
    html,
    /pre\{[^}]*font-family:"JetBrains Mono"/,
    "expected compiled preformatted code styles to use JetBrains Mono first",
  );
});
