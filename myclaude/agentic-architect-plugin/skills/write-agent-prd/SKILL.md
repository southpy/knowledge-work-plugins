---
name: write-agent-prd
description: >
  Write an Agent PRD with embedded Harness quadrant positioning, HITL node
  design, toolchain spec, and Agent-level success metrics. Use when the user
  asks to "write an Agent PRD", "create an Agent requirements doc", "draft
  a PRD for an agent", "spec out an agent feature", or needs a requirements
  document that includes Harness definition, acceptance criteria, and human
  intervention checkpoints.
argument-hint: "<business scenario or agent feature description>"
metadata:
  version: "0.1.0"
  domain: agentic-architecture
---

# Write Agent PRD

Write a complete Agent PRD from a business scenario. Unlike a standard feature-spec, an Agent PRD must answer six questions that product specs omit: Harness quadrant position, tech constraints for automation, quantifiable acceptance criteria, HITL intervention points, toolchain design, and connector dependencies.

> **Gate**: Do NOT write the PRD until all six dependency sections are complete (Phases 1–3). If the user wants to skip ahead, explain which section is still missing and offer to abbreviate the questions.

## Phase 1: Harness Quadrant Assessment

**Goal**: Determine whether the scenario is ready for Agent investment and at what autonomy level.

Load `${CLAUDE_PLUGIN_ROOT}/harness-quadrant/SKILL.md` for the full framework.

Ask (skip if already answered in the user's initial request):

1. How verifiable is the outcome? Can a script or external system confirm success without human judgment?
2. How well-specified is the task? Are the inputs, steps, and acceptable outputs predictable and documented?

Map the answer to one of four quadrants:
- **High verification + High specification → Full autonomy** — proceed to Agent PRD
- **Low verification + High specification → Supervised autonomy** — HITL required; proceed with mandatory human checkpoints
- **High verification + Low specification → Pilot first** — recommend a discovery sprint before writing the PRD
- **Low verification + Low specification → Not ready** — stop; surface the specific prerequisites the business must define first

If the quadrant is "Not ready", stop here and deliver a blockers list instead of a PRD.

**Output**: Quadrant position + autonomy level recommendation.

> **Gate**: Confirm quadrant with user before proceeding.

## Phase 2: Constraint Discovery

**Goal**: Surface the six dependency fields that shape every architectural decision.

Use AskUserQuestion when running in Cowork mode. Gather:

1. **Tech constraints** — existing systems the Agent must integrate with, latency SLAs, token budget, rate limits
2. **Acceptance criteria** — what measurable condition means "task succeeded"? (not "Agent said it succeeded")
3. **HITL design** — which decision points require human approval? At what confidence threshold does the Agent escalate?
4. **Toolchain draft** — which actions does the Agent need to take? Map to specific tool categories (read-only vs. write vs. destructive)
5. **Connector availability** — which MCP integrations are available in the deployment environment?
6. **Failure mode** — what is the rollback or recovery path if the Agent fails mid-task?

Apply the ACI constraint immediately: if toolchain draft exceeds 10 tools, flag the overload and prompt a re-scoping discussion before continuing.

**Output**: Constraints table with all six fields populated.

> **Gate**: Confirm constraints with user before proceeding to Phase 3.

## Phase 3: Architecture Alignment

**Goal**: Lock in the design decisions the PRD will document — do not generate the PRD until these are agreed.

1. Propose the **architecture mode** based on Phases 1–2:
   - Single Agent (task is atomic, ≤8 tools, latency-sensitive)
   - Orchestrator + Workers (parallelizable subtasks or specialized domains)
   - Critic Loop (output quality is hard to verify programmatically)
2. Propose the **context structure**: which constraints go in permanent layer vs. Skills vs. runtime injection
3. Run the **anti-pattern pre-check**: scan the toolchain and HITL design against the 8 anti-patterns checklist — flag any violations before writing the PRD

Load `${CLAUDE_PLUGIN_ROOT}/anti-patterns/references/anti-patterns-detail.md` for the checklist.

Present proposed architecture mode + anti-pattern findings to the user. If violations are found, get explicit user sign-off before continuing.

**Output**: Architecture decisions locked.

> **Gate**: User approves architecture mode before Phase 4.

## Phase 4: Generate PRD

**Goal**: Produce the full Agent PRD using all gathered information.

Load `references/agent-prd-template.md` for the output template. Fill every section with information from Phases 1–3. Do not leave placeholders unfilled — if data is missing, add a `[TBD: {what is needed}]` callout so the owner knows what to complete.

Apply these rules while filling the template:
- **Harness definition** must have all four elements: acceptance criteria (measurable), execution boundary (retry limit + permitted operations), feedback signal (external, not Agent self-report), rollback procedure
- **Success metrics** must include both product-level (user-facing) and Agent-level (task success rate, latency P95, human intervention rate %)
- **HITL table** must cover every decision point where confidence ≥ threshold → auto-proceed and confidence < threshold → escalate

## Additional Resources

- **`references/agent-prd-template.md`** — Full PRD template with all required sections; load during Phase 4
- **`${CLAUDE_PLUGIN_ROOT}/harness-quadrant/SKILL.md`** — Harness quadrant evaluation framework; load during Phase 1
- **`${CLAUDE_PLUGIN_ROOT}/anti-patterns/references/anti-patterns-detail.md`** — 8 anti-pattern checklist; load during Phase 3
- **`${CLAUDE_PLUGIN_ROOT}/tool-design/references/aci-principles.md`** — ACI toolchain design principles; load if toolchain exceeds 10 tools or has boundary issues
- **`${CLAUDE_PLUGIN_ROOT}/context-design/references/context-layers.md`** — Context layering rules; load during Phase 3 context structure design

## If Connectors Available

If **~~project tracker** is connected:
- Phase 2: pull epic or ticket requirements automatically instead of asking manually

If **~~knowledge base** is connected:
- Phase 3: search for prior Agent ADRs and architecture decisions as precedent

## Tips

1. **The gate on quadrant matters** — writing a PRD for a "not ready" scenario wastes everyone's time. The quadrant assessment is not a formality.
2. **HITL is not optional for Supervised autonomy** — if the quadrant says "Supervised", the HITL table is a required section, not a nice-to-have.
3. **Acceptance criteria ≠ "Agent succeeded"** — every acceptance criterion must be verifiable by something external to the Agent: a database query, an API call, a unit test, a human checklist.
