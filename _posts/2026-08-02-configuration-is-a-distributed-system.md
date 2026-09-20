---
title: "Configuration Is a Distributed System"
layout: post
date: 2026-08-02 12:00
description: "How configuration moves from its source to running processes, where updates get stuck, and how to check that every workload uses the right version."
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

That question assumes configuration is one thing in one place. In production, it is usually copied through several systems before a running process can use it. The value in the source of truth is only the first copy.

A more useful question is: *how far did this revision get?*

Configuration is a distributed system. Copies can fall behind, updates can reach some processes and miss others, and old and new versions often run together. Treating configuration as a map of keys and values misses a large part of the work: getting the right values into every process that needs them.

## The source of truth is only the source

Consider a common path for an application credential:

<pre class="mermaid">
flowchart TB
    Authority["Secret manager"] -->|fetch| Sync["Sync controller"]
    Sync -->|write| Secret["Kubernetes Secret"]
    Template["Pod template"] -.->|references| Secret
    Secret -->|resolve when container starts| Env["Container environment"]
    Secret -->|mount through kubelet| File["Mounted file"]
    Env -->|read at startup| Process["Workload process"]
    File -->|reread or reload| Process
    Process -->|check and use| Subsystem["Application feature"]

    classDef authority fill:#fff3d6,stroke:#d1a11f,color:#4f3200
    classDef control fill:#efe7ff,stroke:#6a3fd4,color:#20113a
    classDef state fill:#e8f1ff,stroke:#2f5da8,color:#102a43
    classDef runtime fill:#d8f3ef,stroke:#1b8c7a,color:#0f3c36
    class Authority authority
    class Sync,Template control
    class Secret state
    class Env,File,Process,Subsystem runtime
</pre>

**Two delivery paths.** The Pod template names the Secret and key to use. Kubernetes supplies the value when the container starts or mounts it as a file. A file update still needs the process to reread it. Yellow marks the source, purple the controller and Pod template, blue the stored copy, and green the running application.

Each arrow is a step that can fail.

The controller needs the correct source path, permissions, refresh policy, target name, and key mapping. The workload manifest needs to reference the correct Secret and key. Updating the Secret does not update a running container's environment; a Pod rollout creates processes with the new values. The application must then parse and use them.

None of those steps is implied by the previous one. A value can exist in the secret manager without being selected by the synchronization resource. A Kubernetes Secret can be current while existing Pods retain old environment variables. A mounted file can change while an application that read it once at startup continues using the previous value. A web Deployment can be wired correctly while a worker Deployment is forgotten.

The secret manager is still the source of truth: it holds the value we want to use. Checking it tells us nothing about the value a running process is using.

## Four stages to check

It helps to give each stage a name. For each revision, or version of the configuration, ask how far it has reached:

**Declared.** An owner has saved the desired version at the source: in Git, a secret manager, or a configuration service.

**Prepared.** That version has been turned into something the workload can receive: a Kubernetes Secret or ConfigMap, a generated file, or a service response.

**Delivered.** The workload has access to that version through its environment, a mounted file, or a runtime fetch.

**Activated.** The process has checked the version and started using it. Delivery alone is not enough: an application may cache the old value, delay a reload, or reject an invalid update.

Each stage needs evidence. Logs, status fields, or a diagnostic endpoint should show which revision reached it, without exposing secret values. This is a way to check the four stages, not a fifth stage.

These names help narrow down a failure. "The Secret is correct" means preparation worked. "The rollout finished" means the new Pods became available. Neither proves the application accepted the intended revision. A health check may show that a process can serve requests while it still uses an older, valid configuration.

## Updates need a trigger

Kubernetes makes this concrete. The kubelet eventually updates files in a normal ConfigMap volume. The application must reread them to use the new values. A `subPath` mount does not receive these updates. An immutable ConfigMap cannot be updated in place; create a replacement and update the workload to use it.

Environment variables need a different path. Updating a ConfigMap or Secret does not trigger a Deployment rollout by itself. You need to replace the Pods, for example through a rollout restart or a new versioned ConfigMap name in the Pod template. Without a planned rollout, containers started later during scaling or restarts can receive the new value while existing ones keep the old value.

