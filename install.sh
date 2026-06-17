#!/usr/bin/env bash

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

# ── Check Node version >= 18 ─────────────────────────────────────────────────
NODE_MAJOR=$(node -e "console.log(process.versions.node.split('.')[0])" 2>/dev/null || echo "0")
if [ "$NODE_MAJOR" -lt 18 ]; then
  echo -e "${RED}✗ Node.js 18+ required. You have Node $(node -v 2>/dev/null).${NC}"
  echo ""
  echo -e "  Fix: ${YELLOW}nvm install 18 && nvm alias default 18 && nvm use 18${NC}"
  echo -e "  Then re-run: ${YELLOW}bash install.sh${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} Node $(node -v)"

# ── Paths ────────────────────────────────────────────────────────────────────
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_PATH=$(which node)
NODE_BIN=$(dirname "$NODE_PATH")
NPM_PATH="$NODE_BIN/npm"
NPX_PATH="$NODE_BIN/npx"

IS_NVM=false
[[ "$NODE_PATH" == *".nvm"* ]] && IS_NVM=true && echo -e "  ${YELLOW}⚠${NC}  nvm detected — using full paths"

# ── Ask for the DS repo path ─────────────────────────────────────────────────
CANDIDATE_PATHS=(
  "$HOME/Documents/Cursor/Phenom DS/phenom-ds"
  "$HOME/Documents/Cursor/Design system/phenom-ds"
  "$HOME/phenom/angular-ds"
  "$HOME/code/phenom-ds"
  "$HOME/Documents/phenom-ds"
)

AUTO_DETECTED=""
for p in "${CANDIDATE_PATHS[@]}"; do
  if [ -d "$p" ]; then AUTO_DETECTED="$p"; break; fi
done

if [ -n "$AUTO_DETECTED" ]; then
  echo ""
  echo -e "${YELLOW}Found your Phenom DS repo at:${NC}"
  echo -e "  ${GREEN}${AUTO_DETECTED}${NC}"
  echo -e "${YELLOW}Press Enter to confirm, or type a different path:${NC}"
  read -r DS_PATH
  DS_PATH="${DS_PATH:-$AUTO_DETECTED}"
else
  echo ""
  echo -e "${YELLOW}Where is your local phenom-ds repo?${NC}"
  echo -e "  Example: /Users/yourname/Documents/phenom-ds"
  read -r DS_PATH
  while [ ! -d "$DS_PATH" ]; do
    echo -e "${RED}  Not found. Try again:${NC}"
    read -r DS_PATH
  done
fi

if [[ "$INSTALL_DIR" == "$DS_PATH"* ]] || [[ "$DS_PATH" == "$INSTALL_DIR"* ]]; then
  echo -e "${RED}Error: Install dir and DS repo path overlap.${NC}"
  exit 1
fi

echo ""
echo -e "  ${GREEN}✓${NC} DS repo:    ${DS_PATH}"
echo -e "  ${GREEN}✓${NC} MCP server: ${INSTALL_DIR}"
echo ""

# ── Install & build ──────────────────────────────────────────────────────────
echo -e "${CYAN}→ Installing dependencies...${NC}"
cd "$INSTALL_DIR"
if ! "$NPM_PATH" install --silent; then
  echo -e "${RED}✗ npm install failed${NC}"
  exit 1
fi

echo -e "${CYAN}→ Building...${NC}"
if ! "$NPM_PATH" run build; then
  echo -e "${RED}✗ Build failed${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Build successful${NC}"
echo ""

# ── Write ~/.cursor/mcp.json ─────────────────────────────────────────────────
CURSOR_MCP="$HOME/.cursor/mcp.json"
STORYBOOK_URL="https://pds.phenom.com/angular"
SERVER_PATH="${INSTALL_DIR}/dist/index.js"

echo -e "${CYAN}→ Updating ~/.cursor/mcp.json...${NC}"

python3 - "$DS_PATH" "$SERVER_PATH" "$STORYBOOK_URL" "$CURSOR_MCP" "$NODE_PATH" "$NPX_PATH" "$IS_NVM" <<'PYEOF'
import json, os, sys

ds_path, server_path, storybook_url, cursor_mcp, node_path, npx_path, is_nvm = \
  sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7]

# nvm users: use full npx path so Cursor finds it
# system node users: plain "npx" works fine
sb_command = npx_path if is_nvm == "true" else "npx"

config = {}
if os.path.exists(cursor_mcp):
    try:
        with open(cursor_mcp) as f:
            config = json.load(f)
    except:
        config = {}

if "mcpServers" not in config:
    config["mcpServers"] = {}

config["mcpServers"]["phenom-angular"] = {
    "command": node_path,
    "args": [server_path],
    "env": {"REPO_PATH": ds_path, "STORYBOOK_URL": storybook_url}
}
config["mcpServers"]["storybook-mcp"] = {
    "command": sb_command,
    "args": ["-y", "@raksbisht/storybook-mcp"],
    "env": {"STORYBOOK_URL": storybook_url}
}

os.makedirs(os.path.dirname(cursor_mcp), exist_ok=True)
with open(cursor_mcp, "w") as f:
    json.dump(config, f, indent=2)

print("Done")
PYEOF

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Installation complete! 🎉        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Restart Cursor → ${CYAN}Settings → MCP${NC}"
echo -e "  You should see: ${CYAN}phenom-angular${NC} and ${CYAN}storybook-mcp${NC}"
echo ""
echo -e "  Try asking Cursor:"
echo -e "  ${YELLOW}\"Show me all @Input() props for the button component\"${NC}"
echo ""
