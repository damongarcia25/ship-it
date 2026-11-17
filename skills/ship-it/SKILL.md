---
name: ship-it
description: Publishes the project in the current repo to the user's shippedby profile (shippedby.app). It reads the repo, drafts a title, tagline, description and tags, takes a screenshot of the live site, shows the draft, and publishes only after the user says yes. Use when the user says "ship this", "ship it", "publish to shippedby", "add this to my shippedby", "put this on shippedby" or "post this project to my profile".
---

# ship-it

Adds the project in this repo to the user's shippedby profile as a shipped project. Follow the steps in order.
Do not skip the confirmation in step 6.

The scripts live in the `scripts/` folder next to this file. Below, `SKILL_DIR` means the folder that holds
this SKILL.md. Run the scripts by their full path from the repo being published, so relative paths resolve there.

The API is at `https://shippedby.app`. If `SHIPPEDBY_API_BASE` is set, use that instead (it is for testing).
The scripts already handle this.

## 1. Check the token

Check that `SHIPPEDBY_TOKEN` is set in the environment. Do not print its value, and never write it to a file.

If it is missing, tell the user exactly this, then stop:

> Create a token at https://shippedby.app/settings (API tokens), then run:
> `export SHIPPEDBY_TOKEN=sb_your_token_here`
> and ask me again.

If it is set, run:

```sh
sh "SKILL_DIR/scripts/whoami.sh"
```

It prints `username` and `profile_url` when the token works. If it prints an error (a 401 means the token is
wrong or revoked), show the error, repeat the token instructions above, and stop.

## 2. Read the repo

Read what the project says about itself:

- `README.md` (or `README`, `readme.md`)
- `package.json`: `name`, `description`, `homepage`, `keywords`
- The landing page copy: `index.html`, `public/index.html`, or the main page component
  (`src/App.*`, `app/page.*`, `pages/index.*`, `src/routes/+page.svelte` and similar)

Note what it does, who it is for, and what it is built with. Do not read `.env` files or anything with secrets.

## 3. Find the live URL

Look for the address where people use the project, in this order:

- `wrangler.toml` or `wrangler.json(c)`: `routes`, `route`, custom domains
- `vercel.json`: aliases or domains
- `netlify.toml`
- `CNAME` (GitHub Pages)
- `package.json` `homepage`
- Links in the README, like "Live:", "Try it", "Demo" or a site badge

It has to be a public `https://` address. Ignore `localhost`, preview URLs with long hashes, and API endpoints.
If there is no clear answer, or there are several, ask the user once: "What's the live URL for this project?"

Also note the repo URL if there is one: `git remote get-url origin` (turn `git@github.com:a/b.git` into
`https://github.com/a/b`). Leave it out if the repo is private or there is no remote.

## 4. Write the draft

- **title**: the project's name, up to 80 characters.
- **tagline**: one line on what it is, up to 140 characters. No period needed.
- **description**: 2 to 4 short sentences, up to 1000 characters. Say what it does, who it is for and one thing
  that makes it useful. Plain words. No hype words ("revolutionary", "seamless", "powerful", "game-changing",
  "unleash", "supercharge", "cutting-edge"), no em dashes, no emoji, no exclamation marks.
- **tags**: up to 5 short tags, each under 24 characters, lowercase unless it is a name (for example
  `ai, chrome extension, Cloudflare`).

Write it the way the project's own README talks about it. Don't invent features the repo doesn't show.

## 5. Take the screenshot

```sh
node "SKILL_DIR/scripts/screenshot.mjs" "<live_url>"
```

It opens the page in a headless browser at 1280x800 and prints the path of the image it saved. The first run
may download Playwright's Chromium, which takes a minute. If it fails (no Node, no network, the page blocks
headless browsers), tell the user what happened and ask for the path to a PNG, JPEG or WebP screenshot instead
(3 MB at most).

## 6. Show the draft and ask

Show everything that will be published, like this:

```
Title:       ...
Tagline:     ...
Description: ...
Live URL:    ...
Repo URL:    ... (or "none")
Tags:        ...
Screenshot:  /path/to/screenshot.png
Profile:     <profile_url from step 1>
```

Then ask: **"Publish this to shippedby?"**

- Publish only after a clear yes ("yes", "publish it", "go ahead").
- If the user asks for changes, make them, show the full draft again and ask again.
- Anything else (no answer, "maybe", "not now") means do not publish.

## 7. Publish

```sh
sh "SKILL_DIR/scripts/publish.sh" \
  --title "..." \
  --tagline "..." \
  --description "..." \
  --live-url "..." \
  --repo-url "..." \
  --tags "tag one, tag two" \
  --screenshot "/path/to/screenshot.png"
```

Leave out `--repo-url` when there is none. On success it prints the project's link on shippedby. Show the user
that link. If the answer says the link is hidden until the site is verified, pass that on too: the project shows
on their profile right away, and the live link appears once they verify the site from their shippedby editor.

If it fails, show the error it printed. What the codes mean:

- 400: a field is missing or too long. Fix the field, show the draft again and ask before trying again.
- 401: the token is wrong or revoked. Go back to step 1.
- 409: the profile has no handle yet, or already holds 12 projects.
- 413 or 415: the screenshot is too big or is not a PNG, JPEG or WebP image.
- 422: the live URL did not load. The message says why. Check the URL with the user.
- 429: too many projects published with this token lately. Tell the user when they can try again.

Do not retry a failed publish more than once without asking the user.