The External Secrets Operator sets its update rule with `spec.refreshPolicy`:

- `Periodic` checks the provider at the configured interval. With `refreshInterval: 0`, it creates the Secret once without periodic updates.
- `OnChange` responds to changes in the `ExternalSecret` resource, not to a password changing at the provider.
- `CreatedOnce` normally syncs once. It can sync again if the target Secret is changed or deleted, or if the `ExternalSecret` is recreated.

Every step has an update rule. Some poll, some wait for a rollout, and some run only at startup. Write those rules down so operators do not have to guess during an incident.

A useful configuration guide answers four questions for every step:

- What starts the update?
- What is the expected delay?
- How is failure reported and retried?
- What evidence proves the next stage accepted the revision?

Without those answers, eventual consistency becomes "probably updated by now."

## Find every process that needs the value

Teams usually give a secret only to the workload that uses it. That limits access, but shared startup checks can make the choice harder.

Return to the worker from the opening example. Suppose the web process uses `EVENT_SIGNING_KEY`, while the worker never signs an event. If both use a startup check that requires the key, the worker needs it just to start. It can fail before running any of its own code.

There are three ways to handle this:

- Give the value to every workload that runs the shared check. This fixes startup, but gives more processes access to the secret.
- Use separate checks for web processes and workers. Each role requires only its own settings, but there are more checks to maintain.
- Require the key only when signing is enabled, and check it again before signing. This keeps shared parsing, but the checks must account for which features are enabled.

The right choice depends on the application. Its startup checks and deployment setup need to agree about which processes need the value.

Check web processes, workers, scheduled jobs, migration hooks, administrative commands, and sidecars. Short-lived jobs are easy to miss: they may not exist when you inspect the change, but the next deployment can start them with an outdated setup.

> [!IMPORTANT]
> Every workload that uses a value, or requires it to start, needs a complete path from the source to the running process.

## Old and new versions run together

A rolling deployment usually runs old and new Pods at the same time. Kubernetes controls that overlap through `maxUnavailable` and `maxSurge`. Configuration changes need to work during this overlap, just as code changes do.

Consider a change where:

- the old code accepts configuration format `v1`;
- the new code requires format `v2`;
- the configuration is stored and rolled out independently.

Publishing `v2` first can break old instances. Deploying the code first can break new instances that still receive `v1`. The release process needs to prevent those incompatible combinations.

A common approach is to make the change in stages:

1. Deploy code that accepts both the old and new configuration shapes.
2. Check that all affected workloads run that code.
3. Publish the new configuration revision gradually.
4. Check that all intended workloads are using it.
5. Remove support for the old shape in a later release.

Credential rotation adds another system to the change. If a service signs with a new key before receivers can verify it, requests fail. If a database password changes before clients receive it, new connections fail. Safe rotation often needs a period when both credentials work, followed by a check that nobody still uses the old one. If the old credential was revoked, restoring a configuration file will not bring it back.

Give each configuration version an ID that follows it from the source to the process. That lets you compare what was requested with what is actually in use.

## Check each stage

Checks are most useful when they tell you where the change failed.

**Before deployment**, check syntax, accepted fields, generated manifests, Secret references, and the list of workloads. These checks catch setup errors without needing production credentials.

**During synchronization**, report whether the controller fetched the source and wrote the target. Its status should distinguish missing permissions, missing data, conversion errors, and a policy that does not refresh automatically.

**At startup**, check required values, types, ranges, and settings that depend on each other. Mark the process ready only if it can serve safely with its current configuration. Readiness is about this process; a separate check should show whether all processes have reached the desired revision.

**During reload**, check the complete new configuration before switching to it. Updating fields one at a time can create a mix of old and new settings that nobody tested. If the update is invalid, keeping the previous working version is often safer.

Keeping the previous version has limits. It may contain an expired or revoked credential. It can also hide an update that has been stuck for days. Decide how long old settings remain acceptable and report rejected updates clearly.

Check meaning as well as format. A timeout of `0` may be a valid integer but disable the timeout. A percentage of `100` may pass parsing but turn a gradual rollout into a change for everyone. The code that uses the setting should check these rules.

