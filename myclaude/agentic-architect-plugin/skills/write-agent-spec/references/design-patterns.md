# Claude Code Agent Skill Design Patterns

Five proven patterns for structuring Claude Code SKILL.md files. These are adapted from general agent skill design principles, reframed for Claude Code's specific architecture: file-based markdown skills, three-layer progressive disclosure, `~~category` connectors, and `AskUserQuestion` for structured interaction.

Load this reference during Phase 2 (Pattern Selection) to evaluate which pattern fits the user's use case.

---

## Pattern 1: Context Loader

**Adapted from**: Tool Wrapper

### Purpose

Make Claude an on-demand expert for a specific domain, library, framework, or API. The skill loads relevant documentation into context only when the user needs it, keeping the context window clean otherwise.

### When to Use

- The skill's primary value is giving Claude deep knowledge of something specific
- Users ask questions like "How do I do X in [library]?" or "What's the convention for Y?"
- The knowledge is too detailed to keep in the system prompt permanently
- The skill wraps internal coding guidelines, API conventions, or domain expertise

### Claude Code Implementation

**Frontmatter**: Include domain keywords and library names in the `description` trigger phrases so the skill activates when those topics appear.

**Body**: Keep short. Provide a domain overview and explicit instructions for when to load each reference file:

```
When the user asks about authentication flows, read `references/auth-patterns.md`.
When the user asks about rate limiting, read `references/rate-limiting.md`.
```

**`references/` directory**: Store the detailed domain documentation here. Organize by topic — one file per major concept. These files can be as long as needed; they only load when explicitly referenced.

### Progressive Disclosure

```
Metadata (always loaded)     → Domain name + trigger keywords
SKILL.md body (on trigger)   → Domain overview, key concepts, load instructions
references/ (on demand)      → Full API docs, conventions, examples
```

### Example Structure

```
nextflow-development/
├── SKILL.md                    # Overview + "when to read X, load references/X.md"
└── references/
    ├── pipeline-patterns.md    # Core pipeline design patterns
    ├── executor-config.md      # Executor configuration reference
    ├── error-handling.md       # Error handling conventions
    └── testing-patterns.md     # Testing approaches
```

### Key Directives in Body

```markdown
Load `references/pipeline-patterns.md` at the start of any session involving
pipeline design. Load `references/error-handling.md` when the user reports
workflow failures or asks about retry logic.
```

### Anti-Pattern

Do not use Context Loader if the skill needs to produce a structured deliverable — that is a Structured Generator. Do not use it if the skill needs to evaluate existing work — that is a Checklist Reviewer.

---

## Pattern 2: Structured Generator

**Adapted from**: Generator

### Purpose

Produce consistent, well-formatted output from a template. Every run of this skill should generate the same structure with different content filled in, enforcing standards across documents, reports, code artifacts, or configurations.

### When to Use

- The skill's output has a fixed structure (sections, fields, format)
- Inconsistent output is a real problem (different formats on every run)
- Users provide input (a topic, a codebase, a PR) and expect a standardized document back
- Examples: ADRs, PR descriptions, incident reports, API documentation, onboarding guides, commit messages

### Claude Code Implementation

**Body**: Embed the output template directly as a code fence. This is the core of the skill — Claude fills in the template with the user's content.

**`$ARGUMENTS` / `@$1`**: Accept user input directly. Use `$ARGUMENTS` for a topic or description; use `@$1` to inline a file's contents when the skill needs to read code, a document, or a config.

**`references/` directory**: Store style guides, tone rules, or complex formatting conventions here. Load them when the user's context requires it.

### Example Output Template (in body)

```markdown
## Output Format

Generate the following structure:

~~~markdown
# ADR-[number]: [Title]

**Status:** Proposed
**Date:** [Date]
**Deciders:** [Names]

## Context
[What forces are at play? What is the situation?]

## Decision
[What change is being proposed?]

## Consequences
- [What becomes easier]
- [What becomes harder]
~~~
```

