# Claude Code SKILL.md Templates

Pattern-specific templates for generating SKILL.md files. Replace all `{PLACEHOLDER}` values. Remove optional sections if not needed. Load during Phase 4 (Generate).

---

## Frontmatter Template (all patterns)

```yaml
---
name: {skill-name}
description: >
  {Third-person description. Example:}
  Help users {action}. Use when the user asks to "{trigger-phrase-1}",
  "{trigger-phrase-2}", "{trigger-phrase-3}", or needs help with {domain}.
argument-hint: "{Short description of expected argument, e.g.: <file path or topic>}"
---
```

**Rules:**
- `name`: kebab-case, lowercase, must match the skill directory name
- `description`: third-person ("Help users..." or "This skill..."), trigger phrases in double quotes
- `argument-hint`: include only if the skill accepts a direct argument; omit field entirely otherwise

---

## Template 1: Context Loader

Use when the skill's primary job is loading domain reference docs on demand.

```markdown
---
name: {skill-name}
description: >
  Help users work with {domain}. Use when the user asks about
  "{domain-keyword-1}", "{domain-keyword-2}", or needs guidance on
  {key-topic-1}, {key-topic-2}, or {key-topic-3}.
---

# {Skill Title}

On-demand expertise for {domain}. Load the relevant reference file when the user's question touches a specific topic.

## Domain Overview

{2-3 sentence overview of the domain. What is it? Why does it matter?}

## Key Concepts

- **{Concept 1}**: {One-line definition}
- **{Concept 2}**: {One-line definition}
- **{Concept 3}**: {One-line definition}

## Reference Loading

When the user asks about {topic-1}, read `references/{topic-1-file}.md`.
When the user asks about {topic-2}, read `references/{topic-2-file}.md`.
When the user asks about {topic-3}, read `references/{topic-3-file}.md`.

Load the relevant reference before responding. Do not answer from general knowledge when a reference file exists — the reference is authoritative.

## Common Tasks

- **{Task 1}**: {What to do}
- **{Task 2}**: {What to do}
- **{Task 3}**: {What to do}

## Additional Resources

- **`references/{topic-1-file}.md`** — {What it covers}
- **`references/{topic-2-file}.md`** — {What it covers}
- **`references/{topic-3-file}.md`** — {What it covers}
```

---

## Template 2: Structured Generator

Use when the skill produces a consistent structured artifact from a template.

```markdown
---
name: {skill-name}
description: >
  Generate {artifact-type} from {input-description}. Use when the user asks to
  "write {artifact}", "create {artifact}", "draft {artifact}", or needs a
  {artifact-type} for {use-case}.
argument-hint: "<{input-description}>"
---

# {Skill Title}

Generate a well-structured {artifact-type} from {input-description}.

## Usage

```
/{skill-name} {$ARGUMENTS or @$1 description}
```

{Optional: specific instruction about what the user provides as input}

## Output Format

Generate the following structure:

~~~markdown
# {Artifact Title}

## {Section 1}
{Description of what goes here}

## {Section 2}
{Description of what goes here}

## {Section 3}
{Description of what goes here}
~~~

## Style Rules

- {Rule 1: tone, length, voice}
- {Rule 2: what to include or omit}
- {Rule 3: formatting convention}

{Optional: "Load `references/{style-guide}.md` for detailed style guidelines."}

## If Connectors Available

If **~~{category}** is connected:
- {What the connector enables}

## Tips

1. {Tip 1 for the user}
2. {Tip 2 for the user}
```

---

## Template 3: Checklist Reviewer

Use when the skill evaluates existing content against defined criteria.

```markdown
---
name: {skill-name}
description: >
  Review {content-type} for {review-focus}. Use when the user asks to
  "review {content}", "audit {content}", "check {content}", or before
  {common-trigger-event}.
argument-hint: "<{content-type} path or URL>"
---

# {Skill Title}

Review {content-type} against a structured checklist and produce a severity-grouped findings report.

## Usage

```
/{skill-name} @$1
```

Review the provided {content-type}: @$1

If no {content-type} is provided, ask the user what to review.

## Review Dimensions

### {Dimension 1}
- {Category A}
- {Category B}

### {Dimension 2}
- {Category A}
- {Category B}

### {Dimension 3}
- {Category A}
- {Category B}

{Optional: "Load `references/{checklist-file}.md` for the full checklist criteria."}

## Output

~~~markdown
## Review: [{subject}]

### Summary
[1-2 sentence overview of the {content-type} and overall quality]

### Findings

| Severity | Dimension | Finding | Recommendation |
|----------|-----------|---------|----------------|
| 🔴 Critical | {Dimension} | [description] | [fix] |
| 🟡 Warning  | {Dimension} | [description] | [improvement] |
| 🔵 Info     | {Dimension} | [description] | [suggestion] |

### What Looks Good
- [Positive observations]

### Verdict
[Approve / Request Changes / Needs Discussion]
~~~

## If Connectors Available

If **~~source control** is connected:
- Pull {content-type} automatically from a URL or PR reference

If **~~{other-category}** is connected:
- {What it enables}

## Tips

1. {Tip 1}
2. {Tip 2}
```

