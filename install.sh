#!/usr/bin/env bash
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Phenom Angular MCP — Installer       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# Install in-place (where the repo was cloned)
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Ask for the DS repo path ────────────────────────────────────────────────

CANDIDATE_PATHS=(
  "$HOME/Documents/Cursor/Phenom DS/phenom-ds"
  "$HOME/Documents/Cursor/Design system/phenom-ds"
  "$HOME/phenom/angular-ds"
  "$HOME/code/phenom-ds"
  "$HOME/Documents/phenom-ds"
)

AUTO_DETECTED=""
for p in "${CANDIDATE_PATHS[@]}"; do
  if [ -d "$p" ]; then
    AUTO_DETECTED="$p"
    break
  fi
done

if [ -n "$AUTO_DETECTED" ]; then
  echo -e "${YELLOW}Found your Phenom DS repo at:${NC}"
  echo -e "  ${GREEN}${AUTO_DETECTED}${NC}"
  echo -e "${YELLOW}Press Enter to confirm, or type a different path:${NC}"
  read -r DS_PATH
  DS_PATH="${DS_PATH:-$AUTO_DETECTED}"
else
  echo -e "${YELLOW}Where is your local phenom-ds repo?${NC}"
  echo -e "  Example: /Users/yourname/Documents/phenom-ds"
  read -r DS_PATH
  while [ ! -d "$DS_PATH" ]; do
    echo -e "${RED}  Not found. Try again:${NC}"
    read -r DS_PATH
  done
fi

# Guard: prevent installing INTO the DS repo
if [[ "$INSTALL_DIR" == "$DS_PATH"* ]] || [[ "$DS_PATH" == "$INSTALL_DIR"* ]]; then
  echo -e "${RED}Error: Install dir and DS repo path overlap. Make sure you cloned phenom-angular-mcp to a separate folder.${NC}"
  exit 1
fi

echo ""
echo -e "  ${GREEN}✓${NC} DS repo:     ${DS_PATH}"
echo -e "  ${GREEN}✓${NC} MCP server:  ${INSTALL_DIR}"
echo ""

# ── Detect npx path (handles nvm, homebrew, etc.) ───────────────────────────
NPX_PATH=$(which npx 2>/dev/null || echo "npx")
echo -e "  ${GREEN}✓${NC} npx:          ${NPX_PATH}"
echo ""

# ── Install & build ─────────────────────────────────────────────────────────
echo -e "${CYAN}→ Installing dependencies...${NC}"
cd "$INSTALL_DIR"
npm install --silent

echo -e "${CYAN}→ Building...${NC}"
npm run build
echo -e "${GREEN}✓ Build successful${NC}"
echo ""

# ── Merge into ~/.cursor/mcp.json ───────────────────────────────────────────
CURSOR_MCP="$HOME/.cursor/mcp.json"
STORYBOOK_URL="https://pds.phenom.com/angular"
SERVER_PATH="${INSTALL_DIR}/dist/index.js"

echo -e "${CYAN}→ Updating ~/.cursor/mcp.json...${NC}"

python3 - "$DS_PATH" "$SERVER_PATH" "$STORYBOOK_URL" "$CURSOR_MCP" "$NPX_PATH" <<'PYEOF'
import json, os, sys

ds_path, server_path, storybook_url, cursor_mcp, npx_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

new_servers = {
  "phenom-angular": {
    "command": "node",
    "args": [server_path],
    "env": {
      "REPO_PATH": ds_path,
      "STORYBOOK_URL": storybook_url
    }
  },
  "storybook-mcp": {
    "command": npx_path,
    "args": ["-y", "@raksbisht/storybook-mcp"],
    "env": {
      "STORYBOOK_URL": storybook_url
    }
  }
}

if os.path.exists(cursor_mcp):
    with open(cursor_mcp, "r") as f:
        config = json.load(f)
else:
    os.makedirs(os.path.dirname(cursor_mcp), exist_ok=True)
    config = {}

if "mcpServers" not in config:
    config["mcpServers"] = {}

config["mcpServers"].update(new_servers)

with open(cursor_mcp, "w") as f:
    json.dump(config, f, indent=2)

print("Done")
PYEOF

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Installation complete! 🎉        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Restart Cursor and go to ${CYAN}Settings → MCP${NC}"
echo -e "  You should see: ${CYAN}phenom-angular${NC} and ${CYAN}storybook-mcp${NC}"
echo ""
echo -e "  Try asking Cursor:"
echo -e "  ${YELLOW}\"Show me all @Input() props for the button component\"${NC}"
echo ""
