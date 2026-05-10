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

Every public function, type, default value, error message, dependency, and example becomes something users can build on. Once they do, changing it is no longer a private refactor. It is a negotiation with people who are trying to keep their own systems working.

That is the part that took me time to appreciate. A library can be small, elegant, and well-tested, but the moment it has users, its shape matters beyond its implementation. The API becomes a promise. The docs become a promise. The release process becomes a promise. Even the things you choose not to expose become part of how users understand the library.

I have felt this across different kinds of projects: a larger API client such as [`openai-kotlin`](https://github.com/aallam/openai-kotlin), smaller focused Kotlin libraries, and newer runtime-boundary work like [`execbox`](https://github.com/aallam/execbox). The details are different, but the maintenance pressure is the same: once people depend on your library, you are not only publishing code. You are publishing expectations.

<div class="text-center" markdown="1">
![Library contracts between maintainers and users][0]{:width="90%"}
</div>

## Public API is more than types

It is tempting to think of public API as the list of exported symbols. Functions, classes, interfaces, modules, packages. That is only the visible part.

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

This is why library code needs a different level of care than application code. In an application, an internal function can be fixed when its caller changes. In a library, you do not control the callers. They live in other repositories, other companies, other release cycles, and sometimes other time zones. You only see them when an issue appears.

The harder part is that users rarely depend on your API exactly the way you imagined. They will compose it with frameworks you do not use, run it on platforms you do not test every day, and rely on edge cases because those edge cases solve real problems for them.

That does not mean every behavior must be frozen forever. It means public behavior should be intentional. If something is not meant to be stable, do not expose it casually. If something is stable, test it like a contract.

## Small surfaces survive

The easiest API to maintain is the one you did not publish.

This sounds obvious, but it is one of the most useful lessons in library design. Every public helper, option, overload, type alias, package path, and configuration hook creates future work. It may need documentation. It may need tests. It may need compatibility. It may limit a future internal design.

Small public surfaces are not about minimalism for its own sake. They are about preserving room to improve the library without breaking users.

A good library usually has more internal machinery than public API. That is fine. Internals can be ugly for a while. They can be renamed, split, optimized, generated, deleted, or replaced. Public API has a different cost model. Once it exists, removal is expensive.

This is especially important when a project is young. Early versions are full of uncertainty. You may not know the right abstractions yet. You may not know whether users need a low-level primitive or a higher-level workflow. Publishing too much too early turns guesses into obligations.

The better default is to expose the smallest useful path, then let real usage pull more surface area out of the internals. When a pattern repeats, promote it. When users keep reaching around the API, understand why. When an option exists only because the implementation happened to have it, keep it private.

Small surfaces also make documentation and examples better. A library that can be explained with a few concepts is easier to adopt, easier to debug, and easier to trust.

## Docs are part of the contract

Documentation is not a decoration around the library. For many users, it is the library.

The first example teaches them what the maintainers consider normal. The getting-started page defines the happy path. The advanced guide tells them which use cases are expected. The upgrade guide tells them whether changes are predictable. Missing docs tell them where the contract is weak.

This is why examples matter so much. Users copy them. They build habits from them. If the example skips error handling, people will skip error handling. If it uses an unstable internal helper, people will use that helper. If it shows a pattern that only works in a narrow environment, users will assume the library failed when it does not work elsewhere.

Docs also help maintainers make decisions. If a behavior cannot be explained clearly, the API may be wrong. If a feature needs five paragraphs of caveats, it may be too complex, too early, or sitting at the wrong abstraction level. If the docs keep saying what the library does not do, the project may not have a clear enough positive shape yet.

The best docs do not need to cover every implementation detail. They need to make the contract legible:

- what the library is for,
- what the main path looks like,
- which guarantees users can rely on,
- where the boundaries are,
- how to upgrade when those boundaries move.

In practice, docs and design feed each other. Writing the docs often exposes where the API is too clever, where a type name is vague, or where a feature has no obvious place in the mental model.

## Compatibility is a budget

Compatibility is not binary. It is a budget you spend.

Every breaking change spends user trust. Sometimes that spend is worth it. Bad APIs should not live forever just because they were published once. A confusing abstraction can cost users more over time than a well-explained migration. Pre-1.0 libraries especially need room to correct their shape before stability hardens the wrong design.

But breaking changes should be honest. They should solve a real problem, not clean up maintainer discomfort. They should come with migration notes. They should avoid surprising users with unrelated churn. They should be grouped carefully instead of scattered across releases without a story.

Deprecation is useful when it gives users time to move. It is less useful when it becomes a permanent museum of old ideas. A deprecation should answer three questions:

- what should users do instead,
- when does the old path go away,
- why is the change worth making.

Semantic versioning helps here, but it is not enough by itself. A version number can tell users that a release may break them. It cannot tell them whether the change is understandable, whether the migration is realistic, or whether the maintainers respect their time.

Compatibility also includes softer promises: supported platforms, runtime versions, generated code shape, dependency ranges, serialization formats, package names, module paths, and error semantics. These are easy to treat as implementation details until users build on them.

The maintainer's job is not to avoid all change. It is to make change predictable.

## Dependencies become user dependencies

Every dependency you add to a library becomes part of someone else's application.

That does not mean libraries should have no dependencies. Good dependencies can reduce bugs, improve standards compliance, and let maintainers focus on the library's actual purpose. But dependencies carry costs that are different in a library than in an application.

An application chooses its own runtime, deployment target, bundle size, dependency policy, and upgrade schedule. A library is pulled into environments it does not control. A transitive dependency can affect build time, binary size, cold start, platform support, security reviews, licensing, and version resolution.

The question is not "can this dependency help?" The question is "is this dependency part of the contract I want users to inherit?"

Sometimes the answer is yes. Sometimes the answer is no. Sometimes the right design is to keep an integration optional, put it behind a separate package, or accept a little more local code to avoid forcing a large dependency onto every user.

Dependencies also shape maintenance. If your library wraps a fast-moving API, generated models or protocol clients may be necessary. If your library targets multiple platforms, dependency choices can decide which platforms remain possible. If your library sits close to runtime boundaries, dependency behavior can leak into security, lifecycle, or performance expectations.

The dependency tree is not invisible. Users will feel it.

## Maintenance is product work

Maintaining a library is product work under technical constraints.

The product is not a UI. It is the experience of adopting, understanding, upgrading, debugging, and trusting the library. Issues, pull requests, release notes, examples, CI, package metadata, and error messages are all part of that experience.

This is where taste matters, but not in the vague sense. Taste is choosing boring names when clever names would be memorable. It is saying no to an option that would make one user happy but weaken the model for everyone. It is keeping a release small enough that users can understand it. It is accepting that a missing feature is sometimes better than a feature with the wrong contract.

A maintainer has to balance different kinds of pressure:

- new users want the simplest possible start,
- advanced users want escape hatches,
- contributors want their use cases accepted,
- existing users want stability,
- the maintainer wants the codebase to remain workable.

Those goals conflict. A healthy library does not satisfy all of them equally. It chooses a center of gravity and makes that choice visible.

For me, this is the main difference between writing code and writing libraries. Code can be correct in isolation. A library has to be correct in relation to users. It has to age. It has to carry old decisions until they can be changed responsibly. It has to leave enough space for future maintenance.

## The quiet goal

The quiet goal of a library is predictability.

Users should be able to predict how the API behaves. They should be able to predict whether an upgrade is risky. They should be able to predict where to look when something fails. They should be able to predict whether a feature belongs in the library or outside it.

That predictability does not happen by accident. It comes from treating the public surface as a contract, keeping that contract small, documenting it clearly, changing it deliberately, and remembering that every dependency and release is part of the user's system too.

Reusable code is the beginning. The real work is making it safe for other people to build on.

[0]: {{ site.url }}/assets/images/blog/library_contract.svg
