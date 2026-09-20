---
title: "Writing Libraries Is Writing Contracts"
layout: post
date: 2026-05-09 10:00
description: "What maintaining open source libraries teaches about API design, documentation, compatibility, dependencies, releases, and user trust."
tag:
- Libraries
- Open Source
- Software Engineering
blog: true
jemoji:
---

Writing a library starts with code, but maintaining one is mostly about contracts.

Every public function, type, default value, error message, dependency, and example becomes something users can build on. Once they do, a change can force work on people trying to keep their own systems running.

That is the part that took me time to appreciate. A library can be small, elegant, and well-tested, but the moment it has users, its shape matters beyond its implementation. The API becomes a promise. The docs become a promise. The release process becomes a promise. Even the things you choose not to expose become part of how users understand the library.

I have felt this while maintaining [`openai-kotlin`](https://github.com/aallam/openai-kotlin), smaller Kotlin libraries, and [`execbox`](https://github.com/aallam/execbox), which runs JavaScript with access to tools chosen by the host. The projects differ in size and purpose, but each has users whose code needs to keep working.

<div class="text-center" markdown="1">
![Library contracts between maintainers and users][0]{:width="90%"}
</div>

## Public API is more than types

It is tempting to think of public API as the functions, classes, interfaces, and packages a library exposes. That is only the visible part.

The real API also includes behavior:

- what happens when input is missing,
- whether calls are lazy or eager,
- which errors are thrown and when,
- whether ordering is stable,
- how cancellation works,
- how retries, timeouts, and defaults behave,
- which platforms are supported,
- which values are accepted even if the type allows more.

Users learn those details from your implementation, docs, examples, and tests. If the behavior is useful, they will depend on it. If the behavior is accidental, they may still depend on it.

This changes how you maintain the code. Within an application, you can often update an internal function and its callers together. With a library, you do not control the callers. They live in other repositories and follow other release schedules. You may only hear about them when something breaks.

The harder part is that users rarely depend on your API exactly the way you imagined. They will compose it with frameworks you do not use, run it on platforms you do not test every day, and rely on edge cases because those edge cases solve real problems for them.

That does not mean every behavior must be frozen forever. It means public behavior should be intentional. If something is not meant to be stable, do not expose it casually. If something is stable, test it like a contract.

## Keep the public API small

The easiest API to maintain is the one you did not publish.

This sounds obvious, but it is one of the most useful lessons in library design. Every public helper, option, overload, type alias, package path, and configuration hook creates future work. It may need documentation. It may need tests. It may need compatibility. It may limit a future internal design.

A small public API leaves room to improve the library without breaking users.

A library can keep plenty of code private. That code can be renamed, split, optimized, or replaced without asking users to change anything. Removing a public API is harder because someone may already depend on it.

This matters most when a project is young. You may not yet know whether users need a small building block or a complete workflow. Publishing too much too early turns guesses into promises you have to keep.

I saw this while preparing `execbox` for a stable API. Experimental runtime packages had grown around the core idea, so I removed them before 1.0. That left `@execbox/core` for the execution API and tool-provider interfaces, and `@execbox/quickjs` for running code in QuickJS. The cleanup caused some short-term disruption, but it left less for users to learn and for me to support.

Start with the smallest useful API, then add to it when real usage shows a need. When users keep working around the API, find out why. An internal option does not need to become public just because it already exists.

Small surfaces also make documentation and examples better. A library that can be explained with a few concepts is easier to adopt, easier to debug, and easier to trust.

## Docs are part of the contract

Documentation is not a decoration around the library. For many users, it is the library.

The first example teaches them what the maintainers consider normal. The getting-started page defines the happy path. The advanced guide tells them which use cases are expected. The upgrade guide tells them whether changes are predictable. Missing docs tell them where the contract is weak.

This is why examples matter so much. Users copy them. They build habits from them. If the example skips error handling, people will skip error handling. If it uses an unstable internal helper, people will use that helper. If it shows a pattern that only works in a narrow environment, users will assume the library failed when it does not work elsewhere.

Docs also help maintainers make decisions. If a behavior is hard to explain, the API may need work. If a feature needs five paragraphs of exceptions, it may be doing too much. Writing down what the library is for can help decide which features belong in it.

The best docs do not need to cover every implementation detail. They need to make a few things clear:

- what the library is for,
- what the main path looks like,
- which guarantees users can rely on,
- where the boundaries are,
- how to upgrade when those boundaries move.

Writing the docs often reveals a confusing API, a vague type name, or a feature that does not fit the rest of the library.

## Make upgrades predictable

Every breaking change asks users to spend time upgrading. Sometimes that work is worth it: a confusing API can cost more over time than a clear migration. Before 1.0, libraries especially need room to fix design mistakes.

A breaking change should solve a clear problem and come with migration notes. Keep unrelated changes out of the upgrade path, and explain why the work is worth doing.

Marking an API as deprecated gives users time to replace it before removal. The notice should answer three questions:

- what should users do instead,
- when does the old path go away,
- why is the change worth making.

For projects that follow [Semantic Versioning](https://semver.org/), version numbers help, but they are not enough. SemVer allows the public API to change during `0.y.z` and requires a major-version increase for incompatible API changes after `1.0`. Users still need to know what changed and how to update their code.

Compatibility also covers supported platforms, runtime versions, generated code, dependency versions, data formats, package names, module paths, and error behavior. These may look like internal details until users build on them.

## Dependencies become user dependencies

When users install your library, they also inherit its required runtime dependencies and the packages those dependencies need.

That does not mean libraries should have no dependencies. Good dependencies can reduce bugs, improve standards compliance, and let maintainers focus on the library's actual purpose. But dependencies carry costs that are different in a library than in an application.

An application chooses its own runtime, deployment target, bundle size, dependency policy, and upgrade schedule. A library is pulled into environments it does not control. A transitive dependency can affect build time, binary size, cold start, platform support, security reviews, licensing, and version resolution.

Ask whether the benefit is worth the cost to users. Sometimes it is. In other cases, an optional integration, a separate package, or a little more local code can spare users a dependency they do not need.

Dependencies also shape maintenance. An API client may need generated types to keep up with an API. A library supporting several platforms needs dependencies that work on those platforms. A library that runs other code needs to account for how its dependencies handle permissions, cleanup, and memory.

## Maintenance is product work

Maintaining a library includes helping people adopt, understand, upgrade, and debug it. Issues, pull requests, release notes, examples, CI, package metadata, and error messages are all part of that work.

That means choosing clear names, keeping releases small enough to understand, and sometimes turning down a feature that would make the API harder for everyone else to use.

A maintainer has to balance different kinds of pressure:

- new users want the simplest possible start,
- advanced users want ways to handle unusual cases,
- contributors want their use cases accepted,
- existing users want stability,
- the maintainer wants the codebase to remain workable.

Those goals can conflict. Decide which uses the library supports best, and make that choice clear.

For me, this is the hard part of maintaining libraries: carrying old decisions long enough for users to move, while leaving room to improve the design.

Users should know what the API does, what an upgrade asks of them, and where to look when something fails. A small API, clear docs, and well-explained releases make that possible.

Reusable code is the beginning. The real work is making it safe for other people to build on.

[0]: {{ site.url }}/assets/images/blog/library_contract.svg
