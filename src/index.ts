#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import * as fs from "fs";
import * as path from "path";
import { glob } from "glob";
import { Project, SyntaxKind } from "ts-morph";

// ─── Config ────────────────────────────────────────────────────────────────

const REPO_PATH =
  process.env.REPO_PATH ||
  "/Users/shlomi/Documents/Cursor/Phenom DS/phenom-ds";
const STORYBOOK_URL =
  process.env.STORYBOOK_URL || "https://pds.phenom.com/angular";

// ─── Helpers ───────────────────────────────────────────────────────────────

function readFileSafe(filePath: string): string | null {
  try {
    return fs.readFileSync(filePath, "utf-8");
  } catch {
    return null;
  }
}

/** Given a .component.ts path, find the matching .html and .scss/.css */
function getSiblingFiles(componentTsPath: string) {
  const dir = path.dirname(componentTsPath);
  const base = path.basename(componentTsPath, ".component.ts");
  const html =
    readFileSafe(path.join(dir, `${base}.component.html`)) ??
    readFileSafe(path.join(dir, `${base}.html`));
  const scss =
    readFileSafe(path.join(dir, `${base}.component.scss`)) ??
    readFileSafe(path.join(dir, `${base}.component.css`));
  return { html, scss };
}

/** Find the story file for a component (searches nearby dirs) */
function findStoryFile(componentTsPath: string): string | null {
  const dir = path.dirname(componentTsPath);
  const base = path.basename(componentTsPath, ".component.ts");

  const candidates = [
    path.join(dir, `${base}.stories.ts`),
    path.join(dir, `${base}.component.stories.ts`),
    path.join(dir, "..", `${base}.stories.ts`),
    path.join(dir, "..", "stories", `${base}.stories.ts`),
  ];

  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  return null;
}

