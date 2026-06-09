# Single-Machine Infrastructure Consulting Spec

## Purpose

This document scopes a consulting engagement to make the Epytype / White Crystal stack operational, secure, and commercially usable on **one machine first**.

The goal is not generic platform engineering. The goal is the shortest path to:

1. reliable daily research and coding workflows;
2. secure handling of strategic IP and future customer data;
3. faster proof, compiler, and document-store iteration;
4. a system credible enough that Japanese and U.S. companies would be
   comfortable evaluating it;
5. a deployment shape that supports revenue quickly without forcing premature
   scale work.

## Guiding Rule

Optimize for **max revenue per unit cost**, not architectural completeness.

That means:

- perfect one machine before clustering;
- reduce human friction before optimizing scale;
- protect trade secrets before broad automation;
- prefer deterministic, local-first workflows over complex managed services;
- separate public narrative from private implementation and protected assets;
- do not build infrastructure that only becomes useful after ten customers.

## Current Repo Reality

The repo series already has a useful split. The engagement should respect it.

| Repo | Role in this engagement | Why it matters |
|---|---|---|
| `epytype` / `epytype-github` | coordination hub, policy, security, access, rollout plan | this is where infra policy, repo boundaries, and operating rules should live |
| `epytype-spec` | public-safe or semi-public language and semantics spec | needed for external-facing trust and internal clarity, but not for secrets |
| `epytype-lang` | compiler/runtime/tooling implementation | main engineering spine; infra must make this repo fast to build, test, and protect |
| `epytype-kernel` | protected algorithms, cryptography, private assets, premium IP | highest-value repo; strongest access controls and isolation required |
| `epytype-docstore` | White Crystal corpus, graph retrieval, Lean/proof linkage, semantic compression fixtures | main revenue-adjacent research surface and likely early customer demo surface |

## High-Level Outcome

At the end of the consulting project, one server should provide:

- secure remote access from anywhere;
- strong private repo hosting and workflow boundaries;
- fast dev/test/proof workflows across multiple active threads;
- disciplined paper/proof/result storage so work does not sprawl across local
  files;
- a clean path for White Crystal, semantic compression, and proof tooling to
  become commercial offerings;
- an operating model credible for confidential customer evaluations.

## Business Objective

The first commercial value is likely not “general infrastructure hosting.”
It is one or more of:

1. private theorem/proof and semantic compression work for strategic clients;
2. secure research collaboration around White Crystal / Epytype;
3. enterprise licensing for protected kernels and proof-linked document systems;
4. custom AI-assisted formalization / retrieval / compression workflows.

The infrastructure should therefore optimize for:

- proprietary research protection;
- fast iteration on compiler, proofs, and docstore;
- trustworthy outputs and reproducible reports;
- customer-confidence security posture;
- low recurring ops burden.

## In Scope

### 1. One-Machine Operating Environment

Design and implement the baseline operating environment for a single primary
server:

- OS hardening and baseline patching strategy;
- disk layout and encrypted storage plan;
- service layout for public-safe vs private-sensitive workloads;
- local build/test/proof directories;
- backup/restore plan;
- log policy;
- operator runbooks.

### 2. Secure Remote Access

Design a low-friction global access workflow for you personally:

- stable remote entry from anywhere;
- SSH that is easy to use and hard to misuse;
- device trust policy;
- emergency recovery path if a laptop is lost;
- minimal exposed surface on the public internet;
- session recording or audit logging where appropriate.

This should be optimized for daily use, not enterprise bureaucracy.

### 3. Repo And IP Boundary Enforcement

Implement the repo boundary model operationally:

- GitHub for public-safe and coordination surfaces;
- Forgejo for more sensitive implementation and strategic IP;
- explicit rules for which repo types may live where;
- least-privilege access;
- secrets entirely outside Git;
- branch protection and merge discipline;
- backup/restore for private code hosting.

### 4. Research Workflow Control

Reduce paper/proof sprawl:

- canonical project/workspace layout;
- rules for papers, manifests, normalized records, proofs, reports, and build
  output;
- locked artifact flow for new results;
- deterministic output folders;
- generated vs source-of-truth separation;
- archive policy for experiments and abandoned lines of work.

The practical test is:

> writing a paper or theorem campaign should not leave 100+ ambiguous local
> files scattered across the machine.

### 5. Dev Lifecycle Optimization

Improve iteration speed for active multi-threaded work:

- worktree or equivalent branch/workspace model;
- faster build/test/proof feedback;
- policy for long-running background tasks;
- CI that protects quality without leaking private data;
- local dashboards or reports for proof/build status;
- issue/workstream discipline.

### 6. AI Proof And Dev Stack

Scope the AI side as infrastructure-assisted, not hype-driven:

- model access strategy for “GPT-5.4 class” proof/dev work;
- local routing policy for sensitive prompts and corpora;
- auditability of AI-produced code/proofs;
- workflow support for Lean audit, Epytype-native proof plans, and theorem
  extraction;
- future option for Lean-driven or proof-certificate-driven AI proving.

This project should not depend on training your own frontier model.
It should make existing model access safer, cheaper, and more useful.