### Connector Integration

```markdown
If **~~knowledge base** is connected:
- Search for prior ADRs to determine the next sequential number
- Check for related decisions that this one supersedes
```

### Anti-Pattern

Do not use Structured Generator if the output structure varies significantly based on input — use Phased Pipeline instead, which can adapt structure per step. Do not use it if the skill needs to gather extensive requirements first — combine with Guided Discovery.

---

## Pattern 3: Checklist Reviewer

**Adapted from**: Reviewer

### Purpose

Evaluate existing content against a defined set of criteria, grouping findings by severity. The checklist is stored in `references/` so it can be swapped without changing the skill logic.

### When to Use

- The skill reviews, audits, or grades something that already exists
- Users submit code, a document, a PR, a config, or a design for evaluation
- The skill needs to produce a structured verdict (not just open-ended feedback)
- Examples: code review, PR review, contract review, security audit, accessibility audit, content quality check

### Claude Code Implementation

**Body**: Define the review dimensions and output format. Keep the specific checklist criteria in `references/`.

**`@$1` / `~~source control`**: Accept the content to review via file reference or by pulling from a connected tool.

**`references/` directory**: Store the detailed checklist. By swapping the checklist file (e.g., replacing a Python style guide with an OWASP security checklist), you get a completely different specialized audit using the same skill structure.

### Review Dimension Structure

```markdown
## Review Dimensions

### Security
- [High-level categories, not detailed rules]

### Performance
- [High-level categories]

### Correctness
- [High-level categories]
```

### Output Format

```markdown
## Output

~~~markdown
## Review: [Subject]

### Summary
[1-2 sentence overview]

### Findings

| Severity | Category | Finding | Recommendation |
|----------|----------|---------|----------------|
| 🔴 Critical | Security | [description] | [fix] |
| 🟡 Warning  | Perf     | [description] | [fix] |
| 🔵 Info     | Style    | [description] | [fix] |

### Verdict
[Approve / Request Changes / Needs Discussion]
~~~
```

### Connector Integration

```markdown
If **~~source control** is connected:
- Pull the PR diff automatically; no need for the user to paste code
- Check CI status alongside the manual review

If **~~knowledge base** is connected:
- Load team coding standards and compare against them
```

### Anti-Pattern

Do not use Checklist Reviewer if the skill also needs to fix what it finds — that becomes a Phased Pipeline (review → fix → verify). Do not use it for open-ended analysis without defined criteria — that is better served by a Structured Generator producing an analysis report.

---

## Pattern 4: Guided Discovery

**Adapted from**: Inversion

### Purpose

The agent interviews the user before taking action. Rather than guessing or generating immediately with incomplete context, this pattern collects requirements through structured questioning, then produces a high-quality output only after the picture is complete.

### When to Use

- The skill cannot produce good output without understanding the user's specific context
- The domain has many variables that significantly affect the output (tech stack, team size, constraints, preferences)
- Premature generation would produce generic, useless output
- Examples: plugin creation, system design, project planning, onboarding customization, skill spec writing (this skill itself)

### Claude Code Implementation

**Gate rule**: State explicitly at the top of the relevant section that output must not be generated until all required phases are complete.

**AskUserQuestion**: Use this tool for all questions in Cowork mode. It presents structured options with a Skip button and free-text fallback. Do NOT include "None" or "Other" as explicit options — AskUserQuestion provides those implicitly.

**Phased questions**: Group related questions into phases. Present each phase's questions together. Confirm understanding after each phase before moving on.

**Skip logic**: If the user's initial request already answers some questions, skip them. State which questions are being skipped and why.

### Gate Rule Syntax

```markdown
> **Gate**: Do NOT generate [output] until all Phase [N] questions are answered.
> If the user asks to skip ahead, explain why the information is needed and
> offer an abbreviated version of the question set instead.
```

### Phase Structure

