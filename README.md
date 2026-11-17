# ship-it

ship-it is an agent skill that puts the project you're working on onto your [shippedby](https://shippedby.app) profile. It reads the repo, writes a short draft, takes a screenshot of the live site, and publishes only after you say yes.

```sh
npx skills add damongarcia25/ship-it
```

<!-- Replace docs/demo.gif with a real recording of the skill: "ship this", the draft, "yes", the link. -->
![ship-it publishing a project to shippedby](docs/demo.gif)

## Use it

In your coding agent, inside the project's repo, say something like:

- "ship this"
- "publish this to shippedby"
- "add this to my shippedby"

The agent:
1. checks your token
2. reads the README, package.json and landing page
3. finds the live URL in your deploy config, or asks you for it
4. drafts a title, tagline, description and tags
5. takes a 1280x800 screenshot

Then it shows you everything and asks "Publish this to shippedby?". Nothing is sent until you say yes.

## Setup

1. Sign in at [shippedby.app](https://shippedby.app), open [shippedby.app/settings](https://shippedby.app/settings), and make a token under **API tokens**. Copy it right away: it is only shown once.
2. Put it in your shell profile (`~/.zshrc`, `~/.bashrc`) or wherever your agent reads environment variables:

   ```sh
   export SHIPPEDBY_TOKEN=sb_your_token_here
   ```

3. Restart your agent so it picks up the variable.

Anyone with the token can publish to your profile. Keep it out of repos and revoke it in settings if it leaks.

**What you need:**
- `curl`
- Node.js 18 or later, for the screenshot. The first screenshot downloads Playwright's Chromium, about 150 MB.
- If you can't run the screenshot, the agent asks you for an image instead.

## Manual install

`npx skills add` copies `skills/ship-it` into the right place for your agent. To do it by hand, copy that folder (the one with `SKILL.md` and `scripts/`) to one of these paths:

| Agent | This project only | All projects |
| --- | --- | --- |
| Claude Code | `.claude/skills/ship-it/` | `~/.claude/skills/ship-it/` |
| Codex | `.agents/skills/ship-it/` | `~/.agents/skills/ship-it/` |
| Cursor | `.agents/skills/ship-it/` or `.cursor/skills/ship-it/` | `~/.agents/skills/ship-it/` or `~/.cursor/skills/ship-it/` |
| OpenClaw | `<workspace>/skills/ship-it/` | `~/.openclaw/skills/ship-it/` |

For example, for Claude Code on your machine:

```sh
git clone https://github.com/damongarcia25/ship-it.git
mkdir -p ~/.claude/skills
cp -R ship-it/skills/ship-it ~/.claude/skills/
```

## Testing against another server

`SHIPPEDBY_API_BASE` changes the server the scripts talk to. It's meant for a local copy of shippedby:

```sh
export SHIPPEDBY_API_BASE=http://127.0.0.1:8788
```

## What's in the skill

- `SKILL.md`: the steps the agent follows.
- `scripts/whoami.sh`: checks the token with `GET /api/v1/me`.
- `scripts/screenshot.mjs`: the 1280x800 screenshot, through `npx playwright`.
- `scripts/publish.sh`: sends the project with `curl` to `POST /api/v1/projects` and prints its link.

The token only ever goes to curl on stdin. It is never written to a file or passed on the command line.

## License

MIT. See [LICENSE](LICENSE).
