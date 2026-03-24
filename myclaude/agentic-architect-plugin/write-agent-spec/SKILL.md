---
name: write-agent-spec
description: >
  Help users write Claude Code skill specifications (SKILL.md files) following
  proven design patterns. Use when the user asks to "write a skill",
  "create a SKILL.md", "design a skill spec", "build an agent skill",
  "scaffold a skill", or needs help choosing a design pattern for a new skill.
  Also use when asked to "write an agent spec", "document a skill", or "define
  a slash command".
argument-hint: "<skill idea or domain>"
---

# Write Agent Spec

Design and generate well-structured SKILL.md files by selecting the right Claude Code design pattern, gathering requirements, then producing a spec that follows project conventions.

## How It Works

```
┌──────────────────────────────────────────────────────────────────┐
│                     WRITE AGENT SPEC                             │
├──────────────────────────────────────────────────────────────────┤
│  Phase 1: DISCOVERY                                              │
│  ✓ What does the skill do?                                       │
│  ✓ Who uses it and when?                                         │
│  ✓ Action or on-demand knowledge?                                │
│  ✓ External tool integrations?                                   │
├──────────────────────────────────────────────────────────────────┤
│  Phase 2: PATTERN SELECTION                                      │
│  ✓ Match use case to one of 5 Claude Code design patterns        │
│  ✓ Present recommendation with rationale                         │
│  ✓ Confirm with user before proceeding                           │
├──────────────────────────────────────────────────────────────────┤
│  Phase 3: DETAIL GATHERING                                       │
│  ✓ Pattern-specific questions                                    │
│  ✓ Trigger phrases, output format, references needed             │
│  ✓ Connector integrations, argument handling                     │
├──────────────────────────────────────────────────────────────────┤
│  Phase 4: GENERATE                                               │
│  ✓ Fill skill-spec-template.md with gathered details             │
│  ✓ Generate SKILL.md + references/ files if needed              │
│  ✓ Present for review and iterate                                │
└──────────────────────────────────────────────────────────────────┘
```

> **Gate rule**: Do NOT generate any SKILL.md content until Phase 3 is complete. If the user asks to skip ahead, explain that requirements gathering produces significantly better specs and offer an abbreviated discovery instead.

## Phase 1: Discovery

Understand what the user wants to build. Extract information already provided in the initial request — skip any question already answered.

Ask only what is unclear:

- What should this skill help users accomplish?
- Is it a user-initiated action (slash command with arguments) or on-demand knowledge Claude loads when a topic comes up?
- Who is the target user? (engineer, PM, designer, etc.)
- Does it integrate with external tools or services? (MCP servers, databases, SaaS tools)
- Will it run in Cowork (knowledge work context) or Claude Code (engineering/terminal context)?

Summarize your understanding and confirm before proceeding to Phase 2.

## Phase 2: Pattern Selection

Match the user's use case to one of the five Claude Code design patterns. Load `references/design-patterns.md` to review the detailed criteria for each pattern.

Present a recommendation table:

```
| Pattern            | Fit      | Rationale                          |
|--------------------|----------|------------------------------------|
| Context Loader     | Strong   | [reason]                           |
| Structured Gen.    | Moderate | [reason]                           |
| Checklist Reviewer | Weak     | [reason]                           |
| Guided Discovery   | —        | [reason]                           |
| Phased Pipeline    | —        | [reason]                           |
```

**Decision heuristic** (apply in order):

1. Skill's primary job is loading reference docs for a specific domain/library → **Context Loader**
2. Skill produces a consistent structured artifact from a template → **Structured Generator**
3. Skill evaluates or scores existing content against criteria → **Checklist Reviewer**
4. Skill cannot produce good output without first interviewing the user → **Guided Discovery**
5. Skill orchestrates ordered steps where each depends on the previous → **Phased Pipeline**
6. Use cases can overlap — patterns compose (e.g., Guided Discovery + Structured Generator is the most common combination)

Confirm the chosen pattern with the user before Phase 3. If the user is unfamiliar with patterns, give a one-sentence explanation of each.

## Phase 3: Detail Gathering

Ask pattern-specific follow-up questions, then universal questions. Wait for answers before generating.

**Context Loader:**
- What domain, library, or framework does it cover?
- What reference files should live in `references/`? (list topics, not file names)
- What keywords in a user's message should trigger loading this context?

**Structured Generator:**
- What artifact does it produce? (ADR, report, PR description, email, etc.)
- What are the required sections/fields in the output?
- Does it accept a file or text as input via `$ARGUMENTS` or `@$1`?
- Are there style rules or tone guidelines to enforce?

**Checklist Reviewer:**
- What content is being reviewed? (code, a document, a PR, a config)
- What are the review dimensions? (security, performance, clarity, etc.)
- What is the severity model? (Critical / Warning / Info, or custom)
- Does it need to pull content from a tool (source control, document store)?

**Guided Discovery:**
- What information must be collected before generating output?
- What are the phases of questioning? (group related questions together)
- What happens if the user skips a question?

**Phased Pipeline:**
- What are the ordered steps? (list in sequence)
- Where are the user approval gates? (which steps require confirmation)
- What is the output at each checkpoint?

**Universal questions (all patterns):**
- What phrases would a user say to invoke this skill? (becomes the `description` field)
- Does the skill accept a direct argument? If so, what? (becomes `argument-hint`)
- What does the final output look like? (provide a template or example)
- Does it need `~~category` connector integrations? Which categories?
- Are any `references/` files needed for detailed content?

Confirm all details before proceeding. State what you plan to generate.

## Phase 4: Generate

Load `references/skill-spec-template.md`. Select the template section that matches the chosen pattern. Fill all `{PLACEHOLDER}` values with gathered information.

Generate:

1. **`SKILL.md`** — Complete file with valid YAML frontmatter and markdown body
2. **`references/` files** — One file per major reference topic (if needed)

Present the full output to the user. Ask for feedback and iterate until satisfied.

## Formatting Rules

Apply these conventions when generating any SKILL.md:

- **Body is instructions for Claude, not documentation for the user.** Write directives, not descriptions.
- **Imperative/infinitive style.** "Parse the config file" — not "You should parse the config file."
- **Three-layer progressive disclosure:**
  - Frontmatter `description` (~100 words) — always in context, must include trigger phrases
  - SKILL.md body (< 3,000 words, ideally 1,500-2,000) — loads when skill triggers
  - `references/` files (unlimited) — loads on demand during execution
- **Frontmatter `description`**: third-person, with specific trigger phrases in quotes.
- **Connector references**: use `~~category` placeholders (e.g., `~~source control`, `~~knowledge base`) for tool-agnostic references. Document them in `CONNECTORS.md` at the plugin root.
- **Intra-plugin paths**: use `${CLAUDE_PLUGIN_ROOT}` — never hardcode absolute paths.
- **Argument handling**: use `$ARGUMENTS` for all arguments as a string, `$1`/`$2` for positional, `@$1` to inline file contents.
- **Naming**: kebab-case for skill directory name and `name` field. They must match.

## Additional Resources

- **`references/design-patterns.md`** — Detailed descriptions of all 5 patterns with Claude Code-specific implementation notes, examples, and a decision tree
- **`references/skill-spec-template.md`** — Pattern-specific SKILL.md templates with placeholders and a post-generation quality checklist
