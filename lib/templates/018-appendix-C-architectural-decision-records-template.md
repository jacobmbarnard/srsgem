# Appendix C. Architectural Decision Records

*Architectural Decision Records (ADRs) document important architectural decisions made during the development of this system, including the context, decision, and consequences of each choice.*

> **Note:** Guidance below describes how to manage ADRs in the `ADRs/` folder. Individual ADR files live outside this appendix and are not included in the SRS build unless you add them here manually.

## Directory Structure

ADRs are organized in the `ADRs/` folder in your project's working directory, with subfolders corresponding to ADR status:

```
ADRs/
├── proposed/
│   └── ADR-XXX-[title].md
├── accepted/
│   └── ADR-001-[title].md
├── deprecated/
│   └── ADR-005-[title].md
└── superseded/
    └── ADR-003-superseded-by-ADR-007-[title].md
```

**Status definitions:**

- **proposed/** — New ADRs under consideration, not yet approved
- **accepted/** — ADRs reviewed and approved by the architecture team
- **deprecated/** — ADRs no longer relevant but retained for historical context
- **superseded/** — ADRs replaced by newer decisions (reference the newer ADR)

## Naming Convention

```
ADR-###-[brief-descriptive-title].md
```

**Example:** `ADR-001-use-postgresql-for-primary-database.md`

## Fill-In Template (based on MADR 4.0.0)

Copy this template into the appropriate `ADRs/` subfolder. Use `##` as the top heading inside each ADR file.

```markdown
## ADR-XXX: [Brief Title of Decision]

**Date:** YYYY-MM-DD

**Status:** Proposed | Accepted | Deprecated | Superseded

### Context and Problem Statement

<!-- Describe the issue or problem that motivated this decision. -->

### Decision Drivers

- [Driver 1]
- [Driver 2]

### Considered Options

#### Option 1: [Name]

<!-- Description, pros, and cons. -->

#### Option 2: [Name]

<!-- Description, pros, and cons. -->

### Decision Outcome

**Chosen option:** "[Option name]"

**Rationale:**

<!-- Why this option was selected. -->

**Consequences:**

- **Good:** <!-- positive outcomes -->
- **Bad:** <!-- negative outcomes -->
- **Neutral:** <!-- other outcomes -->

### Links

- Related ADRs: <!-- links if applicable -->
- References: <!-- external documentation -->
```

## Example Skeleton

The following shows the expected shape of an accepted ADR. Copy `ADRs/proposed/ADR-001-[title].md` (created at project init) as a starting point.

#### ADR-001: [Brief Title of Decision]

**Date:** YYYY-MM-DD

**Status:** Accepted

##### Context and Problem Statement

<!-- TODO: Describe the problem being solved. -->

##### Decision Drivers

- <!-- TODO: Driver 1 -->

##### Considered Options

###### Option 1: [Name]

<!-- TODO: Description, pros, and cons. -->

##### Decision Outcome

**Chosen option:** "[Option name]"

**Rationale:**

<!-- TODO: Explain the decision. -->

**Consequences:**

- **Good:** <!-- TODO -->
- **Bad:** <!-- TODO -->

##### Links

- Related ADRs: <!-- TODO -->
- References: <!-- TODO -->

When an ADR is superseded, move it to `ADRs/superseded/`, update its status, and link to the replacing ADR (for example, `Superseded by ADR-008`).

## Management Workflow

1. **Create** — New ADRs start in `ADRs/proposed/`
2. **Review** — Architecture team reviews the proposed ADR
3. **Approve** — Move accepted ADRs to `ADRs/accepted/`
4. **Deprecate** — Move obsolete ADRs to `ADRs/deprecated/`
5. **Supersede** — Move replaced ADRs to `ADRs/superseded/` and reference the new ADR

## ADR Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| ADR-001 | [Title] | Proposed | [Date] |

## Best Practices

- Assign sequential numbers to new ADRs
- Create ADRs during design, before implementation
- Keep ADRs concise but complete
- Get architecture team approval before moving to `accepted/`
- Link related ADRs and external references
- Retain superseded and deprecated ADRs for historical context

## References

- [MADR 4.0.0 specification](https://adr.github.io/madr/) — MADR templates are typically [CC0](https://creativecommons.org/publicdomain/zero/1.0/)
- [Architectural Decision Records guide](https://adr.github.io/)
- [srsgem project repository](https://github.com/jacobmbarnard/srsgem) — licensed under [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)