---
title: "Configuration Is a Distributed System"
layout: post
date: 2026-08-02 12:00
description: "Why production configuration is a propagation graph, how changes move from declaration to activation, and how to design delivery, rollout, validation, and observability around that fact."
mermaid: true
tag:
- Configuration
- Distributed Systems
- Kubernetes
- Reliability
blog: true
jemoji:
---

A configuration value exists in the secret manager. The synchronization controller reports success. The Kubernetes Secret contains the expected key. The web pods are healthy. A background worker still fails at startup because the value is missing.

The usual question is: *where is the configuration wrong?*

That question assumes configuration is one thing in one place. In production it is usually a piece of state copied through several systems, transformed along the way, and activated by more than one process. The value in the source of truth is only the first copy.

A more useful question is: *how far did this revision get?*

Configuration is a distributed system. It has authorities, replicas, propagation delays, schemas, consumers, version skew, partial failures, and rarely a transaction covering the whole path. Treating it as a map of keys and values hides the part that causes most operational failures: delivery.

## The source of truth is only the source

Consider a common path for an application credential:

<pre class="mermaid">
flowchart TB
    Authority["External authority"] -->|fetch| Sync["Synchronization controller"]
    Sync -->|materialize| Secret["Kubernetes Secret"]
    Template["Pod template"] -.->|references| Secret
    Secret -->|resolve when container starts| Env["Container environment"]
    Secret -->|project through kubelet| File["Mounted file"]
    Env -->|read at startup| Process["Workload process"]
    File -->|reread or reload| Process
    Process -->|validate and activate| Subsystem["Configured subsystem"]

    classDef authority fill:#fff3d6,stroke:#d1a11f,color:#4f3200
    classDef control fill:#efe7ff,stroke:#6a3fd4,color:#20113a
    classDef state fill:#e8f1ff,stroke:#2f5da8,color:#102a43
    classDef runtime fill:#d8f3ef,stroke:#1b8c7a,color:#0f3c36
    class Authority authority
    class Sync,Template control
    class Secret state
    class Env,File,Process,Subsystem runtime
</pre>

**Two delivery paths.** The pod template references the Secret but does not contain its value. Environment delivery happens when a container starts; file delivery follows kubelet projection and still requires the process to reread or reload it.

Each edge is a contract.

The controller needs the correct source path, permissions, refresh policy, target name, key mapping, and transformation. The workload manifest needs to reference the correct Secret and key. A running process cannot receive a changed environment variable; a controlled Pod rollout is the normal way to create processes with the new environment. The process must parse the value and make it available to the subsystem that uses it. Every relevant workload needs a complete path of its own.

None of those steps is implied by the previous one. A value can exist in the secret manager without being selected by the synchronization resource. A Kubernetes Secret can be current while existing Pods retain old environment variables. A mounted file can change while an application that read it once at startup continues using the previous value. A web Deployment can be wired correctly while a worker Deployment is forgotten.

Calling the secret manager the source of truth is still useful: it identifies the authority allowed to declare the desired value. It does not prove the state of any running consumer.

## Four states and an evidence plane

It helps to give each stage a name. A production configuration change moves through four lifecycle states, while an evidence plane makes every transition verifiable.

**Declared.** An owner has recorded a desired revision in the authoritative system. This might be a Git commit, a secret-manager version, a configuration-service record, or an API mutation.

**Materialized.** The desired revision has been rendered into the system-specific object from which a workload can receive it: a Kubernetes Secret or ConfigMap, a generated file, a service response, or a release artifact.

**Delivered.** The workload has access to that revision. For a container this may mean a new environment, a projected file, or a successful runtime fetch.

**Activated.** The running process has parsed, validated, and begun using the revision. Delivery and activation are different when applications cache configuration, reload asynchronously, reject invalid updates, or contain several independently configured subsystems.

**Evidence plane.** For every intended consumer, an operator can determine which revision reached each lifecycle state without exposing its value. Evidence is not another copy of configuration; it is attached to every transition.

