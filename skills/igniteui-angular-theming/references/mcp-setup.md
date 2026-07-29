> **OpenClaw safety note:** Commands and MCP tool calls in this reference are examples. Do not install packages, configure MCP/IDE settings, start servers, run destructive operations, or write external config without Camilo's explicit approval. If MCP tools are unavailable, use the bundled references and call out any API uncertainty. Do not store sensitive data in client-side state.


## OpenClaw Safety Adapter

This skill has been adapted for Lucy/OpenClaw.

- Do **not** automatically install npm packages, configure MCP servers, edit IDE settings, or write external configuration without Camilo's explicit approval.
- First inspect the project (`package.json`, Angular version, installed Ignite UI package variant, existing theme/config).
- If an Ignite UI MCP server/tool is already available, use it to verify current APIs. If it is unavailable, use the bundled references and say when an answer should be checked against vendor docs.
- Project `docs/STANDARDS.md`, SDD phase gates, and higher-priority workspace rules remain authoritative.
- Never put secrets, license tokens, private registry credentials, or PATs in code, docs, logs, or chat.

# Setting Up the Theming MCP Server

> **Part of the [`igniteui-angular-theming`](../SKILL.md) skill hub.**

## Contents

- [VS Code](#vs-code)
- [Cursor](#cursor)
- [Claude Desktop](#claude-desktop)
- [WebStorm / JetBrains IDEs](#webstorm--jetbrains-ides)
- [Verifying the Setup](#verifying-the-setup)

The Ignite UI Theming MCP server enables AI assistants to generate production-ready theming code. It must be configured in your editor before the theming tools become available.

## VS Code

Create or edit `.vscode/mcp.json` in your project:

```json
{
  "servers": {
    "igniteui-theming": {
      "command": "npx",
      "args": ["-y", "igniteui-theming", "igniteui-theming-mcp"]
    }
  }
}
```

This works whether `igniteui-theming` is installed locally in `node_modules` or needs to be pulled from the npm registry — `npx -y` handles both cases.

## Cursor

Create or edit `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "igniteui-theming": {
      "command": "npx",
      "args": ["-y", "igniteui-theming", "igniteui-theming-mcp"]
    }
  }
}
```

## Claude Desktop

Edit the Claude Desktop config file:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "igniteui-theming": {
      "command": "npx",
      "args": ["-y", "igniteui-theming", "igniteui-theming-mcp"]
    }
  }
}
```

## WebStorm / JetBrains IDEs

1. Go to **Settings → Tools → AI Assistant → MCP Servers**
2. Click **+ Add MCP Server**
3. Set Command to `npx` and Arguments to `igniteui-theming igniteui-theming-mcp`
4. Click OK and restart the AI Assistant

## Verifying the Setup

After configuring the MCP server, ask your AI assistant:

> "Detect which Ignite UI platform my project uses"

If the MCP server is running, the `detect_platform` tool will analyze your `package.json` and return the detected platform (e.g., `angular`).
