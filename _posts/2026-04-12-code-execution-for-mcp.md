---
title: "Code execution for MCP"
layout: post
date: 2026-04-12 12:10
description: "A technical look at why direct MCP tool calling runs into context and boundary problems, what Anthropic and Cloudflare found, and the architecture behind execbox."
mermaid: true
tag:
- JavaScript
- Node.js
- MCP
- Architecture
blog: true
jemoji:
---

There is a pattern showing up more often in agent systems: instead of asking the model to call one tool at a time, let it write code that calls tools, then run that code inside a controlled environment.

At first glance, this looks like a small implementation detail. In practice, it changes three important things:

1. how much context the model consumes,
2. how intermediate data moves through the system,
3. where the real security boundary actually lives.

This post looks at the problem, the external signals that validate it, and the architecture behind [`execbox`](https://github.com/aallam/execbox) as one concrete response.

<div class="text-center" markdown="1">
![Direct MCP tool calling versus code execution][0]{:width="90%"}
</div>

## Problem

The Model Context Protocol (MCP) made tool integration dramatically more uniform, but there is still a scaling problem once agents are connected to many tools or many servers.

In the naive setup, the client exposes tool definitions directly to the model, then runs a loop like:

1. model inspects available tools,
2. model calls one tool,
3. tool result is pushed back through the model context,
4. model decides the next tool call,
5. repeat.

This works, but it has costs:

- every exposed tool definition consumes context,
- every intermediate result flows back through the model,
- large payloads are copied multiple times,
- multi-step control flow becomes expensive and noisy,
- the boundary between "what the model can reason about" and "what the system should execute" stays blurry.

Once you connect hundreds of tools, or even a handful of tools returning large documents or datasets, the overhead is hard to ignore.

<pre class="mermaid">
flowchart LR
    M["Model"] --> T["Tool catalog in context"]
    T --> C1["Call tool A"]
    C1 --> R1["Return result to model"]
    R1 --> C2["Call tool B"]
    C2 --> R2["Return another result"]
    R2 --> M

    classDef model fill:#efe7ff,stroke:#6a3fd4,color:#20113a
    classDef catalog fill:#fff3d6,stroke:#d1a11f,color:#4f3200
    classDef tool fill:#d8f3ef,stroke:#1b8c7a,color:#0f3c36
    class M model
    class T catalog
    class C1,R1,C2,R2 tool
</pre>

## Signals

What made this pattern feel less like a personal preference and more like a real architectural direction is that Anthropic and Cloudflare both published work pointing at the same underlying issue.

Anthropic's post, [Code execution with MCP: Building more efficient agents](https://www.anthropic.com/engineering/code-execution-with-mcp), describes two core scaling problems with direct MCP tool usage:

- tool definitions overload the context window,
- intermediate tool results consume additional tokens.

Their proposed shift is straightforward: let the model write code against tool-like APIs, load definitions on demand, and keep intermediate processing inside the execution environment instead of replaying everything through the model.

Cloudflare's post, [Code Mode: give agents an entire API in 1,000 tokens](https://blog.cloudflare.com/code-mode-mcp/), makes the same argument from a different angle. They describe "Code Mode" as replacing a large tool surface with a much smaller interface where the model writes code against a typed SDK, then executes that code. For their Cloudflare API MCP server, they report a fixed footprint of around 1,000 tokens and claim a **99.9%** reduction versus a naive full-tool exposure.

Then Cloudflare followed that with [Sandboxing AI agents, 100x faster](https://blog.cloudflare.com/dynamic-workers/), which focuses on the other half of the problem: if models are going to generate code dynamically, that code has to run somewhere safe. Their point is direct and correct: you cannot just `eval()` model-generated code in the host application and call it a day. They also argue that containers are often heavier than you want for high-volume, per-task execution.

Taken together, these posts point to a useful framing:

- direct tool calling is often too expensive at scale,
- code execution is a viable way to compress planning and data movement,
- code execution only helps if the runtime boundary is explicit and controlled.

That last point matters most here.

## Constraints

Viewed through that lens, the design constraints become clearer.

If the model is going to write code that interacts with tools, then the system needs at least four properties:

1. **Explicit capability exposure**  
   The host must decide exactly which tools exist and under what names.

2. **A stable execution contract**  
   The model-facing surface should stay the same even if the runtime changes.

3. **A real boundary between host and guest**  
   Tool calls should cross a structured interface, not leak arbitrary host authority.

4. **Runtime choice**  
   Different deployments need different trade-offs: easiest setup, off-main-thread execution, child-process lifecycle separation, or an application-owned remote boundary.

This is where a lot of existing discussions stop. They establish that "code instead of direct tool calls" is useful, but they leave open a practical question:

What does the execution layer actually look like if you want to use this pattern outside one specific platform?

## Implementation

[`execbox`][1] is one answer to that question.

At a high level, it is a Node.js library for running guest JavaScript against host-defined tools and wrapped MCP servers, without hard-wiring the whole system to one runtime shape.

The core model is intentionally small:

1. host code defines tools, or discovers them from an MCP source,
2. those tools are resolved into a deterministic guest namespace,
3. guest code runs against that namespace,
4. tool calls cross a host-controlled boundary and return structured JSON-compatible results.

That provides one execution contract while still letting the deployment boundary change.

## Architecture

At a high level, the architecture is easier to think about in terms of boundaries than packages.

There are five moving parts:

1. the host application defines or discovers capabilities,
2. those capabilities are resolved into a guest-facing namespace,
3. guest code runs inside a chosen runtime,
4. tool calls cross a controlled host boundary,
5. results come back as structured data rather than arbitrary host objects.

<pre class="mermaid">
sequenceDiagram
    autonumber
    participant App as Host application
    participant NS as Resolved namespace
    participant Guest as Guest runtime
    participant Boundary as Host boundary
    participant Systems as Systems / APIs / MCP servers

    App->>NS: Define or discover capabilities
    App->>Guest: Execute code with namespace
    Guest->>Boundary: Call tool
    Boundary->>Systems: Invoke capability
    Systems-->>Boundary: Structured result
    Boundary-->>Guest: Return JSON-safe value
    Guest-->>App: Return execution result
</pre>

The main design goal is that the namespace and call contract stay stable even when the runtime changes. The same model can start in-process, move off the main thread, move into a child process, or sit behind an application-owned transport without forcing a rewrite of how capabilities are exposed.

MCP can appear on either side of that flow:

- upstream, as a source of tools that are wrapped into the guest namespace,
- downstream, as a surface that exposes code execution back out to MCP clients.

Internally, that maps to a small set of packages such as `@execbox/core`, the executor packages, and `@execbox/protocol`, but the important user-facing idea is simpler: define capabilities once, choose the runtime boundary that fits the deployment, and keep the execution contract the same.

## Usage

In TypeScript, one of the cleanest ways to express that flow is to start from an MCP server declared with the MCP SDK itself, then expose it to guest code through `execbox`.

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
    inputSchema: {
      query: z.string(),
    },
    outputSchema: {
      hits: z.array(z.string()),
    },
  },
  async (args) => ({
    content: [{ text: `found ${args.query}`, type: "text" }],
    structuredContent: {
      hits: [args.query],
    },
  }),
);