A successful declaration is therefore only the start of a change, not evidence that it reached runtime.

This vocabulary also narrows incidents quickly. "The Secret is correct" establishes materialization. It says nothing about delivery or activation. "The rollout finished" establishes that Pods were replaced. It does not prove the process accepted the intended revision. A healthy endpoint may prove the process can serve traffic, but unless health includes the relevant configuration invariant, it may not prove activation either.

## Presence is not propagation

Kubernetes makes the distinction concrete. A ConfigMap projected as a normal volume is eventually updated by the kubelet, subject to its synchronization and cache propagation delays. The application uses the new value only if it rereads or reloads the file; one that reads only at startup continues using its previous in-memory state. A `subPath` mount is an important exception because it does not receive ConfigMap updates. A running process never observes later ConfigMap changes through its environment; an intentional Pod replacement is the documented mechanism for rolling out the new value. Without one, ordinary scaling can leave a service running a mixture of old and new values. Container recreation can introduce an even narrower form of skew because the kubelet resolves referenced values when it creates each container.

Secret synchronization adds another independent clock. The External Secrets Operator, for example, supports `CreatedOnce`, `Periodic`, and `OnChange` refresh policies. `Periodic` rereads the external provider on an interval. `OnChange` reacts to changes in the `ExternalSecret` resource rather than provider-side rotation. `CreatedOnce` normally creates the target once, but reconciles it again if the target Secret is deleted or altered; recreating the `ExternalSecret` also begins a new lifecycle. "The controller is installed" therefore tells us very little about when a particular change should materialize.

The wider lesson is not specific to Kubernetes: every edge in the graph has a propagation policy. It might be push-based, polled, rollout-bound, startup-only, manually triggered, or immutable. If that policy is left implicit, operators will invent one in their heads, and their models will disagree during an incident.

A useful configuration specification answers four questions for every edge:

- What event starts propagation?
- What is the expected delay?
- How is failure surfaced and retried?
- What evidence proves the next stage accepted the revision?

Without those answers, eventual consistency becomes "probably updated by now."

## The consumer set is larger than it looks

Teams usually wire configuration into the workload that uses the feature. That sounds precise and least-privileged. It can still be incomplete.

Suppose the web process uses `EVENT_SIGNING_KEY`, while a worker never signs an event. If both processes boot through one configuration schema that marks the key as globally required, the worker is also a consumer of that configuration for startup purposes. It can fail before reaching any feature-specific code.

This creates an architectural choice.

One option is to deliver the value to every workload that runs the global validator. That restores the runtime invariant, but it widens secret distribution. Another is to split configuration schemas by process role so that each workload validates only what it can use. That preserves least privilege, but introduces more schemas and makes shared startup paths less uniform. A third is conditional validation: keep a shared schema, but require a field only when the relevant capability is enabled, then assert the invariant again at the feature boundary. This limits distribution while keeping common parsing, at the cost of a more stateful contract.

None of these choices is universally correct. The mistake is using one definition of *consumer* in application code and another in deployment configuration.

For delivery purposes, the consumer set includes every workload that either uses the value or requires it to start. That includes web processes, workers, scheduled jobs, migration hooks, administrative commands, and sometimes sidecars. Short-lived jobs are easy to miss because they may not exist when the change is inspected, yet the next deployment can create them with stale wiring.

The invariant is simple:

> For every workload that consumes or startup-validates a configuration field, there must be a complete delivery path from its declared source to activation in that workload.

This is a graph property, not a check that a key appears somewhere in a repository.

## Version skew is normal

A rolling deployment intentionally runs old and new Pods at the same time. Kubernetes controls the overlap through `maxUnavailable` and `maxSurge`; it does not provide an instant fleet-wide transition. Configuration changes therefore need a compatibility story just as binary changes do.

The dangerous case is a coupled change:

- the old binary accepts configuration schema `v1`;
- the new binary requires schema `v2`;
- the configuration is stored and rolled out independently.

Publishing `v2` first can break old instances. Deploying the binary first can break new instances that still receive `v1`. A rolling update creates an overlap in which incompatible binary/configuration combinations are possible unless the release process or delivery mechanism prevents them.

The usual solution is an expand-and-contract sequence:

1. Deploy code that accepts both the old and new configuration shapes.
2. Verify that the compatible binary is active everywhere that matters.
3. Publish the new configuration revision gradually.
4. Verify activation across the fleet.
5. Remove support for the old shape in a later release.

Credential rotation is the same problem with an external participant. If a producer begins signing with a new key before consumers can verify it, or a database password changes before connection pools receive it, rollback may not be as simple as restoring a file. Safe rotation often needs an overlap period in which both revisions are accepted, followed by evidence that the old revision is no longer in use.

This is why configuration deserves versioning. A version is not only history in Git. It is an identity that can travel through the graph and let us compare desired, materialized, delivered, and activated state.

## Validate at the boundary that owns the failure

"Fail fast" is good advice until every layer fails for the same reason and nobody can tell which boundary was broken.

Validation should be layered.

**Before deployment**, validate syntax, schema, generated manifests, references, and the expected consumer set. These checks catch structural errors without needing production credentials.

**During reconciliation**, report whether the desired source was fetched and the target object was produced. A controller condition should distinguish missing permissions, missing source data, transformation errors, and an intentionally non-refreshing policy.

**At process startup**, validate required presence, parsing, ranges, mutually dependent fields, and invariants the application can determine locally. A process should not advertise readiness if it cannot serve correctly with its activated configuration. Readiness should answer whether this replica can serve safely now, not whether the fleet has converged on the desired revision.

**During runtime reload**, build and validate a complete candidate before swapping it into use. Updating fields one at a time exposes combinations that never existed in any declared revision. If a candidate is invalid, continuing with the last-known-good revision is often safer than partially activating it.

That last rule has limits. Continuing with an expired or revoked credential may be unsafe, and retaining configuration indefinitely can hide a broken control plane. Last-known-good behavior therefore needs an expiry policy and an explicit degraded state, not silent immortality.

Validation also needs semantic checks. A value can be present, correctly typed, and operationally disastrous. A timeout of `0` may parse as an integer but disable a safety boundary. A percentage of `100` may be valid syntax but turn a gradual rollout into a global change. The component that understands the meaning should own those invariants.

## Observe revisions, not values

During an incident, an operator should be able to answer:

- What revision is desired?
- What revision did the synchronization layer materialize?
- What revision did each workload activate?
- When did each transition happen?
- Which consumers are missing, stale, or rejecting the revision?

Secrets and other sensitive configuration values should not appear in logs or metrics. Bounded, explicitly non-sensitive effective settings can be useful for diagnosis, but should be selected deliberately rather than dumped wholesale. Hashing is not automatically safe either: hashes of low-entropy configuration can be guessed, and a unique revision label attached to every metric series creates unbounded cardinality.

A better design carries an opaque revision identifier alongside the value. Prefer an identifier assigned by the authority; if a process must derive one, use a keyed digest rather than a bare hash of the configuration. Controllers can record it in status or metadata. Processes can emit it once in a structured startup or reload event and expose it through an authenticated, authorized, and bounded diagnostic inventory. Fleet-level monitoring can then report counts such as "27 of 30 consumers activated the desired revision" and the age of the oldest stale consumer without turning every revision into a permanent time series.

Health and configuration state should also remain distinct. A service may be healthy on its last-known-good revision while configuration convergence is degraded. Collapsing both into one boolean either removes a healthy instance unnecessarily or hides propagation failure. Report service readiness, configuration activation, and convergence separately, then decide which conditions should block rollout.

## Roll out configuration like code

Configuration can change behavior without changing a binary, which sometimes makes it more dangerous than code. It often receives less testing precisely because it looks smaller.

