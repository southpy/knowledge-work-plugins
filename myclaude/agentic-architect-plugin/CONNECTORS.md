# Connectors

## How tool references work

Plugin files use `~~category` as a placeholder for whatever tool the user connects in that category. For example, `~~project tracker` might mean Linear, Asana, Jira, or any other tracker with an MCP server.

Plugins are **tool-agnostic** — they describe workflows in terms of categories (project tracker, design, product analytics, etc.) rather than specific products.

## Connectors for this plugin

| Category | Placeholder | Examples | What It Enables |
| --- | --- | --- | --- |
| Project tracker | `~~project tracker` | Linear, Jira, Asana | Pull requirements and epics as input to `/write-agent-prd` and `/design-agent` |
| Knowledge base | `~~knowledge base` | Notion, Confluence | Reference prior Agent designs and ADRs during review and design |
| Source control | `~~source control` | GitHub, GitLab | Reference existing SKILL.md files during `/write-agent-spec` |