## Observe revisions, not values

During an incident, an operator should be able to answer:

- What revision is desired?
- What revision did the sync controller write?
- What revision did each workload activate?
- When did each transition happen?
- Which consumers are missing, stale, or rejecting the revision?

Keep secrets out of logs and metrics. A few carefully chosen, non-sensitive settings can help with debugging; dumping the entire configuration cannot. A plain hash is not always safe either: someone can guess a predictable value and compare its hash. Adding a new revision label to every metric also creates more time series with every update.

A better design carries a revision ID alongside the value. Use an ID assigned by the source, and deliver it with the values it describes. A process should report that ID only after it has accepted those values. If you must derive an ID from secret data, use a keyed hash such as HMAC and keep its key private.

Controllers can record the ID in status fields. Processes can log it at startup or reload and expose it through a diagnostic endpoint with access checks. Monitoring can then report "27 of 30 consumers use the desired revision" and how long the others have been behind, without adding every revision to every metric.

A service may still serve safely with the previous version while an update is stuck. Report both facts. One health flag cannot tell an operator whether to stop a rollout, retry delivery, or remove a process from service.

## Roll out configuration like code

Configuration can change behavior without a code release. It deserves testing and a rollout plan even when the diff is only one line.

Google's SRE guidance calls for gradual deployment, rollback, and automatic rollback or at least a way to stop progress if the change causes operators to lose control.

Start with a small group of workloads, then check both their behavior and the version they use before continuing. Keep the previous version available. Check whether reverting it is enough: a changed database or revoked credential may need another repair. Stop automatically when application errors rise, even if delivery itself succeeded.

If a configuration only works with one code version, test and release them together, or record which combinations are supported. If they must change separately, make sure old and new versions can work together during the rollout.

## Test the delivery path

Most configuration tests focus on the endpoints. A schema test proves the application can parse an example. A deployment test proves a Secret exists. The failure-prone part is the path between them.

Useful tests check that:

- the source key maps to the intended Secret or ConfigMap key;
- every workload on the list references the right object;
- generated manifests preserve the reference in every environment;
- startup checks accept the deployed format;
- old and new code/configuration combinations work as planned;
- rotation, reload, rollback, and fallback to the previous version work;
- short-lived jobs and hooks receive their required settings;
- logs and diagnostics report the active revision without exposing secrets.

Not all of these tests need a cluster. Render the manifests and compare them with the workload list to catch missing references. Use placeholder values to test key mappings and parsing. A small test environment can then check synchronization, Pod replacement, and reloads.

Give each step an owner and test it where failures are easiest to catch.

## Configuration is deployed state

Review and version control help us manage configuration at the source. We still need to follow it into the running application:

<pre class="mermaid">
flowchart LR
    Declared["Declared"] --> Prepared["Prepared"]
    Prepared --> Delivered["Delivered"]
    Delivered --> Activated["Activated"]
    Declared -.-> Evidence["Check each stage"]
    Prepared -.-> Evidence
    Delivered -.-> Evidence
    Activated -.-> Evidence

    classDef lifecycle fill:#efe7ff,stroke:#6a3fd4,color:#20113a
    classDef evidence fill:#d8f3ef,stroke:#1b8c7a,color:#0f3c36
    class Declared,Prepared,Delivered,Activated lifecycle
    class Evidence evidence
</pre>

**From source to use.** Purple boxes show the four stages. Dotted arrows lead to the checks, in green, that tell us how far a revision reached. Each workload has its own path through these stages.

For the worker in the opening example, finding the key in the Secret was only the preparation check. The missing step was deciding whether the worker needed the key and making its startup checks and deployment agree.

A configuration change is finished when every intended workload uses the intended revision and we can verify it.

## References

- [Updating Configuration via a ConfigMap - Kubernetes](https://kubernetes.io/docs/tutorials/configuration/updating-configuration-via-a-configmap/)
- [ConfigMaps - Kubernetes](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Deployments - Kubernetes](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [ExternalSecret API - External Secrets Operator](https://external-secrets.io/latest/api/externalsecret/)
- [Configuration Design and Best Practices - Google SRE Workbook](https://sre.google/workbook/configuration-design/)
