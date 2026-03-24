# Agentic Architect Plugin

A plugin for designing, evaluating, and specifying AI Agent systems — built for [Cowork](https://claude.com/product/cowork) and Claude Code. Covers the full Agent design lifecycle: feasibility assessment, architecture design, PRD authoring, architecture review, and skill specification. Works standalone or connected to your project tracker and knowledge base.

## Installation

```bash
claude plugins add knowledge-work-plugins/myclaude/agentic-architect-plugin
```

## Commands

Explicit workflows you invoke with a slash command:

| Command | Description |
|---|---|
| `/design-agent` | Design a complete Agent architecture from a business scenario — Harness assessment, state machine, toolchain, context structure |
| `/review-agent` | Review an existing Agent design against the 8 anti-patterns, context layers, ACI toolchain, and Harness completeness |
| `/write-agent-prd` | Write an Agent PRD with embedded Harness quadrant, HITL design, toolchain spec, and Agent-level success metrics |
| `/write-agent-spec` | Design and generate SKILL.md files for Claude Code agents using the 5 proven skill design patterns |

## Skills

Domain knowledge Claude uses automatically when relevant:

| Skill | Triggers On |
|---|---|
| `harness-quadrant` | Feasibility evaluation, "is this a good fit for Agent", business automation assessment, PRD analysis |
| `anti-patterns` | Architecture review, "why is this Agent unstable", "review Agent design", postmortem |
| `context-design` | System prompt design, context layering, token window management, "context rot" |
| `tool-design` | Tool schema design, MCP tool definition, function calling interface, ACI principles |

## Example Workflows

### Assess a New Business Scenario

```
/design-agent We want to automate customer support triage — route tickets by urgency and product area
```

Runs Harness quadrant evaluation, outputs complete architecture: state machine, toolchain, context structure, Harness definition, anti-pattern pre-check, and an MVP implementation path.

### Review an Existing Agent Design

```
/review-agent @path/to/agent-design.md
```

Or paste the design directly. Gets a full report: 8 anti-pattern checks, context structure audit, toolchain ACI compliance, Harness completeness, risk rating, and prioritized improvement actions.

### Write an Agent PRD

```
/write-agent-prd automated invoice processing workflow
```

Runs guided discovery: Harness quadrant positioning, tech constraints, HITL node design, toolchain draft, connector availability. Outputs a complete Agent PRD with Agent-level success metrics (task success rate, latency SLA, human intervention rate).

### Write a Skill Spec

```
/write-agent-spec onboarding checklist generator for new engineers
```

Guides through discovery → pattern selection → detail gathering → SKILL.md generation. Produces a ready-to-use SKILL.md with the right design pattern and references structure.

## Standalone + Supercharged

All commands work without any integrations:

| What You Can Do | Standalone | Supercharged With |
|---|---|---|
| Agent feasibility assessment | Describe your business scenario | Project tracker (pull ticket requirements) |
| Architecture design | Describe the system | Knowledge base (find prior Agent designs) |
| Agent PRD authoring | Describe constraints manually | Project tracker (pull epics), knowledge base (find related docs) |
| Architecture review | Paste design doc | Knowledge base (reference prior decisions) |
| Skill spec writing | Describe the skill | Source control (reference existing skills) |

## MCP Integrations

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](CONNECTORS.md).

| Category | Examples | What It Enables |
|---|---|---|
| **Project tracker** | Linear, Jira, Asana | Pull requirements and epics as input to `/write-agent-prd` |
| **Knowledge base** | Notion, Confluence | Reference prior Agent designs and ADRs during review and design |
| **Source control** | GitHub, GitLab | Reference existing SKILL.md files during `/write-agent-spec` |

## Design Principles

This plugin embeds four frameworks that apply across all commands:

- **Harness Quadrant** — Two-axis evaluation (task clarity × verification automation) that determines when a scenario is ready for Agent investment
- **Context Layering** — Five-layer model (permanent, on-demand, runtime, memory, system) that prevents context rot
- **ACI Toolchain Design** — Agent-Centric Interface principles: ≤10 tools, clear boundaries, informative errors
- **8 Anti-Patterns** — Checklist of the most common Agent architecture failure modes, from over-stuffed system prompts to missing Harness

## Settings

Create a local settings file at `agentic-architect-plugin/.claude/settings.local.json` to set defaults:

```json
{
  "domain": "Your business domain (e.g., e-commerce, fintech, HR automation)",
  "techStack": ["Python", "LangGraph", "Claude API", "PostgreSQL"],
  "hitlPolicy": "strict | moderate | minimal",
  "tokenBudget": 8000
}
```