### 7. Proof / Lean / Epytype Validation Workflow

Design a practical validation lane for:

- existing Lean-ledger work;
- Epytype-native proof-certificate migration work;
- docstore proof provenance;
- theorem extraction from papers;
- reproducible build and verification reports.

Important boundary:

- Lean remains current audit authority where already used.
- The infra project should enable proof workflows, not force a complete proof
  kernel rewrite during the infra phase.

### 8. Security For Confidential Customer Data

Bring the machine to a level where a serious company could evaluate it for
private work:

- encryption at rest;
- encrypted backups;
- secrets management;
- access logging;
- incident response basics;
- customer-project separation rules;
- data retention/deletion policy;
- minimal public exposure;
- secure file transfer and temporary sharing policy.

This is not a certification program. It is an operational trust baseline.

### 9. Cryptography / Encryption Rollout Support

Support rollout of encryption/decryption primitives and security testing
workflow:

- key hierarchy and rotation policy;
- storage of signing/encryption keys;
- split between research crypto code and production-secret handling;
- test harness expectations;
- review path for protected crypto work in `epytype-kernel`.

### 10. Semantic Compression Operations

Support semantic compression as a product/research capability:

- deterministic report generation;
- canonical fixture documents;
- metric ledgers;
- storage layout for compression results;
- comparison against gzip and lower-bound estimates;
- auditability of what is lossless vs semantic-regenerative.

## Explicitly Out Of Scope

To keep cost low and speed high, the following are not phase-1 goals:

- multi-server orchestration;
- Kubernetes;
- global high availability;
- large-team IAM bureaucracy;
- customer self-serve SaaS;
- broad MLOps platform build-out;
- replacing every legacy tool immediately;
- full rewrite of Lean before the machine is useful;
- perfect zero-trust enterprise architecture across many sites.

## Repo-Specific Deliverables

### `epytype-github`

Deliverables:

- operating model for GitHub vs Forgejo;
- secret handling policy;
- backup/restore and cutover checklist;
- branch protection and release policy;
- consulting engagement spec and execution ledger;
- risk register and incident runbook.

Why this matters:

- this repo is the management plane for the whole project.

### `epytype-lang`

Deliverables:

- build/test workflow for compiler/runtime;
- local and hosted CI privacy controls;
- native-code policy enforcement path;
- workspace/thread model for parallel development;
- artifact discipline for generated outputs;
- performance and validation workflow.

Why this matters:

- this is the engineering core and will consume most infra cycles.

### `epytype-kernel`

Deliverables:

- strongest access controls;
- separate backup and storage policy;
- restricted collaborator model;
- review workflow for protected algorithms and cryptography;
- no-leak rules for benchmark and theorem assets.

Why this matters:

- this is likely the highest-value IP surface.

### `epytype-docstore`

Deliverables:

- paper/proof/result storage workflow;
- deterministic artifact and report layout;
- proof-ledger handling;
- White Crystal graph/retrieval validation lane;
- AI-readable and human-readable paper export workflow;
- semantic compression metrics and fixture discipline.

Why this matters:

- this is closest to customer-visible value and research output.

### `epytype-spec`

Deliverables:

- public-safe spec publication path;
- readable vs protected boundary;
- controlled examples;
- consistency with implementation policy.

Why this matters:

- this is the trust layer for external understanding, but should not leak core
  implementation advantages.

## Target Architecture: One Server

The consultant should design for one machine with four logical zones:

1. **Operator zone**  
   Your direct shell/editor/AI workflow.

2. **Private source zone**  
   Private repos, local clones, worktrees, proofs, manifests, and protected
   artifacts.

3. **Service zone**  
   Forgejo, CI runners, local dashboards, proof/report services, and internal
   storage services.

4. **Public-safe zone**  
   Only what must be internet-facing or shareable.

Core principle:

> Most of the machine should not be directly exposed to the public internet.

## Revenue-First Priority Order

The consultant should execute in this order unless blocked:

### Priority 1: Secure access + repo boundaries

Why first:

- prevents catastrophic leaks;
- supports all other work;
- cheapest high-leverage improvement.

Success looks like:

- you can securely reach the machine globally in minutes;
- private code and trade secrets are not living in ad hoc laptop sprawl;
- GitHub vs Forgejo rules are operational.

### Priority 2: Workflow discipline for papers, proofs, and code

Why second:

- this saves time immediately;
- reduces lost work and duplicate work;
- makes AI assistance and consulting output reusable.

Success looks like:

- one canonical place for source, generated outputs, proofs, and reports;
- no ambiguous “latest_final_v3_real” style file chaos;
- theorem and paper extraction becomes a repeatable pipeline.

### Priority 3: Build/test/proof acceleration

Why third:

- lowers iteration cost on the highest-value technical surfaces;
- directly improves delivery speed.

Success looks like:

- faster loops for `epytype-lang`, `epytype-docstore`, and proof workflows;
- multi-thread work without context collisions;
- local dashboards or status reports that remove guesswork.

### Priority 4: Customer-confidence security baseline

Why fourth:

- needed before serious confidential collaborations;
- supports enterprise conversations.

Success looks like:

- clear policy for secrets, backups, encryption, user access, incident response,
  and customer-data handling.

### Priority 5: AI + proof + semantic compression operating lane

Why fifth:

- this is where infra starts amplifying product differentiation rather than only
  reducing risk.

Success looks like:

- AI can be used safely on the right materials;
- proof artifacts are auditable;
- semantic compression metrics are easy to generate and compare.

## Proposed Work Packages

### Work Package A: Server Foundation

Deliver:

- machine hardening checklist;
- encrypted disk/storage layout;
- admin access model;
- patch/update policy;
- baseline monitoring/logging;
- backup/restore drill.

### Work Package B: Remote Access And Personal Workflow

Deliver:

- secure remote entry method;
- SSH profile and key policy;
- travel-safe/global-access setup;
- laptop loss recovery procedure;
- file sync and remote editing pattern.

### Work Package C: Repo Hosting And Private Code Path

Deliver:

- GitHub/Forgejo split implementation;
- private Forgejo baseline on the machine;
- repo migration order;
- auth and role model;
- branch protection and backup policy.

### Work Package D: Research Asset Organization

Deliver:

- canonical directory and artifact model for papers/proofs/results;
- source vs generated rules;
- archive policy;
- deterministic report layout;
- worktree/branch discipline.

### Work Package E: Build / CI / Proof Lane

Deliver:

- local test harness entrypoints;
- safe CI runner layout;
- privacy-safe logs;
- proof and docstore report locations;
- break/fix triage path.

### Work Package F: Security And Crypto Operations

Deliver:

- secret management baseline;
- key storage and rotation policy;
- encrypted backup policy;
- data handling policy for future customers;
- review path for cryptographic code and tests.

### Work Package G: AI And Product Acceleration

Deliver:

- model routing and access policy;
- sensitive vs non-sensitive prompt/data policy;
- reproducible AI-dev workflow for code/proofs/papers;
- revenue-prioritized shortlist of AI-enabled product features.

## Acceptance Criteria

The consulting project is successful when:

1. one machine can be securely administered from anywhere by you;
2. private repos and protected assets have a clear and enforced home;
3. daily paper/proof/code work stops generating unmanaged file sprawl;
4. the core repos have a faster and more reliable build/test/proof loop;
5. backups, restores, and secrets handling are documented and tested;
6. the machine is credible for confidential pilot work;
7. the infra does not materially increase recurring costs;
8. the operating model is documented well enough that another trusted engineer
   can step in.

## Required Consulting Outputs

Ask the consultant to produce, at minimum:

- architecture diagram for the one-machine design;
- repo boundary and hosting plan;
- remote access design;
- secrets and encryption policy;
- backup/restore and disaster recovery runbook;
- CI/runner policy;
- paper/proof/result artifact workflow;
- customer-data handling baseline;
- implementation backlog ordered by ROI;
- risk register with severity and mitigation.

## Suggested Execution Sequence

1. repo and threat review;
2. one-machine architecture proposal;
3. access and hardening implementation;
4. private hosting and repo boundary implementation;
5. workflow cleanup for papers/proofs/results;
6. build/test/proof acceleration;
7. backup/restore drill;
8. security review and final operating runbook.

## Questions The Consultant Must Answer

Before work begins, require explicit answers to:

1. What should be on GitHub now, and what should move to Forgejo first?
2. What is the safest remote access pattern with the least daily friction?
3. How should secrets, signing keys, and encryption keys be handled on one
   machine?
4. How should White Crystal paper/proof/result artifacts be organized?
5. What build/test/proof loops are costing the most time right now?
6. What must be true before a confidential customer dataset can touch the box?
7. Which controls are real security wins, and which are performative overhead?
8. What gives the highest revenue leverage in the next 30, 60, and 90 days?

## Non-Negotiable Constraints

- one server only for phase 1;
- minimal recurring cost;
- no trade-secret leakage into public-safe surfaces;
- no secrets in Git;
- no premature scale architecture;
- no “enterprise platform” detour without immediate revenue justification.

## 30 / 60 / 90 Day Success Markers

### 30 Days

- secure remote access working smoothly;
- single-machine private hosting and repo boundary plan active;
- artifact sprawl reduced with a canonical workspace layout;
- backup and secret policies documented.

### 60 Days

- Forgejo/private code workflow stable for the most sensitive repos;
- build/test/proof loops materially faster;
- White Crystal artifact discipline in daily use;
- customer-confidence security baseline in place.

### 90 Days

- one-machine environment good enough for confidential pilot projects;
- AI/proof/docstore workflows aligned with the operating model;
- revenue-facing offers tied to secure reproducible delivery.

## Recommendation

Hire for this as a **principal infrastructure / systems / security workflow**
engagement, not as generic DevOps.

The right person should be strong in:

- Linux/server operations;
- SSH, secure networking, and secrets handling;
- self-hosted Git platforms;
- backup/disaster recovery;
- build/CI systems;
- developer workflow design;
- applied security judgment;
- enough compiler/research empathy to avoid breaking the proof/docstore work.

They do **not** need to be the main theorem prover or language designer.
They need to make the machine and workflow trustworthy, fast, and hard to leak.
