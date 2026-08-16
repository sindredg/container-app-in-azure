# Roadmap

The remaining phases, in the order they will be built, with what each one has to decide before it can be called finished.

Phases 1 to 10 are complete. See the [phase pages](README.md#phases).

## Ordering

Automated delivery moved ahead of the database and the scaling work. Every later phase involves releasing an image, and each manual release so far has produced a defect: a stale build, a tag that was never raised, an architecture mismatch. Doing three more phases by hand repeats that three more times.

The virtual network stays last because it is a migration rather than a change, and it is easier to migrate a platform whose shape has stopped moving.

---

## Phase 11: Per-app pull identities

**Goal.** Each app pulls only its own images. Today both share one identity, so the web app can pull the API's images and the reverse, for no reason other than convenience during phase 10.

**Work.** One user-assigned identity per app. A `Container Registry Repository Reader` role assignment for each, scoped with an ABAC condition to that app's repository rather than the whole registry. Point each Container App at its own identity, then remove the shared one.

**Decisions to settle.**

- Whether the condition scopes to an exact repository name or a prefix, and what that implies for repositories added later.
- Whether the shared identity is deleted in the same release or left briefly for rollback.

**Done when.** Each app runs on its own identity, and an attempt to pull the other app's image with it is refused. The refusal is the evidence, not the successful pull.

Closes the shortcut recorded in the phase 10 page. Issue #24, upstream TLS verification, is folded in here because it needs a web image rebuild either way.

---

## Phase 12: Automated delivery

**Goal.** A push produces a deployed revision. No local Docker, no hand-edited image tag, no `terraform apply` from a laptop.

**Work.** A federated credential so GitHub Actions authenticates to Azure over OIDC with no stored secret. Scoped role assignments for the pipeline identity: enough to plan and apply, and to push images. Two workflows — `terraform plan` on pull requests with the plan posted for review, and build, push, apply on merge to `main`.

**Decisions to settle.**

- **Where the image tag comes from.** Deriving it from the commit makes it immutable by construction and removes the manual bump that broke phase 10. Semver from a version file keeps the tag human-readable and matches the existing validation rule. One or the other, not both by accident.
- **Whether apply is automatic on merge or gated behind an approval.** Automatic is the point of the exercise; a gate is more honest about a lab with one operator.
- **What the pipeline identity is allowed to do.** Contributor on the resource group is the easy answer and the wrong one to leave undocumented.

**Done when.** A commit to `main` results in a new revision serving traffic, with no local build, and the plan for that change is visible on the pull request that produced it. The GitHub repository holds no Azure secret.

**Why it matters beyond convenience.** Every manual release so far has produced a defect. The pipeline builds from the exact commit, so it cannot build stale code, and it runs on `amd64`, so the cross-architecture problem disappears rather than being worked around.

---

## Phase 13: Scaling behaviour

**Goal.** Scale in both directions, and stop the first visitor after a quiet period getting an error.

**Work.** Raise `max_replicas` above one, so the HTTP scale rule can fire for the first time — it has been configured since phase 7 and has never done anything. Fix the cold-start `504` (issue #23). Drive concurrent load and record what happens on the way up and on the way back down.

**Decisions to settle.**

- **Raise `proxy_read_timeout`, or set `min_replicas = 1`.** The first keeps scale-to-zero and trades a slow first request for a failed one. The second removes the delay and the cost profile with it.
- Whether the page should load immediately and fill in the API panel asynchronously, which makes a slow backend a slow panel rather than a failed page.

**Done when.** Under load, replicas appear and the API reports different replica names. After the load stops, they go away. A request after a long idle succeeds. Closes *Scaling and recovery tests*.

**Do this before the database.** More replicas means more concurrent connections, and connection behaviour is a design input for the next phase rather than something to discover afterwards.

---

## Phase 14: Azure SQL Database

**Goal.** The application holds state, and reaches it without a password.

**Work.** A logical server and a Basic tier database in Terraform. A Microsoft Entra administrator on the server, and the API's managed identity added as a contained database user with the minimum rights it needs. Firewall rules. The API records which revisions and replicas have served traffic, and the site shows what the platform has actually done.

**Decisions to settle.**

- **Where schema migrations run.** At container startup risks several replicas racing each other. A separate Container Apps job is cleaner and adds a moving part. By hand is honest for a lab and does not scale. This is the interesting problem in the phase and deserves a real answer rather than a default.
- **Basic tier rather than serverless.** Recorded with the arithmetic: the serverless free allowance is roughly fifty-five hours of uptime a month, and the auto-pause delay means a single visitor costs about an hour of it.
- **Whether storing revision history duplicates Log Analytics.** It does. The defensible answer is that the application needed a reason to hold state and the data is useful to a visitor without portal access. Worth writing down rather than waiting to be asked.

**Constraint.** `/health` must never touch the database. Probes run every few seconds while a replica is alive, and a query in that path would keep a connection open permanently.

**Done when.** The API reads and writes with no password anywhere in Terraform, in state, or in an environment variable, and the site shows real recorded history.

---

## Phase 15: Virtual network migration

**Goal.** Network-level control over the platform: security groups, egress control, and private endpoints for the registry, the state account, and the database.

**Work.** This is a migration, not a setting. The network type of a Container Apps environment cannot be changed after creation, and the current environment is Consumption-only, which does not support user-defined routes or NAT Gateway egress even with a virtual network attached. So: a new workload profiles environment in a virtual network, both apps redeployed into it, traffic cut over, then the old environment retired.

**Decisions to settle.**

- The subnet size, which cannot be changed later while resources are in it.
- Whether the new environment is internal-only with something in front of it, or keeps a public inbound address.
- How the cutover works, given both environments have different fully qualified domain names.

**Done when.** Both apps serve from the new environment, the registry, state account, and database are reachable only over private endpoints, and the old environment is deleted.

---

## After that

Not sequenced. Whichever is most useful at the time.

- **Observability front end.** Dashboards provisioned as files in the image, anonymous read-only access, Azure Monitor as a data source through a managed identity with Monitoring Reader. Worth doing after the database, when there is real data to show.
- **Container image scanning**, which is cheaper to add once a pipeline exists to hang it off.
- **Microsoft Sentinel detection rules** over the Log Analytics workspace.
- **A SQL Managed Instance exercise**, as a deliberate throwaway inside its twelve-month free window. Stand it up, do the dedicated subnet properly, connect to it, write up what was learned, delete it. It is not a candidate for backing this platform: the free allowance runs it about a quarter of the month, and it costs roughly a thousand a month afterwards.

## Working split

Platform work — Terraform, Azure, identity, networking, validation — is done by the repository owner. Application code, and the documentation that is not the worklog, is written with Claude.

Worklogs are written by whoever ran the commands, because they are an account of what actually happened and carry the screenshots that prove it.
