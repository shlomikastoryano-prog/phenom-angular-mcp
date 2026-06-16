# Phenom Angular MCP — Install Guide

## Step 1 — Copy the project folder

Copy the `phenom-angular-mcp` folder to:
```
/Users/shlomi/Documents/Cursor/phenom-angular-mcp
```

## Step 2 — Install dependencies & build

Open Terminal, run:
```bash
cd "/Users/shlomi/Documents/Cursor/phenom-angular-mcp"
npm install
npm run build
```

You should see a `dist/` folder appear.

## Step 3 — Configure Cursor

Open (or create) the Cursor MCP config file:
```
~/.cursor/mcp.json
```

Paste the contents of `cursor-mcp.json` into it.
If the file already exists, merge the `mcpServers` block into it.

> **Note:** If your Storybook runs on a different port than 6006,
> change `STORYBOOK_URL` in both servers accordingly.

## Step 4 — Restart Cursor

Close and reopen Cursor. Go to **Settings → MCP** to verify both servers show as connected:
- `phenom-angular` ✓
- `phenom-design-system-extractor` ✓

## Available tools after setup

### phenom-angular (reads from your repo — no Storybook needed)
| Tool | What it does |
|---|---|
| `list_components` | All Angular components in the DS |
| `search_components` | Search by name / selector |
| `get_component_source` | Full TS + HTML + SCSS source |
| `get_component_inputs` | All `@Input()` props with types & defaults |
| `get_component_outputs` | All `@Output()` EventEmitters |
| `get_story_code` | The `.stories.ts` file |
| `get_storybook_index` | Live story index (Storybook must be running) |

### storybook-mcp (reads from https://pds.phenom.com/angular via Playwright)
| Tool | What it does |
|---|---|
| `list` | All components and stories |
| `search` | Search by name or path |
| `get_docs` | Docs, code examples, and args for a story |
| `screenshot` | Screenshot of a rendered component |

## Example prompts in Cursor

```
Show me all the @Input() props for the button component

Get the HTML template for phenom-input-field

What components are available in the Phenom DS?

Show me the story code for the dropdown component
```

## Troubleshooting

**`dist/index.js` not found** — run `npm run build` again inside the folder.

**Storybook tools fail** — make sure `npm run storybook` is running in your DS repo first.

**Wrong port** — check which port Storybook uses: `cat package.json | grep storybook`, update `STORYBOOK_URL` in `~/.cursor/mcp.json`.
