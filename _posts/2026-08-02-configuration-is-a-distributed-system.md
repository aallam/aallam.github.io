---
title: "The Secret Exists. The Worker Still Fails."
layout: post
date: 2026-08-02 12:00
description: "A worked example of a Kubernetes worker that fails despite a valid Secret: follow the value, find the startup check, and fix the right process."
permalink: /configuration-is-a-distributed-system/
mermaid: true
tag:
- Configuration
- Kubernetes
- Reliability
blog: true
unlisted: true
noindex: true
jemoji:
---

Suppose an application runs as a web service and a background worker. Both use the same container image, with different startup commands. A new release lets the web service sign outgoing events using `EVENT_SIGNING_KEY`.

The value is saved in a secret manager and copied into a Kubernetes Secret. The web service starts and signs events successfully. The worker keeps restarting:

```text
Missing required configuration: EVENT_SIGNING_KEY
```

The Secret exists. The key exists. The new image works in the web Pods. Repeating those checks will keep producing reassuring answers while the worker stays down.

This example has two separate problems to investigate: how the process gets the value, and why it requires that value at all.

## Start with the failed process

First, check whether the container started. In this example, the error comes from the application's startup code: the worker ran, checked its configuration, and exited.

That is a different failure from Kubernetes being unable to supply a required Secret or key. With a required `secretKeyRef`, a missing Secret or key prevents the container from starting. The [Kubernetes Secret docs](https://kubernetes.io/docs/concepts/configuration/secret/#optional-secrets) describe this distinction.

For a restarting worker, inspect the previous container's logs and the failed Pod's settings. Do not rely only on the latest Deployment template: the failed Pod may belong to an older rollout. There is no need to get a shell inside the crashing container to inspect its Secret references.

Taken by itself, the startup error tells us that this run did not get a usable `EVENT_SIGNING_KEY`. It does not tell us whether the value is absent at the source, missing from the Pod setup, or empty.

## Follow the value into each process

The web container has this entry under `env`:

```yaml
env:
  - name: EVENT_SIGNING_KEY
    valueFrom:
      secretKeyRef:
        name: event-signing
        key: signing-key
```

The worker container has no such entry. In this example, there is no `envFrom`, mounted Secret, or runtime fetch supplying the key either. The image does not contain it. Both workloads and the Secret are in the same namespace.

Sharing an image does not give the two containers the same environment. Each Pod's setup decides what it receives.

<pre class="mermaid">
flowchart TB
    Source["Secret manager"] -->|sync| Secret["Kubernetes Secret"]
    Secret -->|web container reference| Web["Web receives key"]
    Web -->|startup check passes| Ready["Web signs events"]
    Worker["Worker has no key reference"] -->|shared startup check fails| Failed["Worker exits"]

    classDef stored fill:#e8f1ff,stroke:#2f5da8,color:#102a43
    classDef working fill:#d8f3ef,stroke:#1b8c7a,color:#0f3c36
    classDef broken fill:#fff0eb,stroke:#c45b3b,color:#552615
    class Source,Secret stored
    class Web,Ready working
    class Worker,Failed broken
</pre>

**The same image, different settings.** Blue shows the stored value, green the working web path, and red the worker failure. There is no reference connecting the worker to the Secret.

Four checks separate what exists from what a process can use:

| Stage | What we check in this example | What we learn |
| --- | --- | --- |
| Declared | The intended value is saved at the source. | The source has it. |
| Prepared | The target Secret has the expected key in the workload's namespace. | Synchronization produced the key. |
| Delivered | The actual Pod supplies the variable to the right container. | The web container has a reference; the worker does not. |
| Activated | Startup checks pass and the relevant work succeeds. | The web service signs events; the worker exits. |

Inspect key names, references, and startup results without printing secret values. A key name alone does not prove its value is correct, and a Pod reference alone does not prove the application accepted it. Here, the working web path and the worker's missing reference give us enough evidence to investigate the startup check next.

## Find out why the worker needs it

The shared startup code contains this check:

```js
const signingKey = process.env.EVENT_SIGNING_KEY;
if (!signingKey) {
  throw new Error("Missing required configuration: EVENT_SIGNING_KEY");
}
```

Both startup commands run it before choosing which work to do. The web service needs the key to sign events. The worker does not sign events, but the shared check makes the key a condition for starting any process.

This is the missing link in the investigation. The deployment gives the secret only to the process that uses it. The application requires it everywhere. Those two decisions disagree.

Adding the environment entry to the worker would make startup pass. It would also give the worker a secret it has no use for. For this application, the better fix is to make the startup check match the process role.

## Fix the requirement, then prove the fix

A small version of that change looks like this:

```js
function loadConfig(role, env) {
  if (role === "worker") return {};
  if (role !== "web") throw new Error(`Unknown process role: ${role}`);

  const signingKey = env.EVENT_SIGNING_KEY;
  if (!signingKey) {
    throw new Error("Missing required configuration: EVENT_SIGNING_KEY");
  }
  return { signingKey };
}
```

Here, `web.js` calls `loadConfig("web", process.env)`, and `worker.js` calls `loadConfig("worker", process.env)`. Each entry point uses the returned configuration. This example checks only the signing key; a real worker must still check its own required settings.

The web service keeps its startup check. The worker stops requiring an unrelated secret. Unknown roles still fail, so a typo cannot silently skip validation.

Check the expected behavior and an unknown role, using a dummy key:

```js
import assert from "node:assert/strict";

assert.deepEqual(loadConfig("worker", {}), {});
assert.throws(() => loadConfig("web", {}), /EVENT_SIGNING_KEY/);
assert.deepEqual(loadConfig("web", { EVENT_SIGNING_KEY: "test-only" }), {
  signingKey: "test-only",
});
assert.throws(() => loadConfig("wroker", {}), /Unknown process role/);
```

Then check the real entry points in a test environment. Start the worker without the signing key and have it complete a harmless job. Start the web service without the key and confirm it fails. Supply a test key and verify a signed event with the matching verifier. A unit test of `loadConfig` alone would miss an entry point that still calls the old shared check.

If the worker actually signed events, the fix would be different: give it the correct Secret reference and keep the requirement. The decision comes from what the process does.

## A restart only helps after the setup is right

Restarting the original worker cannot add a missing environment entry or remove an incorrect startup check. Deploy the corrected code first.

There is a related case where the reference is correct but the Secret value changes later. A running container's environment does not update with it, and editing the Secret alone does not trigger a Deployment rollout. Plan a rollout for workloads that need the new value. Otherwise, containers started later can receive a different value from those already running. Kubernetes documents this [environment-variable update behavior](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data).

After either kind of change, check the affected process and its work. A healthy web service says little about a worker using a different startup path.

## A short checklist for the next failure

- Did the container fail to start, or did the application start and reject its configuration?
- Does the expected Secret key exist in the workload's namespace?
- Does the actual Pod supply it to the right container?
- Does that process use the value, or only require it because of a shared check?
- After the fix, can the affected process do its job, and do the necessary startup checks still fail when they should?

The useful stopping point is a working process with the settings it needs. Finding the value in the secret manager is only the first check.
