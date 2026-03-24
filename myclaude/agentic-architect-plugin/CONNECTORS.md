# Connectors

This plugin does not require any external integrations to function. All commands work from first principles using the embedded frameworks (Harness Quadrant, ACI, 8 Anti-Patterns, Context Layering).

The integrations below unlock additional capabilities when available:

---

## Project Tracker

**Category name**: `project tracker`
**Examples**: Linear, Jira, Asana, Shortcut

**Enables**:
- `/write-agent-prd` — pull epic or ticket requirements as input instead of describing manually
- `/design-agent` — read existing backlog items to frame the business scenario

**Without it**: provide requirements as free text in the command argument.

---

## Knowledge Base

**Category name**: `knowledge base`
**Examples**: Notion, Confluence, Obsidian (MCP), Google Docs

**Enables**:
- `/review-agent` — reference prior Agent ADRs and architecture decisions during review
- `/design-agent` — find existing similar Agents to avoid duplicating patterns
- `/write-agent-prd` — reference prior PRDs for format consistency

**Without it**: paste relevant prior decisions directly in the conversation.

---

## Source Control

**Category name**: `source control`
**Examples**: GitHub, GitLab, Bitbucket

**Enables**:
- `/write-agent-spec` — browse existing SKILL.md files in the repo to check conventions
- `/review-agent` — read live agent code to supplement the design document

**Without it**: paste or reference local files in the conversation.