/** Extract the Angular selector from a component file */
function extractSelector(source: string): string | null {
  const match = source.match(/selector\s*:\s*['"`]([^'"`]+)['"`]/);
  return match ? match[1] : null;
}

/** Extract @Input() properties using ts-morph AST */
function extractInputs(componentTsPath: string) {
  const project = new Project({ skipAddingFilesFromTsConfig: true });
  const sourceFile = project.addSourceFileAtPath(componentTsPath);

  const results: Array<{
    name: string;
    type: string;
    alias: string | null;
    required: boolean;
    defaultValue: string | null;
    description: string | null;
  }> = [];

  for (const cls of sourceFile.getClasses()) {
    // Properties with @Input() decorator
    for (const prop of cls.getProperties()) {
      const inputDec = prop.getDecorator("Input");
      if (!inputDec) continue;

      // alias: @Input('alias') or @Input({ alias: 'x' })
      let alias: string | null = null;
      const args = inputDec.getArguments();
      if (args.length > 0) {
        const arg = args[0];
        if (
          arg.getKind() === SyntaxKind.StringLiteral ||
          arg.getKind() === SyntaxKind.NoSubstitutionTemplateLiteral
        ) {
          alias = arg.getText().replace(/['"` ]/g, "");
        } else if (arg.getKind() === SyntaxKind.ObjectLiteralExpression) {
          const aliasMatch = arg.getText().match(/alias\s*:\s*['"`]([^'"`]+)['"`]/);
          if (aliasMatch) alias = aliasMatch[1];
        }
      }

      // required: @Input({ required: true })
      let required = false;
      if (args.length > 0) {
        const argText = args[0].getText();
        required = /required\s*:\s*true/.test(argText);
      }
      // also check the TypeScript 16.1+ required signal
      if (prop.hasExclamationToken()) required = true;

      // default value
      const initializer = prop.getInitializer();
      const defaultValue = initializer ? initializer.getText() : null;

      // JSDoc description
      const jsDocs = prop.getJsDocs();
      const description =
        jsDocs.length > 0
          ? jsDocs
              .map((d) => {
                const comment = d.getComment();
                return typeof comment === "string" ? comment : comment?.map(n => n?.getText() ?? "").join("") ?? "";
              })
              .join("\n")
              .trim() || null
          : null;

      results.push({
        name: prop.getName(),
        type: prop.getType().getText(prop),
        alias,
        required,
        defaultValue,
        description,
      });
    }
  }

  return results;
}

/** Extract @Output() EventEmitters */
function extractOutputs(componentTsPath: string) {
  const project = new Project({ skipAddingFilesFromTsConfig: true });
  const sourceFile = project.addSourceFileAtPath(componentTsPath);

  const results: Array<{
    name: string;
    eventType: string;
    description: string | null;
  }> = [];

  for (const cls of sourceFile.getClasses()) {
    for (const prop of cls.getProperties()) {
      const outputDec = prop.getDecorator("Output");
      if (!outputDec) continue;

      const typeArgs = prop.getType().getTypeArguments();
      const eventType =
        typeArgs.length > 0 ? typeArgs[0].getText(prop) : "unknown";

      const jsDocs = prop.getJsDocs();
      const description =
        jsDocs.length > 0
          ? jsDocs
              .map((d) => {
                const comment = d.getComment();
                return typeof comment === "string" ? comment : comment?.map(n => n?.getText() ?? "").join("") ?? "";
              })
              .join("\n")
              .trim() || null
          : null;

      results.push({
        name: prop.getName(),
        eventType,
        description,
      });
    }
  }

  return results;
}

/** Scan the repo for all Angular component files */
async function scanComponents(): Promise<
  Array<{ name: string; selector: string | null; filePath: string; hasStory: boolean }>
> {
  const files = await glob("**/*.component.ts", {
    cwd: REPO_PATH,
    ignore: ["**/node_modules/**", "**/dist/**", "**/*.spec.ts"],
    absolute: true,
  });

  return files.map((f) => {
    const source = readFileSafe(f) ?? "";
    const selector = extractSelector(source);
    const name = path
      .basename(f, ".component.ts")
      .replace(/-/g, " ")
      .replace(/\b\w/g, (c) => c.toUpperCase());
    const hasStory = findStoryFile(f) !== null;
    return {
      name,
      selector,
      filePath: f,
      hasStory,
    };
  });
}

/** Fetch Storybook index.json */
async function fetchStorybookIndex(): Promise<unknown> {
  const res = await fetch(`${STORYBOOK_URL}/index.json`);
  if (!res.ok) throw new Error(`Storybook not reachable at ${STORYBOOK_URL}`);
  return res.json();
}

// ─── MCP Server ────────────────────────────────────────────────────────────

const server = new Server(
  { name: "phenom-angular-mcp", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "list_components",
      description:
        "List all Angular components in the Phenom Design System repo. Returns component name, selector, file path, and whether a story exists.",
      inputSchema: {
        type: "object",
        properties: {
          filter: {
            type: "string",
            description: "Optional text filter by component name or selector",
          },
        },
      },
    },
    {
      name: "get_component_source",
      description:
        "Get the full source code of an Angular component: TypeScript class, HTML template, and SCSS styles.",
      inputSchema: {
        type: "object",
        properties: {
          componentName: {
            type: "string",
            description: "Component name (e.g. 'button') or partial file path",
          },
        },
        required: ["componentName"],
      },
    },
    {
      name: "get_component_inputs",
      description:
        "Get all @Input() properties of an Angular component with types, aliases, required flag, default values, and JSDoc descriptions.",
      inputSchema: {
        type: "object",
        properties: {
          componentName: {
            type: "string",
            description: "Component name or partial file path",
          },
        },
        required: ["componentName"],
      },
    },
    {
      name: "get_component_outputs",
      description:
        "Get all @Output() EventEmitter properties of an Angular component with event types.",
      inputSchema: {
        type: "object",
        properties: {
          componentName: {
            type: "string",
            description: "Component name or partial file path",
          },
        },
        required: ["componentName"],
      },
    },
    {
      name: "get_story_code",
      description:
        "Get the Storybook story file (.stories.ts) for an Angular component.",
      inputSchema: {
        type: "object",
        properties: {
          componentName: {
            type: "string",
            description: "Component name or partial file path",
          },
        },
        required: ["componentName"],
      },
    },
    {
      name: "search_components",
      description:
        "Search components in the Phenom DS by name, selector, or keyword.",
      inputSchema: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "Search term",
          },
        },
        required: ["query"],
      },
    },
    {
      name: "get_storybook_index",
      description:
        "Fetch the live Storybook index (requires Storybook to be running). Returns all stories with their IDs, names, and component groupings.",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      // ── list_components ──────────────────────────────────────────────
      case "list_components": {
        const components = await scanComponents();
        const filter = (args?.filter as string | undefined)?.toLowerCase();
        const filtered = filter
          ? components.filter(
              (c) =>
                c.name.toLowerCase().includes(filter) ||
                c.selector?.toLowerCase().includes(filter)
            )
          : components;

        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                filtered.map((c) => ({
                  name: c.name,
                  selector: c.selector,
                  filePath: c.filePath.replace(REPO_PATH, ""),
                  hasStory: c.hasStory,
                })),
                null,
                2
              ),
            },
          ],
        };
      }

      // ── get_component_source ─────────────────────────────────────────
      case "get_component_source": {
        const query = (args?.componentName as string).toLowerCase();
        const components = await scanComponents();
        const match = components.find(
          (c) =>
            c.name.toLowerCase().includes(query) ||
            c.filePath.toLowerCase().includes(query) ||
            c.selector?.toLowerCase().includes(query)
        );

        if (!match) {
          return {
            content: [{ type: "text", text: `Component "${args?.componentName}" not found.` }],
          };
        }

        const ts = readFileSafe(match.filePath) ?? "(not found)";
        const { html, scss } = getSiblingFiles(match.filePath);

        return {
          content: [
            {
              type: "text",
              text: [
                `# ${match.name} (${match.selector})`,
                `**File:** ${match.filePath.replace(REPO_PATH, "")}`,
                "",
                "## TypeScript",
                "```typescript",
                ts,
                "```",
                html
                  ? ["## Template", "```html", html, "```"].join("\n")
                  : "",
                scss
                  ? ["## Styles", "```scss", scss, "```"].join("\n")
                  : "",
              ]
                .filter(Boolean)
                .join("\n"),
            },
          ],
        };
      }

      // ── get_component_inputs ─────────────────────────────────────────
      case "get_component_inputs": {
        const query = (args?.componentName as string).toLowerCase();
        const components = await scanComponents();
        const match = components.find(
          (c) =>
            c.name.toLowerCase().includes(query) ||
            c.filePath.toLowerCase().includes(query) ||
            c.selector?.toLowerCase().includes(query)
        );

        if (!match) {
          return {
            content: [{ type: "text", text: `Component "${args?.componentName}" not found.` }],
          };
        }

        const inputs = extractInputs(match.filePath);

        return {
          content: [
            {
              type: "text",
              text:
                inputs.length === 0
                  ? `No @Input() properties found in ${match.name}.`
                  : JSON.stringify(inputs, null, 2),
            },
          ],
        };
      }

      // ── get_component_outputs ────────────────────────────────────────
      case "get_component_outputs": {
        const query = (args?.componentName as string).toLowerCase();
        const components = await scanComponents();
        const match = components.find(
          (c) =>
            c.name.toLowerCase().includes(query) ||
            c.filePath.toLowerCase().includes(query) ||
            c.selector?.toLowerCase().includes(query)
        );

        if (!match) {
          return {
            content: [{ type: "text", text: `Component "${args?.componentName}" not found.` }],
          };
        }

        const outputs = extractOutputs(match.filePath);

        return {
          content: [
            {
              type: "text",
              text:
                outputs.length === 0
                  ? `No @Output() properties found in ${match.name}.`
                  : JSON.stringify(outputs, null, 2),
            },
          ],
        };
      }

      // ── get_story_code ───────────────────────────────────────────────
      case "get_story_code": {
        const query = (args?.componentName as string).toLowerCase();
        const components = await scanComponents();
        const match = components.find(
          (c) =>
            c.name.toLowerCase().includes(query) ||
            c.filePath.toLowerCase().includes(query) ||
            c.selector?.toLowerCase().includes(query)
        );

        if (!match) {
          return {
            content: [{ type: "text", text: `Component "${args?.componentName}" not found.` }],
          };
        }

        const storyPath = findStoryFile(match.filePath);
        if (!storyPath) {
          return {
            content: [
              {
                type: "text",
                text: `No story file found for ${match.name}. The component exists at ${match.filePath.replace(REPO_PATH, "")} but has no .stories.ts nearby.`,
              },
            ],
          };
        }

        const storyCode = readFileSafe(storyPath) ?? "(empty)";
        return {
          content: [
            {
              type: "text",
              text: [
                `# ${match.name} Stories`,
                `**File:** ${storyPath.replace(REPO_PATH, "")}`,
                "",
                "```typescript",
                storyCode,
                "```",
              ].join("\n"),
            },
          ],
        };
      }

      // ── search_components ────────────────────────────────────────────
      case "search_components": {
        const query = (args?.query as string).toLowerCase();
        const components = await scanComponents();
        const results = components.filter(
          (c) =>
            c.name.toLowerCase().includes(query) ||
            c.selector?.toLowerCase().includes(query) ||
            c.filePath.toLowerCase().includes(query)
        );

        return {
          content: [
            {
              type: "text",
              text:
                results.length === 0
                  ? `No components found matching "${args?.query}".`
                  : JSON.stringify(
                      results.map((c) => ({
                        name: c.name,
                        selector: c.selector,
                        filePath: c.filePath.replace(REPO_PATH, ""),
                        hasStory: c.hasStory,
                      })),
                      null,
                      2
                    ),
            },
          ],
        };
      }

      // ── get_storybook_index ──────────────────────────────────────────
      case "get_storybook_index": {
        const index = await fetchStorybookIndex();
        return {
          content: [{ type: "text", text: JSON.stringify(index, null, 2) }],
        };
      }

      default:
        return {
          content: [{ type: "text", text: `Unknown tool: ${name}` }],
          isError: true,
        };
    }
  } catch (err) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${err instanceof Error ? err.message : String(err)}`,
        },
      ],
      isError: true,
    };
  }
});

// ─── Start ─────────────────────────────────────────────────────────────────

const transport = new StdioServerTransport();
await server.connect(transport);
