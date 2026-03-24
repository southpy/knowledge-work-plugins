# Agent PRD Template

Fill every section. Replace `{placeholder}` values. Use `[TBD: {what is needed}]` for data that must be completed by the owner — never leave a section silently empty.

---

```markdown
# Agent PRD: {Agent Name}

**Status**: Draft | In Review | Approved
**Owner**: {Name / Team}
**Last Updated**: {Date}
**Harness Quadrant**: {Fully Autonomous | Supervised Autonomy | Pilot First | Not Ready}

---

## 1. Problem & Business Context

### Problem Statement
{2–3 sentences. What is failing or missing without this Agent? What is the cost of the status quo?}

### Success Definition (Business Level)
{What does success look like for the business in 6 months? Be specific: "reduce ticket triage time from 4h to 30min", not "improve efficiency".}

### Scope
**In scope**: {What this Agent handles}
**Out of scope**: {What this Agent explicitly does not handle — prevents scope creep}

---

## 2. Harness Quadrant Assessment

| Axis | Rating | Evidence |
|------|--------|----------|
| Task Specification Clarity | High / Medium / Low | {Why: inputs/steps/outputs are well-defined or not} |
| Verification Automation | High / Medium / Low | {Why: can an external system confirm success without human judgment?} |

**Quadrant Position**: {Top-right / Top-left / Bottom-right / Bottom-left}
**Recommended Autonomy Level**: {Full autonomy / Supervised autonomy / Pilot first}

**Justification**: {1 paragraph explaining the rating and any conditions that would move the quadrant position}

### Prerequisites (if not fully autonomous)
{List the specific conditions that must be true before upgrading to higher autonomy level, e.g., "verification API must be built", "edge case catalog must reach 95% coverage"}

---

## 3. Architecture Mode

**Selected Mode**: {Single Agent | Orchestrator + Workers | Critic Loop | Hybrid}

| Option | Pros | Cons | Selected? |
|--------|------|------|-----------|
| Single Agent | Simple, low latency | {limitation} | {Yes/No} |
| Orchestrator + Workers | Parallelism, specialization | Coordination overhead | {Yes/No} |
| Critic Loop | Quality assurance on hard-to-verify outputs | 2× latency | {Yes/No} |

**Decision rationale**: {Why this mode fits this scenario. Reference Harness quadrant position and toolchain complexity.}

---

## 4. Core Workflow

### Happy Path

```
{Input description}
  ↓
Step 1: {Action} [{Tool: tool_name}]
  ↓
Step 2: {Action} [{Tool: tool_name}]
  ↓
[HITL checkpoint: {decision point}]  ← if Supervised
  ↓
Step 3: {Action} [{Tool: tool_name}]
  ↓
{Output description}
```

### Key Branches

| Condition | Branch | Recovery Path |
|-----------|--------|---------------|
| {Condition 1, e.g., API returns empty} | {What Agent does} | {Fallback or escalation} |
| {Condition 2, e.g., confidence < threshold} | Escalate to human | HITL checkpoint triggered |
| {Condition 3, e.g., destructive action required} | {Pause or require approval} | {Approval flow} |

---

## 5. Human-in-the-Loop (HITL) Design

> Skip this section only if Harness Quadrant is **Fully Autonomous**.

### HITL Policy

**Policy level**: Strict | Moderate | Minimal
**Default escalation channel**: {Slack channel / Email / Dashboard / In-app notification}

### HITL Checkpoint Table

| Checkpoint | Trigger Condition | Confidence Threshold | Human Decision Required | Timeout / Default |
|------------|-------------------|----------------------|------------------------|-------------------|
| {CP-1: e.g., Before writing to production DB} | Always | N/A | Explicit approval | — |
| {CP-2: e.g., Ambiguous customer intent} | Confidence < {0.7} | {0.7} | Clarify intent | 4h → escalate to manager |
| {CP-3: e.g., High-value transaction} | Transaction > {$X} | N/A | Approval | 1h → reject |

### Escalation Flow

```
Agent confidence < threshold
  → Format escalation message: {what Agent found, what it needs, options available}
  → Post to {channel / webhook}
  → Wait {timeout}
  → If approved: continue from checkpoint
  → If rejected: rollback (see §7 Harness)
  → If timeout: {default action}
