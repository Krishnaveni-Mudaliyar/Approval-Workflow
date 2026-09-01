codeunit 50000 "Customer Approval Management"
{
    // ---------- Validation ----------
    procedure ValidateBeforeApproval(Customer: Record Customer)
    begin
        ValidateMandatoryFields(Customer);
    end;

    procedure ValidateBeforeRelease(Customer: Record Customer)
    begin
        ValidateMandatoryFields(Customer);
    end;

    // ---------- Release ----------
    procedure ReleaseCustomer(var Customer: Record Customer)
    begin
        ValidateBeforeRelease(Customer);

        // ---------- Customer Approval Workflow check ----------
        if IsApprovalWorkflowEnabled(Customer) then
            Error(
                'Customer Approval Workflow is enabled. The customer must be sent for approval instead of being released directly.');

        ValidateBeforeRelease(Customer);

        if not Confirm(
            'Are you sure you want to release customer %1?',
            false,
            Customer."No.")
        then
            exit;

        SetReleased(Customer);
    end;

    // ---------- Reopen ----------
    procedure ReopenCustomer(var Customer: Record Customer)
    begin
        if Customer."Approval Status" <> "Customer Approval Status"::Released
        then
            Error(
                'Only customers with Approval Status "Released" can be reopened.');

        if not Confirm(
            'Are you sure you want to reopen customer %1?',
            false,
            Customer."No.")
        then
            exit;

        SetOpen(Customer);
    end;

    // ---------- Status Transitions ----------
    procedure SetOpen(var Customer: Record Customer)
    begin
        Customer.Validate(
            "Approval Status",
            "Customer Approval Status"::Open);

        Customer.Validate(
            Blocked,
            Customer.Blocked::All);

        Customer.Modify(true);
    end;

    procedure SetPending(var Customer: Record Customer)
    begin
        Customer.Validate(
            "Approval Status",
            "Customer Approval Status"::"Pending for Approval");

        Customer.Validate(
            Blocked,
            Customer.Blocked::All);

        Customer.Modify(true);
    end;

    procedure SetReleased(var Customer: Record Customer)
    begin
        Customer.Validate(
            "Approval Status",
            "Customer Approval Status"::Released);

        Customer.Validate(
            Blocked,
            Customer.Blocked::" ");

        Customer.Modify(true);
    end;

    // ---------- Mandatory Fields ----------
    local procedure ValidateMandatoryFields(Customer: Record Customer)
    begin
        if Customer.Name = '' then
            Error(
                'Name must be filled before the customer can be released or sent for approval.');

        if Customer."Customer Posting Group" = '' then
            Error(
                'Customer Posting Group must be filled before the customer can be released or sent for approval.');

        if Customer."Gen. Bus. Posting Group" = '' then
            Error(
                'Gen. Bus. Posting Group must be filled before the customer can be released or sent for approval.');

        if Customer."VAT Bus. Posting Group" = '' then
            Error(
                 'VAT Bus. Posting Group must be filled before the customer can be released or sent for approval.');

        if Customer."PAN No" = '' then
            Error(
               'PAN No. must be filled before the customer can be released or sent for approval.');
    end;

    //  ---------- Workflow check ----------
    local procedure IsApprovalWorkflowEnabled(Customer: Record Customer): Boolean
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if WorkflowManagement.CanExecuteWorkflow(
                Customer,
                WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode())
        then
            exit(true);

        exit(ApprovalsMgmt.HasOpenApprovalEntries(Customer.RecordId));
    end;
}