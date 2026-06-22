# ACI History

This directory tracks **Approved Change Instructions (ACIs)** issued for the TAIG Service Portal (TSP) and links to their completion reports.

## Purpose

- Record which ACIs have been issued, started, and completed
- Provide a single reference for project governance and change scope
- Link each ACI to its completion report in `/docs/reports`

## ACI Index

| ACI     | Title              | Status    | Completion Report                                      |
|---------|--------------------|-----------|--------------------------------------------------------|
| ACI-001 | PA Foundation      | Completed | [ACI-001-completion-report.md](../reports/ACI-001-completion-report.md) |
| ACI-002 | MVP Implementation | Completed | [ACI-002-completion-report.md](../reports/ACI-002-completion-report.md) |
| ACI-003 | DevOps to PA       | Completed | [ACI-003-completion-report.md](../reports/ACI-003-completion-report.md) |
| ACI-004 | Docker Hub Publish | Completed | [ACI-004-completion-report.md](../reports/ACI-004-completion-report.md) |

## Adding a New ACI

When a new ACI is issued:

1. Add a row to the index table above with status `Issued` or `In Progress`
2. Upon completion, create a report in `/docs/reports/ACI-XXX-completion-report.md`
3. Update the status to `Completed` and link the report

## Report Naming Convention

```
/docs/reports/ACI-XXX-completion-report.md
```

Where `XXX` is the three-digit ACI number (e.g. `ACI-002-completion-report.md`).