```

---

## 6. Toolchain Design

> Constraint: ≤10 tools per Agent. If this list exceeds 10, scope must be reduced or Agent must be split.

### Tool Inventory

| Tool Name | Category | Action Type | Description (ACI compliant) |
|-----------|----------|-------------|------------------------------|
| `{tool_name}` | {Read / Write / Destructive} | {business action description — not implementation detail} | When: {when to call}. Not when: {when NOT to call}. Returns: {what it returns}. |
| ... | | | |

**Total tool count**: {N} / 10

### ACI Compliance Check

- [ ] All tool names describe business actions (not technical implementation)
- [ ] Every tool description includes "when to call" AND "when NOT to call"
- [ ] Every tool returns structured, parseable output (not raw API responses)
- [ ] Error responses include: type, human-readable message, suggestion, retryable flag
- [ ] No two tools have overlapping primary use cases
- [ ] Framework metadata (retry counts, session IDs, latency) is NOT in tool results

---

## 7. Context Structure Design

### Permanent Layer (system prompt, ≤500 tokens)

```
{Agent identity: role + goal + output format requirement}
{Absolute constraints: what Agent must never do}
{Key Harness definition anchor: success = {measurable condition}}
```

### On-Demand Skills

| Skill | Trigger | Content Size |
|-------|---------|--------------|
| {skill-name} | {trigger phrase or condition} | ~{N} tokens |

### Runtime Injection (≤200 tokens per turn)

```
<runtime>
{Fields injected per turn: current_time, user_id, task_state, relevant_context}
</runtime>
```

### Memory Strategy

| Memory Type | Storage | When Written | When Read |
|-------------|---------|--------------|-----------|
| Working memory (current task state) | {file / Redis key} | Each step | Each step |
| Procedural memory (learned patterns) | MEMORY.md → Skills | After 3 successes | Relevant task |
| Error memory (failure cases) | memory/episodes/ | Immediately on failure | RAG retrieval |

---

## 8. Harness Definition

> The Harness is the contract that defines what "done" means. All four elements are required.

### Acceptance Criteria (Verifiable)

| # | Criterion | Verification Method | Owner |
|---|-----------|---------------------|-------|
| AC-1 | {Specific, measurable outcome — not "Agent said it succeeded"} | {external API call / DB query / unit test} | {Team} |
| AC-2 | {e.g., "Ticket routed to correct queue in ≤30s in 95% of cases"} | {monitoring dashboard / integration test} | {Team} |

### Execution Boundary

- **Max retries per step**: {N} (after this, escalate or fail)
- **Max end-to-end duration**: {X minutes} (after this, abort and escalate)
- **Permitted operations**: {list the verbs — read, create, update; be explicit about what's excluded}
- **Forbidden operations**: {e.g., delete, send external communication, write to production without review}

### Feedback Signal

- **Primary signal**: {Where the success/failure signal comes from — not the Agent's own output}
- **Secondary signal**: {Backup verification source}
- **Monitoring**: {Dashboard / alert / log sink to watch}

### Rollback Procedure

- **Trigger condition**: {When rollback activates, e.g., any AC fails OR execution boundary exceeded}
- **Steps**:
  1. {Undo step N: reverse the last write operation}
  2. {Notify: {channel} with task ID and failure reason}
  3. {Restore: bring system to last known good state}
- **Recovery time objective**: {How quickly must rollback complete?}

---

## 9. Anti-Pattern Pre-Check

| Anti-Pattern | Risk Level | Status | Mitigation |
|---|---|---|---|
| System prompt as knowledge base | {High/Med/Low} | {At risk / Mitigated} | {e.g., domain knowledge moved to Skills} |
| Tool proliferation (>10 tools) | {High/Med/Low} | {At risk / Mitigated} | {e.g., tool count is N/10} |
| Missing verification loop | {High/Med/Low} | {At risk / Mitigated} | {e.g., AC-1 verified by external API} |
| Multi-Agent without boundaries | {High/Med/Low} | {At risk / Mitigated} | {e.g., single Agent in MVP} |
| Memory not managed | {High/Med/Low} | {At risk / Mitigated} | {e.g., token monitoring at 70%/80%} |
| No evaluation baseline | {High/Med/Low} | {At risk / Mitigated} | {e.g., Pass@10 baseline before launch} |
| Premature multi-Agent | {High/Med/Low} | {At risk / Mitigated} | {e.g., single Agent first} |
| Constraints rely on expectation | {High/Med/Low} | {At risk / Mitigated} | {e.g., PreToolUse hook validates writes} |

---

## 10. Success Metrics

### Product-Level Metrics (Business Impact)

| Metric | Baseline | Target | Measurement Method |
|--------|----------|--------|--------------------|
| {e.g., Triage time per ticket} | {current} | {goal} | {how measured} |
| {e.g., Error rate in downstream process} | {current} | {goal} | {how measured} |

### Agent-Level Metrics (System Health)

| Metric | Definition | Target | Alert Threshold |
|--------|------------|--------|-----------------|
| Task Success Rate | % of tasks completing all ACs without human intervention | ≥{X}% | <{Y}% → page oncall |
| Latency P95 | 95th percentile end-to-end task duration | ≤{X}s | >{Y}s → page oncall |
| Human Intervention Rate | % of tasks requiring at least one HITL checkpoint | ≤{X}% | >{Y}% → review HITL thresholds |
| Hallucination / Wrong-action Rate | % of tasks with detected incorrect tool calls or wrong outputs | ≤{X}% | >{Y}% → freeze deploys |
| Token Cost per Task | Average tokens consumed per completed task | ≤{X}k tokens | >{Y}k → review context design |

---

## 11. Connector Dependencies

| Category | Required? | Connected Tool | Fallback If Absent |
|----------|-----------|----------------|-------------------|
| {e.g., CRM} | Required | {Salesforce MCP} | Cannot proceed — blocker |
| {e.g., Ticketing} | Required | {Jira MCP} | Manual input by user |
| {e.g., Knowledge base} | Optional | {Confluence MCP} | Agent uses static reference files |

---

## 12. Implementation Path

### MVP (Supervised Autonomy)
- Scope: {Narrowest viable version — which tasks, which users, which channels}
- Autonomy level: Supervised (all HITL checkpoints enabled)
- Harness: AC-1 only; metrics monitoring set up
- Launch gate: Pass@10 ≥ {X}%

### v2 (Expand Automation)
- Scope additions: {What gets added after MVP validation}
- Autonomy upgrade: {Which HITL checkpoints get removed based on MVP data}
- Gate: Human intervention rate ≤ {X}% sustained for {N} weeks

### v3 (Full Autonomy Target, if applicable)
- Conditions for full autonomy: {Specific metric thresholds that must be sustained}
```