---

## Template 4: Guided Discovery

Use when the skill needs to interview the user before generating output.

```markdown
---
name: {skill-name}
description: >
  Help users {goal} through a guided conversation. Use when the user wants to
  "{trigger-phrase-1}", "{trigger-phrase-2}", or needs help {planning/designing/
  defining} {subject} from scratch.
argument-hint: "<{initial-topic-or-description}>"
---

# {Skill Title}

{Goal in one sentence}. Gather requirements through structured questions before producing any output.

> **Gate**: Do NOT generate {output} until Phase {N} is complete. If the user asks to skip ahead, explain why the information is needed and offer to abbreviate the question set.

## Phase 1: {Discovery Topic}

**Goal**: {What you learn in this phase}

Ask (skip questions already answered in the user's initial request):

- {Question 1}
- {Question 2}
- {Question 3}

Use AskUserQuestion when asking in Cowork mode. Do not include "None" or "Other" as options — AskUserQuestion provides free-text input by default.

Summarize your understanding and confirm before proceeding to Phase 2.

**Output**: {What you know after this phase}

## Phase 2: {Analysis/Planning Topic}

**Goal**: {What you learn or decide in this phase}

{Steps to take or questions to ask}

Confirm before proceeding to Phase 3.

**Output**: {What you produce after this phase}

## Phase {N}: Generate

**Goal**: Produce the final {output} based on all gathered information.

{Instructions for generating the output}

Load `references/{template-file}.md` for the output template. Fill in all placeholder values with the information gathered in previous phases.

## Output Format

~~~markdown
{Output template or example}
~~~
```

---

## Template 5: Phased Pipeline

Use when the skill orchestrates a strict multi-step workflow with approval gates.

```markdown
---
name: {skill-name}
description: >
  Run the {workflow-name} workflow. Use when the user wants to "{trigger-1}",
  "{trigger-2}", or needs to complete {goal} through a structured process.
---

# {Skill Title}

{Goal in one sentence}. Follows a {N}-phase process with checkpoints to ensure quality at each step.

## Overview

1. **{Phase 1 Name}** — {one-line description}
2. **{Phase 2 Name}** — {one-line description}
3. **{Phase 3 Name}** — {one-line description}
{Add more phases as needed}

## Phase 1: {Name}

**Goal**: {What this phase accomplishes}

Steps:
1. {Action}
2. {Action}
3. {Action}

**Output**: {What is produced at the end of this phase}

> **Gate**: Present the {output} to the user. Ask if they approve or want adjustments before proceeding to Phase 2.

## Phase 2: {Name}

**Goal**: {What this phase accomplishes}

{Load `references/{relevant-file}.md` if detailed criteria are needed.}

Steps:
1. {Action}
2. {Action}

**Output**: {What is produced}

> **Gate**: {Condition that must be met. May be a user approval or a completion check.}

## Phase {N}: {Name}

**Goal**: Deliver the final {output}.

Steps:
1. {Action}
2. {Action}

**Output**: {Final deliverable}

## If Connectors Available

If **~~{category}** is connected:
- {Phase N}: {What the connector enables at this step}
```

---

## Common Optional Sections

Add these to any template as needed:

### Connector Section
```markdown
## If Connectors Available

If **~~{category}** is connected:
- {Capability 1}
- {Capability 2}

If **~~{other-category}** is connected:
- {Capability}
```

### Additional Resources Section
```markdown
## Additional Resources

- **`references/{file}.md`** — {What it contains and when to load it}
- **`references/{file2}.md`** — {What it contains and when to load it}
```

### Tips Section
```markdown
## Tips

1. **{Tip title}** — {Tip detail}
2. **{Tip title}** — {Tip detail}
3. **{Tip title}** — {Tip detail}
```

---

## Post-Generation Quality Checklist

Verify every generated SKILL.md before delivering to the user:

- [ ] `name` field in frontmatter is kebab-case and matches the skill directory name
- [ ] `description` is written in third-person ("Help users..." or "This skill...")
- [ ] `description` includes at least 3 trigger phrases wrapped in double quotes
- [ ] `argument-hint` is present only if the skill accepts a direct argument
- [ ] Body is written in imperative/infinitive style ("Parse the file" not "You should parse")
- [ ] Body content is instructions FOR Claude, not documentation FOR the user
- [ ] Body is under 3,000 words (ideally 1,500-2,000)
- [ ] Detailed content is in `references/` files, not in the body
- [ ] Output format template is included (if the skill produces structured output)
- [ ] Connector references use `~~category` syntax (not specific tool names)
- [ ] Gate rules are present for Guided Discovery and Phased Pipeline patterns
- [ ] `AskUserQuestion` is mentioned when the skill runs interactive phases in Cowork
- [ ] `${CLAUDE_PLUGIN_ROOT}` is used for any intra-plugin path references
