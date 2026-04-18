import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

const rootDir = process.cwd();

function readBuiltFile(relativePath) {
  return fs.readFileSync(path.join(rootDir, "_site", relativePath), "utf8");
}

test("built pages load JetBrains Mono from Google Fonts", () => {
  const html = readBuiltFile(path.join("index.html"));

  assert.match(
    html,
    /fonts\.googleapis\.com\/css2\?[^"]*family=JetBrains\+Mono/,
    "expected built HTML to request JetBrains Mono from Google Fonts",
  );
});
