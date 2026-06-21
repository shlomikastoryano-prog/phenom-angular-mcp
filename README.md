# Phenom Angular MCP

MCP server that connects Cursor directly to the Phenom Angular Design System.

Ask Cursor things like:
- *"What are all the @Input() props of the button component?"*
- *"Show me the HTML template for phenom-input"*
- *"How do I use component X? Show me a story example"*

---

## Two MCPs that complement each other

### phenom-angular — reads from your local repo
Works directly against source code. No internet required.

| Tool | Description |
|---|---|
| `list_components` | All components in the DS |
| `search_components` | Search by name or selector |
| `get_component_source` | Full source — TS + HTML + SCSS |
| `get_component_inputs` | All `@Input()` props with types, defaults, descriptions |
| `get_component_outputs` | All `@Output()` EventEmitters |
| `get_story_code` | The full `.stories.ts` file |
| `get_storybook_index` | Live story list from pds.phenom.com |

### storybook-mcp — reads from pds.phenom.com/angular
Works against the live public Storybook. Returns what users see on the site.

| Tool | Description |
|---|---|
| `connect` | Connect to Storybook and verify connection |
| `list` | All components and stories |
| `search` | Search by name or path |
| `get_docs` | Rendered docs — props, code examples, descriptions |
| `screenshot` | Screenshot of a rendered component |

### Why both?

`phenom-angular` knows **how the component is built** — source code, TypeScript, templates.  
`storybook-mcp` knows **how to use the component** — documentation, examples, visuals.

Together: Cursor can answer both *"what are the @Input() props?"* and *"show me a usage example"*.

---

## Installation

### Requirements
- Node.js 18+
- Cursor
- Local clone of https://bitbucket.org/phenompeople/phenom-ds/src/main/

### Step 1 — Clone

```bash
git clone https://github.com/shlomikastoryano-prog/phenom-angular-mcp.git
```
```bash
cd phenom-angular-mcp
```

### Step 2 — Run the install script

```bash
bash install.sh
```

The script will try auto-detect your `phenom-ds` repo path — just press Enter to confirm.

or

The script will ask you:
1. **Where to install the server** — Enter the repo path (`~/Documents/Cursor/phenom-angular-mcp`)
2. Press Enter

### Step 3 — Restart Cursor

Open Cursor → **Settings → MCP**. You should see:
- ✅ `phenom-angular`
- ✅ `storybook-mcp`

---

## Video 
https://drive.google.com/file/d/1vkFX_JVqQQ-c0M7_h5edCt51YtQEojS7/view?usp=sharing


## Questions?

Contact Shlomi Kastoryano
