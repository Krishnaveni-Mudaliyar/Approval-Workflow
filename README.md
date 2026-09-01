# Approval-Workflow

An AL extension for Microsoft Dynamics 365 Business Central that adds a Customer Master approval workflow: an **Approval Status** field, **Reopen**/**Release** actions, PAN No. uniqueness validation, mandatory-field enforcement, and automatic syncing of the **Blocked** field with approval state.

- **Publisher:** Krishnaveni Mudaliyar
- **App ID:** `7ef7bf21-c6e4-476a-b582-212a270ba232`
- **Object ID range:** 50000–50200
- **Target application:** Business Central 28.0
- **Runtime:** 17.0

## Prerequisites

1. Configure the standard **Customer Approval Workflow** in Business Central (Workflows page) before installing/using this extension, so the "send for approval" path has a workflow to run against.

## What's Included

| Object | ID | Purpose |
|---|---|---|
| `Customer Approval Status` (Enum) | 50000 | Values: `Open`, `Pending for Approval`, `Released` |
| `Customer Extension` (Table Ext.) | 50000 | Adds `Approval Status` and `PAN No` fields to Customer; sets a new customer to `Open` / `Blocked = All` on insert; validates PAN No. uniqueness |
| `CustomerCardExt` (Page Ext.) | 50000 | Adds `Approval Status` and `PAN No` fields to the Customer Card; adds **Reopen** and **Release** actions under Request Approval |
| `Customer Approval Management` (Codeunit) | 50000 | Core logic: mandatory-field validation, Release/Reopen procedures, status transitions (`SetOpen`/`SetPending`/`SetReleased`), workflow-enabled check |
| `Customer Approval Events` (Codeunit) | 50001 | Event subscribers wiring the above into BC's standard approval/workflow events |
| `Customer Approval Mgt. Tests` (Codeunit, Test) | 50002 | Automated tests covering all functional rules below |

## Functional Behavior

### Approval Status field
Added to the Customer Card, with values `Open`, `Pending for Approval`, `Released`.

### Reopen and Release actions
Added under **Request Approval** on the Customer Card. Both actions show a confirmation dialog before completing.

- **Release** — only succeeds if the Customer Approval Workflow is **not enabled** for the customer (checked via `Workflow Management` and `Approvals Mgmt.`). If the workflow is enabled, the user is told to send the customer for approval instead.
- **Reopen** — only succeeds when the current Approval Status is **Released**; otherwise an error is raised.

### Blocked field sync
- `Open` → `Blocked = All`
- `Pending for Approval` → `Blocked = All`
- `Released` → `Blocked = " "` (blank)

A new customer defaults to `Open` / `Blocked = All` on insert.

### PAN No. uniqueness
The `PAN No` field (added to Customer) validates that no other customer record has the same value; a duplicate raises an error naming the conflicting customer.

### Mandatory fields
Before a customer can be **released** or **sent for approval**, the following must be filled:
- Name
- Customer Posting Group
- Gen. Bus. Posting Group
- VAT Bus. Posting Group
- PAN No.

### Workflow integration
`Customer Approval Events` subscribes to:
- `Approvals Mgmt.::OnSendCustomerForApproval` — validates mandatory fields, sets status to `Pending for Approval`
- `Approvals Mgmt.::OnApproveApprovalRequest` — sets status to `Released` once all open approval entries are cleared
- `Approvals Mgmt.::OnRejectApprovalRequest` — sets status back to `Open`
- `Workflow Response Handling::OnReleaseDocument` / `OnOpenDocument` — sets status to `Released` / `Open` respectively

## Testing

`Customer Approval Mgt. Tests` (Codeunit 50002) covers:
- New customer defaults to Open / Blocked = All
- Status transitions correctly pair Approval Status with Blocked
- Duplicate PAN No. is rejected
- Release fails when mandatory fields are missing
- Release succeeds when the workflow is disabled and fields are complete
- Reopen succeeds only from Released, and fails from Open or Pending

Run these from the Test Tool page in your BC sandbox.

## Setup

1. Publish the extension (`Krishnaveni Mudaliyar_Approval-Workflow_1.0.0.0.app`) to your Business Central environment.
2. Set up the Customer Approval Workflow under **Workflows**.
3. Open a Customer Card and confirm the **Approval Status** and **PAN No** fields, and the **Reopen**/**Release** actions, appear under Request Approval.
4. Fill in the mandatory fields (Name, Customer Posting Group, Gen. Bus. Posting Group, VAT Bus. Posting Group, PAN No) before releasing or sending a customer for approval.

## Project Structure

```
Approval-Workflow/
├── app.json
├── src/
│   ├── Codeunits/
│   │   ├── Cod50000.CustomerApprovalManagement.al
│   │   └── Cod50001.CustomerApprovalEvents.al
│   ├── Enums/
│   │   └── Enum50000.CustomerApprovalStatus.al
│   ├── Page Ext/
│   │   └── Pag-Ext50000.CustomerCardExt.al
│   ├── Table Ext/
│   │   └── Tab-Ext50000.CustomerExtension.al
│   └── Test/
│       └── Cod50002.CustomerApprovalMgtTests.al
```
