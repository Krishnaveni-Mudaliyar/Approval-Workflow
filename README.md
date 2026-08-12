# Customer Master Approval Workflow

A Business Central AL extension that adds a controlled approval lifecycle to the standard Customer Card, integrated with BC's native Approval Workflow engine.

## Overview

Every new customer starts **Open** and is blocked from use. Depending on whether a Customer Approval Workflow is enabled, a customer is either sent through BC's standard approval process or released directly, ultimately reaching **Released** status — at which point it becomes usable.

```
Open ──(Send Approval Request)──▶ Pending for Approval ──(Approved)──▶ Released
Open ──(Release, workflow off)───────────────────────────────────────▶ Released
Released ──(Reopen)──▶ Open
```

## Requirement

1. Configure the standard approval workflow for customers.
2. Add an **Approval Status** field to the Customer Card: `Open` / `Pending for Approval` / `Released`.
3. Add **Reopen** and **Release** actions under **Request Approval**, each with a confirmation prompt.
4. **Release** only works if the Customer Approval Workflow is **not** enabled.
5. **Reopen** only works when status is `Released`; otherwise an error is shown.
6. Status `Open` → `Blocked = All`.
7. Status `Released` → `Blocked = blank`.
8. **PAN No.** must be unique across customers.
9. Mandatory fields must be validated before **Release** or **Send Approval Request**.

## Objects

| Object | ID | Purpose |
|---|---|---|
| `Customer Approval Status` (Enum) | 50000 | `Open`, `Pending for Approval`, `Released` |
| `CustomerCardExt` (Page Ext) | 50000 | Adds Approval Status/PAN fields; adds Reopen and a custom Send Approval Request/Release action under **Request Approval** |
| `CustomerExtension` (Table Ext) | 50000 | Adds Approval Status + PAN No. fields; PAN uniqueness on `OnValidate`; defaults new customers to `Open` / `Blocked = All` on `OnInsert` |
| `Customer Approval Management` (Codeunit) | 50000 | Core logic: Release, Reopen, status transitions (`SetOpen`/`SetPending`/`SetReleased`), mandatory-field validation, workflow-enabled check |
| `Customer Approval Events` (Codeunit) | 50001 | Subscribes to BC's approval engine: sets `Pending` on send, `Released` on approval, `Open` on rejection |
| `Customer Appr. Mgt. Tests` (Codeunit) | 50002 | Automated test coverage (see below) |

## How Release is gated (point 4)

`Release` is blocked whenever a Customer Approval Workflow applies to the record. This is checked two ways, combined:

- **`WorkflowManagement.CanExecuteWorkflow`** — is there an enabled workflow that could still fire the send-for-approval event for this customer.
- **`ApprovalsMgmt.HasOpenApprovalEntries`** — does this customer already have an approval in flight. This second check exists because `CanExecuteWorkflow` alone returns `false` once a customer is already `Pending for Approval` (nothing *new* would fire), which would otherwise let `Release` slip through mid-approval.

## How approval outcomes sync back (points 6/7)

Customer/Vendor/Item approvals in standard BC do **not** use the `Release Document` / `Open Document` responses (those are for Sales/Purchase documents only). Instead, `Cod50001` subscribes directly to `Codeunit "Approvals Mgmt."`'s `OnApproveApprovalRequest` and `OnRejectApprovalRequest` events, filtered to `Table ID = Database::Customer`. On approval, `HasOpenApprovalEntries` is checked first so a multi-level approval chain only resolves to `Released` once every level has signed off.

## Setup (not code — done inside Business Central)

1. **Approval User Setup** — add a line per user with an `Approver ID` pointing to who approves them. Keep the chain single-level for straightforward testing (no unintended escalation).
2. **Workflows** → Create Workflow from Template → the Customer Approval Workflow template (`MS-CUSTAPW-xx`). Set `Enabled = Yes`.
3. Review the template's **Then Response** steps — the default "Add/Remove record restriction" responses are **not supported for the Customer table** in standard BC and will error on approval; remove them. This extension manages `Blocked` itself via `SetPending`/`SetReleased`/`SetOpen`, so they aren't needed.
4. **Notification Setup** per user (optional) — Type = Approval, Method = Note, Occurrence = Instantly, so approvers see requests promptly.

## Testing

`Cod50002` covers, without needing the BC UI or a real approver login:

- New customer defaults to `Open` / `Blocked = All`
- `SetOpen` / `SetPending` / `SetReleased` correctly pair Approval Status with Blocked
- PAN No. duplicate rejection
- Release fails when mandatory fields are missing
- Release succeeds when workflow is disabled and fields are complete
- Reopen succeeds when Released; fails when Open or Pending

Scenarios that need the real workflow engine and a second user login (not covered by the automated tests):

- Release blocked at `Pending for Approval` (workflow enabled)
- Full approval → `Released`, including multi-level chains
- Rejection → `Open`
- End-to-end: create → mandatory fields → Send Approval Request → approve → Reopen

## Known limitations

- **Cancel Approval Request** (a standard BC action) is not explicitly handled — `Approval Status` will not automatically revert if a request is cancelled rather than approved/rejected. Not part of the original 9-point requirement.
- The extension assumes the standard `PAN No` field added by this extension (or your organization's chosen PAN field, e.g. the India-localization `P.A.N. No.` field if applicable) is the single source of truth — verify which field your mandatory-field checks and uniqueness validation reference matches what's shown on the Customer Card.
- `IsApprovalWorkflowEnabled` and the approval event subscribers depend on standard BC procedure names (`RunWorkflowOnSendCustomerForApprovalCode`, `OnApproveApprovalRequest`, `OnRejectApprovalRequest`, etc.) — confirm these resolve against your target BC version's symbols before publishing to a new environment.