```markdown
### Phase 1: [Discovery Topic]

**Goal**: [What you're learning in this phase]

Ask (skip if already answered):
- [Question 1]
- [Question 2]

Summarize understanding and confirm before proceeding to Phase 2.

**Output**: [What you know after this phase]
```

### Combination with Structured Generator

Guided Discovery is almost always combined with Structured Generator in the final phase:

```
Phase 1-N: Guided Discovery (questions)
Phase N+1: Structured Generator (output)
```

### Anti-Pattern

Do not use Guided Discovery for skills where a single command provides all needed context. If the user says `/code-review path/to/file.py`, there is nothing to discover — use Checklist Reviewer directly. Do not ask questions that can be inferred from the context.

---

## Pattern 5: Phased Pipeline

**Adapted from**: Pipeline

### Purpose

Orchestrate a strict, sequential workflow where each step depends on the previous one, and some steps require user confirmation before proceeding. Prevents skipped steps and ensures complex tasks are completed correctly.

### When to Use

- The task has a defined sequence that cannot be reordered
- Some steps produce artifacts that feed into the next step
- Certain steps require user sign-off before continuing (e.g., review generated content, confirm a destructive action)
- Examples: incident response, deployment workflows, data migration, content production pipeline, plugin creation

### Claude Code Implementation

**Body**: Organize as numbered phases. Each phase has a Goal, Steps, Output, and optionally a Gate.

**AskUserQuestion at gates**: Use for approval checkpoints. Present what was produced, ask if the user wants to proceed, adjust, or stop.

**References loaded per step**: Load different `references/` files at specific steps to keep context lean. A phase that generates documentation might load `references/style-guide.md`; a phase that deploys might load `references/deployment-checklist.md`.

**Rollback instructions**: Include in relevant phases when actions are hard to reverse.

### Phase Structure

```markdown
### Phase [N]: [Name]

**Goal**: [What this phase accomplishes]

Steps:
1. [Action]
2. [Action]
3. [Action]

**Output**: [What is produced at the end of this phase]

> **Gate**: [Condition that must be met before proceeding to Phase N+1]
> Ask the user to confirm before continuing.
```

### Gate Conditions

Gates can be:
- **Approval gates**: "Show the user the generated [artifact] and ask if they approve before proceeding."
- **Completion gates**: "Do not proceed until [specific output] exists."
- **Quality gates**: "Verify [condition] before Phase N+1."

### Connector Integration

Different connectors may be used at different phases:

```markdown
In Phase 2, if **~~source control** is connected, commit the generated files.
In Phase 4, if **~~project tracker** is connected, create follow-up tickets.
```

### Anti-Pattern

Do not use Phased Pipeline if the steps can be done in any order — use Checklist Reviewer or Structured Generator instead. Do not create artificial gates that add friction without value. Each gate should correspond to a real decision point where user input changes the next step.

---

## Pattern Combinations

Patterns are not mutually exclusive. Common combinations:

| Combination | When to Use |
|-------------|-------------|
| Guided Discovery + Structured Generator | Need requirements before generating a consistent artifact |
| Phased Pipeline + Checklist Reviewer | Multi-step workflow that includes a review checkpoint |
| Context Loader + Structured Generator | Load domain expertise, then generate domain-specific output |
| Phased Pipeline + Guided Discovery | Complex workflow where each phase needs clarifying questions |

---

## Decision Tree

```
Does the skill primarily load reference docs for a specific domain?
  YES → Context Loader
  NO  →
        Does it produce a structured artifact with a fixed format?
          YES →
                Does it need to interview the user before generating?
                  YES → Guided Discovery + Structured Generator
                  NO  → Structured Generator
          NO  →
                Does it evaluate or score existing content against criteria?
                  YES → Checklist Reviewer
                  NO  →
                        Does it have ordered steps with approval gates?
                          YES → Phased Pipeline
                          NO  → Reconsider — most skills fit one of these patterns.
                                A skill that does none of these may need to be split
                                into two skills.
```
