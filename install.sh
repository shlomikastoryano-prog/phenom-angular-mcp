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

# ── Detect node/npm paths (handles nvm, homebrew, etc.) ─────────────────────
NODE_BIN=$(dirname "$(which node 2>/dev/null || echo "node")")
NPM_PATH="$NODE_BIN/npm"
NODE_PATH="$NODE_BIN/node"

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
  echo -e "${RED}Error: Install dir and DS repo path overlap.${NC}"
  exit 1
fi

echo ""
echo -e "  ${GREEN}✓${NC} DS repo:    ${DS_PATH}"
echo -e "  ${GREEN}✓${NC} MCP server: ${INSTALL_DIR}"
echo -e "  ${GREEN}✓${NC} node:       ${NODE_PATH}"
echo ""

# ── Install & build phenom-angular ──────────────────────────────────────────
echo -e "${CYAN}→ Installing dependencies...${NC}"
cd "$INSTALL_DIR"
"$NPM_PATH" install --silent

echo -e "${CYAN}→ Building...${NC}"
"$NPM_PATH" run build
echo -e "${GREEN}✓ Build successful${NC}"
echo ""

# ── Install @raksbisht/storybook-mcp globally ───────────────────────────────
echo -e "${CYAN}→ Installing storybook-mcp globally...${NC}"
"$NPM_PATH" install -g @raksbisht/storybook-mcp --silent
STORYBOOK_MCP_BIN="$NODE_BIN/storybook-mcp"
echo -e "${GREEN}✓ storybook-mcp installed at ${STORYBOOK_MCP_BIN}${NC}"
echo ""

# ── Merge into ~/.cursor/mcp.json ───────────────────────────────────────────
CURSOR_MCP="$HOME/.cursor/mcp.json"
STORYBOOK_URL="https://pds.phenom.com/angular"
SERVER_PATH="${INSTALL_DIR}/dist/index.js"

echo -e "${CYAN}→ Updating ~/.cursor/mcp.json...${NC}"

python3 - "$DS_PATH" "$SERVER_PATH" "$STORYBOOK_URL" "$CURSOR_MCP" "$NODE_PATH" "$STORYBOOK_MCP_BIN" <<'PYEOF'
import json, os, sys

ds_path, server_path, storybook_url, cursor_mcp, node_path, storybook_mcp_bin = \
  sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]

new_servers = {
  "phenom-angular": {
    "command": node_path,
    "args": [server_path],
    "env": {
      "REPO_PATH": ds_path,
      "STORYBOOK_URL": storybook_url
    }
  },
  "storybook-mcp": {
    "command": node_path,
    "args": [storybook_mcp_bin],
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
