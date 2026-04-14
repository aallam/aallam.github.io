import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";

const siteRoot = process.cwd();
const siteUrl = "https://mouaad.aallam.com";
const defaultImage = `${siteUrl}/assets/images/social-card.png`;

function readBuiltPage(relativePath) {
  const filePath = path.join(siteRoot, "_site", relativePath);
  return readFileSync(filePath, "utf8");
}

function countMatches(html, pattern) {
  return [...html.matchAll(pattern)].length;
}

function getMetaContent(html, attr, name) {
  const pattern = new RegExp(
    `<meta\\s+${attr}=["']${name}["']\\s+content=["']([^"']+)["']`,
    "i",
  );
  const match = html.match(pattern);
  assert.ok(match, `Expected meta ${attr}=${name}`);
  return match[1];
}

function getMetaContentByEitherAttr(html, name) {
  for (const attr of ["name", "property"]) {
    const pattern = new RegExp(
      `<meta\\s+${attr}=["']${name}["']\\s+content=["']([^"']+)["']`,
      "i",
    );
    const match = html.match(pattern);
    if (match) return match[1];
  }
  assert.fail(`Expected meta tag for ${name}`);
}

function assertCommonMetadata(html, { description, image }) {
  assert.equal(
    countMatches(html, /<link rel="canonical" href="[^"]+"/g),
    1,
    "Expected exactly one canonical link",
  );
  assert.equal(
    countMatches(html, /<meta name="description" content="[^"]+"/g),
    1,
    "Expected exactly one description meta tag",
  );
  assert.equal(
    getMetaContent(html, "name", "description"),
    description,
    "Unexpected page description",
  );
  assert.equal(
    getMetaContent(html, "name", "twitter:card"),
    "summary_large_image",
    "Expected large Twitter card",
  );
  assert.equal(
    getMetaContentByEitherAttr(html, "og:image"),
    image,
    "Unexpected OG image",
  );
  assert.equal(
    getMetaContentByEitherAttr(html, "twitter:image"),
    image,
    "Unexpected Twitter image",
  );
  assert.equal(
    countMatches(html, /<meta name="twitter:site" content="[^"]+"/g),
    0,
    "Did not expect site-level Twitter account metadata",
  );
  assert.equal(
    countMatches(html, /<meta name="twitter:creator" content="[^"]+"/g),
    0,
    "Did not expect creator-level Twitter account metadata",
  );
}

test("public pages emit one clean set of large-card metadata", () => {
  const expectations = [
    {
      path: "index.html",
      description:
        "Software engineer writing about systems design, cloud infrastructure, Kotlin, Java, and reliable software.",
      image: defaultImage,
    },
    {
      path: "about/index.html",
      description:
        "About Mouaad Aallam, a software engineer focused on architecture, cloud infrastructure, DevOps, Kotlin, and Java.",
      image: defaultImage,
    },
    {
      path: "blog/index.html",
      description:
        "Articles about software engineering, architecture, the JVM, Kotlin, RxJava, and building reliable systems.",
      image: defaultImage,
    },
    {
      path: "projects/index.html",
      description:
        "Projects, experiments, and open-source work by Mouaad Aallam across software engineering and infrastructure.",
      image: defaultImage,
    },
    {
      path: "tags/index.html",
      description:
        "Browse posts by topic across software engineering, architecture, JVM, Kotlin, RxJava, and infrastructure.",
      image: defaultImage,
    },
  ];

  for (const expectation of expectations) {
    const html = readBuiltPage(expectation.path);
    assertCommonMetadata(html, expectation);
  }
});

test("posts can override the default card image while fallback remains available", () => {
  const explicitImagePost = readBuiltPage("kotlin-coroutines-basics/index.html");
  assertCommonMetadata(explicitImagePost, {
    description:
      "Learn Kotlin coroutines fundamentals: builders, structured concurrency, dispatchers, and scopes. Practical guide with examples for async programming.",
    image: `${siteUrl}/assets/images/blog/kotlin_coroutines_banner.png`,
  });

  const fallbackPost = readBuiltPage("hello-world/index.html");
  assertCommonMetadata(fallbackPost, {
    description: "The first post of the website/blog",
    image: defaultImage,
  });
});