Google's SRE guidance for safe configuration changes identifies three useful properties: gradual deployment, rollback, and automatic rollback—or at minimum stopping rollout progress—before a failure removes operator control. Those requirements follow naturally from the distributed-system model.

Gradual rollout limits the number of consumers on a bad revision. A pause between stages creates time to inspect both application outcomes and convergence. Rollback requires preserving the previous revision and knowing whether reversing configuration is sufficient; external state changes may require a forward repair instead. Automatic stopping requires signals tied to the effect of the configuration, not only confirmation that distribution succeeded.

The release unit matters too. If a configuration revision is meaningful only with one binary version, deploy them as one tested artifact or encode their compatibility explicitly. If configuration must remain independently changeable, design overlapping compatibility windows. Independence in the delivery machinery does not create independence in semantics.

## Test the graph

Most configuration tests focus on the endpoints. A schema test proves the application can parse an example. A deployment test proves a Secret exists. The failure-prone part is the path between them.

Useful tests cover the edges:

- the declared source key maps to the intended materialized key;
- every workload in the consumer inventory references the right object;
- generated manifests preserve the reference in every environment;
- startup validation accepts the deployed shape;
- old and new binary/configuration combinations behave as planned;
- rotation, reload, rollback, and last-known-good paths work;
- short-lived jobs and hooks receive the same contract as long-running services;
- observability reports the activated revision without exposing data.

Not all of these tests need a cluster. Rendering manifests and comparing them with a declared consumer inventory catches many omissions deterministically. Contract tests can use non-secret placeholders to exercise mappings and parsers. A small integration environment can then verify reconciliation, Pod replacement, reload behavior, and convergence.

The goal is not to reproduce production in CI. It is to prove that every edge has an owner and at least one test at the cheapest layer capable of finding its failures.

## Configuration is deployed state

Configuration is often described as code, which usefully brings review and version control to it. But code in a repository is not running software, and configuration in its authority is not activated state.

Configuration is a propagation graph, and its lifecycle spine is:

<pre class="mermaid">
flowchart LR
    Declared["Declared"] --> Materialized["Materialized"]
    Materialized --> Delivered["Delivered"]
    Delivered --> Activated["Activated"]
    Declared -.-> Evidence["Evidence plane"]
    Materialized -.-> Evidence
    Delivered -.-> Evidence
    Activated -.-> Evidence

    classDef lifecycle fill:#efe7ff,stroke:#6a3fd4,color:#20113a
    classDef evidence fill:#d8f3ef,stroke:#1b8c7a,color:#0f3c36
    class Declared,Materialized,Delivered,Activated lifecycle
    class Evidence evidence
</pre>

**The configuration lifecycle.** Solid arrows move a revision toward runtime activation; dotted arrows record the evidence needed to prove where it reached. Real systems fan out into many materializations and consumers around this spine.

Every arrow can delay, retry, transform, reject, or silently retain an older revision. Every fan-out can reach some consumers and miss others. Most rolling or staged rollouts create a period of version skew. Every rollback depends on whether the old world still exists outside the configuration system.

Once those properties are explicit, configuration incidents become less mysterious. Instead of asking whether the value exists, ask which revision each stage holds. Instead of checking one workload, enumerate the consumers. Instead of assuming a rollout makes change atomic, design compatibility for the overlap. Instead of logging secrets, propagate revision identity.

A configuration change is finished when all intended consumers have activated the intended revision and the system can prove it. Everything before that is propagation in progress.

## References

- [Updating Configuration via a ConfigMap — Kubernetes](https://kubernetes.io/docs/tutorials/configuration/updating-configuration-via-a-configmap/)
- [Deployments — Kubernetes](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [ExternalSecret API — External Secrets Operator](https://external-secrets.io/latest/api/externalsecret/)
- [Configuration Design and Best Practices — Google SRE Workbook](https://sre.google/workbook/configuration-design/)