const handle = await openMcpToolProvider({ server: upstreamServer });
const executor = new QuickJsExecutor();
const result = await executor.execute(
  '(await mcp.search_docs({ query: "quickjs" })).structuredContent.hits[0]',
  [handle.provider],
);
```

This keeps the API close to the MCP TypeScript SDK itself: the server is declared once, `zod` stays the schema language, and the same server can be exposed to guest code as a callable namespace.

## Boundary

This is the most important design point in the system. The provider and tool surface is the real capability boundary.
If guest code can call a dangerous tool, guest code can exercise that authority. The runtime can make abuse harder, contain failures better, and narrow blast radius, but it does not erase the authority behind the exposed capability.

That is why `execbox` is explicit about what it does provide:

- fresh execution state per call,
- JSON-only tool and result boundaries,
- schema validation around host tool execution,
- bounded logs,
- timeout and memory controls,
- abort propagation into in-flight host work.

## Why it matters

Anthropic and Cloudflare helped validate the same broad pattern:

- code execution can be much more context-efficient than direct tool loops,
- loading only the definitions you need is a better scaling model,
- generated code needs a proper execution boundary.

What was missing in practice was a reusable layer that made those ideas portable across runtimes and MCP integration patterns instead of tying them to one agent host or one vendor platform.

That is what [`execbox`][1] is for.

If you want to look at the implementation:

- [Getting Started](https://execbox.aallam.com/getting-started)
- [Examples](https://execbox.aallam.com/examples)
- [Architecture](https://execbox.aallam.com/architecture/)
- [Security](https://execbox.aallam.com/security)
- [GitHub repository][1]

[0]: {{ site.url }}/assets/images/blog/direct_vs_code_execution.svg
[1]: https://github.com/aallam/execbox
