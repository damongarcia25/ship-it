#!/usr/bin/env node
// Takes a 1280x800 screenshot of a page in headless Chromium, with Playwright run through npx.
//
//   node screenshot.mjs <url> [output-path]
//
// Prints the path of the saved image. With no output path it saves a PNG in the system temp folder. If the PNG
// is over the 3 MB upload limit, it takes a JPEG instead. The first run may download Chromium for Playwright.

import { spawnSync } from "node:child_process";
import { statSync, mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const PLAYWRIGHT = "playwright@1.63.0";
const MAX_BYTES = 3 * 1024 * 1024;

const [url, outArg] = process.argv.slice(2);
if (!url || !/^https?:\/\//i.test(url)) {
  console.error("Usage: node screenshot.mjs <https://url> [output-path]");
  process.exit(2);
}

const npx = process.platform === "win32" ? "npx.cmd" : "npx";
const run = (args) => spawnSync(npx, ["-y", PLAYWRIGHT, ...args], { stdio: ["ignore", "ignore", "pipe"], encoding: "utf8" });

// Chromium for this Playwright version. Quick when it is already there.
const install = run(["install", "chromium"]);
if (install.status !== 0) {
  console.error(`Could not install Chromium for Playwright.\n${install.stderr || ""}`.trim());
  process.exit(1);
}

function shoot(file) {
  const res = run(["screenshot", "--browser", "chromium", "--viewport-size", "1280,800", "--wait-for-timeout", "2000", url, file]);
  if (res.status !== 0) {
    console.error(`Could not take the screenshot of ${url}.\n${res.stderr || ""}`.trim());
    process.exit(1);
  }
  return statSync(file).size;
}

const out = outArg || join(mkdtempSync(join(tmpdir(), "ship-it-")), "screenshot.png");
let file = out;
if (shoot(file) > MAX_BYTES) {
  file = out.replace(/\.(png|webp)$/i, "") + ".jpg";
  if (shoot(file) > MAX_BYTES) {
    console.error(`The screenshot is over 3 MB (${file}). Use a smaller image.`);
    process.exit(1);
  }
}
console.log(file);
