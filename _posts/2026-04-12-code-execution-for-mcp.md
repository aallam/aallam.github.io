---
title: "Code execution for MCP agents"
layout: post
date: 2026-04-12 12:10
description: "Why code execution helps MCP agents scale beyond direct tool loops, and how execbox keeps capability and runtime boundaries explicit."
mermaid: true
tag:
- MCP
- AI Agents
- Architecture
blog: true
jemoji:
---

There is a useful shift happening in MCP agent design: instead of asking the model to call one tool at a time, let it write small programs that call tools inside a controlled execution environment.

That changes the shape of the system. Tool definitions do not all have to sit in the model context. Intermediate results do not all have to be replayed through the model. Multi-step logic can run closer to the data it is manipulating.

This is the pattern [`execbox`](https://github.com/aallam/execbox) is built around: a reusable Node.js library layer for exposing host-defined tools and wrapped MCP servers to guest JavaScript, while keeping capability and runtime boundaries explicit.

<div class="text-center" markdown="1">
![Direct MCP tool calling versus code execution][0]{:width="90%"}
</div>

## Problem

Direct MCP tool loops are a good default. The client exposes tools, the model picks one, the host executes it, the result goes back into context, and the model decides what to do next.

That loop is simple, but it scales poorly once the tool catalog or intermediate data gets large:

- every exposed tool definition consumes context,
- every intermediate result passes back through the model,
- large payloads are copied and summarized repeatedly,
- multi-step control flow becomes token-heavy.

For tools that return large documents, search results, database rows, logs, or API payloads, the loop spends too much of the model budget on mechanical data movement. A compact programming surface lets the model call tool-like APIs, filter intermediate values locally, and return only the final result the host needs to see.

## Signals

Anthropic and Cloudflare have both described the same architecture pressure.

Anthropic's post, [Code execution with MCP: Building more efficient agents](https://www.anthropic.com/engineering/code-execution-with-mcp), frames direct MCP usage around two scaling problems: tool definitions consume context, and intermediate results consume more context. Their answer is to let the model write code against tool-like APIs, load definitions on demand, and keep intermediate processing inside the execution environment.

Cloudflare's post, [Code Mode: give agents an entire API in 1,000 tokens](https://blog.cloudflare.com/code-mode-mcp/), makes the same argument from the API side: a large tool surface can become a smaller typed SDK surface that the model uses from generated code. Cloudflare then followed with [Sandboxing AI agents, 100x faster](https://blog.cloudflare.com/dynamic-workers/), focused on where generated code should run.

Together, these posts point in the same direction: direct tool calling is useful but expensive at scale, code execution can compress data movement, and the runtime cannot be an afterthought.

## Execbox

`execbox` is the library layer I wanted for that pattern. It is not an agent framework or hosted sandbox product; it is a set of Node.js packages that turn host capabilities into callable guest namespaces, then run guest JavaScript against those namespaces through a chosen executor.

The package map is intentionally small: `@execbox/core` owns the execution contract, provider resolution, and MCP adapters; `@execbox/quickjs` provides inline and worker-hosted QuickJS execution; and `@execbox/remote` provides a transport-backed executor for app-owned runner boundaries.

The core flow stays the same across those packages: host code defines tools or discovers them from MCP, those tools become a deterministic guest namespace, guest code runs against that namespace, tool calls cross a host-controlled boundary, and results come back as JSON-compatible data. The same guest code shape can start with inline QuickJS, move to worker-hosted QuickJS, or run through a remote transport that the application owns.

MCP can appear on either side of the flow. Upstream MCP servers can be wrapped into guest namespaces, and execbox can also expose code execution itself as an MCP server so a client gets a compact code-running surface instead of a large direct tool catalog.

## Usage

In TypeScript, a typical MCP provider flow starts with an MCP server declared through the MCP SDK, then wraps it as an execbox provider.

```ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { openMcpToolProvider } from "@execbox/core/mcp";
import { QuickJsExecutor } from "@execbox/quickjs";
import * as z from "zod";

const upstreamServer = new McpServer({
  name: "upstream",
  version: "1.0.0",
});

upstreamServer.registerTool(
  "search-docs",
  {
    description: "Search documentation.",
    inputSchema: { query: z.string() },
    outputSchema: { hits: z.array(z.string()) },
  },
  async (args) => ({
    content: [{ text: `found ${args.query}`, type: "text" }],
    structuredContent: { hits: [args.query] },
  }),
);

const handle = await openMcpToolProvider({ server: upstreamServer });

try {
  const executor = new QuickJsExecutor();
  const result = await executor.execute(
    '(await mcp.search_docs({ query: "quickjs" })).structuredContent.hits[0]',
    [handle.provider],
  );

  if (!result.ok) {
    throw new Error(result.error.message);
  }

  console.log(result.result);
} finally {
  await handle.close();
}
```

The runtime choice is separate from the provider shape. Use inline QuickJS for trusted, lowest-friction local execution. Use worker-hosted QuickJS when you want local execution off the main thread with worker lifecycle controls. Use `@execbox/remote` when the application owns a process, container, VM, or network boundary for the runtime and wants the same execution contract across that boundary.

## Boundaries

The runtime is not the capability owner. The provider and tool surface is.

If guest code can call a tool that deletes data, sends email, or reaches a private system, then guest code has that authority. Moving execution from inline QuickJS to a worker or remote runner changes lifecycle and deployment properties, not what the exposed tools are allowed to do.

Execbox helps make that execution path controlled: fresh execution state per call, JSON-only tool and result boundaries, schema validation around host tool execution, bounded logs, timeout and memory controls, and abort propagation into in-flight host work.

Those controls matter, but they do not make a dangerous tool safe to expose. They make it easier to expose only the tools you intend, run generated code through a stable contract, and choose the runtime placement that matches the deployment.

That is the role of `execbox`: keep one capability model, support MCP tools and wrapped MCP servers, and let applications choose between inline QuickJS, worker-hosted QuickJS, and app-owned remote runner boundaries without rewriting the guest/tool contract.

If you want to look at the implementation:

- [Getting Started](https://execbox.aallam.com/getting-started)
- [Examples](https://execbox.aallam.com/examples)
- [Architecture](https://execbox.aallam.com/architecture/)
- [Security](https://execbox.aallam.com/security)
- [GitHub repository][1]

[0]: {{ site.url }}/assets/images/blog/direct_vs_code_execution.svg
[1]: https://github.com/aallam/execbox
