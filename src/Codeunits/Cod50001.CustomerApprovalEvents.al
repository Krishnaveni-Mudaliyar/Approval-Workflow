codeunit 50001 "Customer Approval Events"
{
    // ---------- Send Customer for Approval ----------
    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Approvals Mgmt.",
        OnSendCustomerForApproval,
        '',
        false,
        false)]
    local procedure OnSendCustomerForApproval(var Customer: Record Customer)
    var
        CustomerApprovalManagement: Codeunit "Customer Approval Management";
    begin
        CustomerApprovalManagement.ValidateBeforeApproval(Customer);
        CustomerApprovalManagement.SetPending(Customer);
    end;

    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Approvals Mgmt.",
        OnApproveApprovalRequest,
        '',
        false,
        false)]
    local procedure OnApproveApprovalRequest(
        var ApprovalEntry: Record "Approval Entry")
    var
        Customer: Record Customer;
        RecRef: RecordRef;
        CustomerApprovalManagement: Codeunit "Customer Approval Management";
        ApprovalMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalEntry."Table ID" <> Database::Customer
        then
            exit;

        if ApprovalMgmt.HasOpenApprovalEntries(ApprovalEntry."Record ID to Approve")
        then
            exit;

        if not RecRef.Get(ApprovalEntry."Record ID to Approve")
        then
            exit;

        RecRef.SetTable(Customer);
        CustomerApprovalManagement.SetReleased(Customer);
    end;

    // ---------- Reject Approval Request ----------    
    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Approvals Mgmt.",
        OnRejectApprovalRequest,
        '',
        false,
        false)]
    local procedure OnRejectApprovalRequest(
        var ApprovalEntry: Record "Approval Entry")
    var
        Customer: Record Customer;
        RecRef: RecordRef;
        CustomerApprovalManagement: Codeunit "Customer Approval Management";
    begin
        if ApprovalEntry."Table ID" <> Database::Customer
        then
            exit;

        if not RecRef.Get(ApprovalEntry."Record ID to Approve")
        then
            exit;

        RecRef.SetTable(Customer);
        CustomerApprovalManagement.SetOpen(Customer);
    end;

    // ---------- Release Document ----------
    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Workflow Response Handling",
        OnReleaseDocument,
        '',
        false,
        false)]
    local procedure OnReleaseDocument(
        RecRef: RecordRef;
        var
        Handled: Boolean)
    var
        Customer: Record Customer;
        CustomerApprovalManagement: Codeunit "Customer Approval Management";
    begin
        if Handled then
            exit;

        if RecRef.Number <> Database::Customer then
            exit;

        RecRef.SetTable(Customer);
        CustomerApprovalManagement.SetReleased(Customer);
        RecRef.GetTable(Customer);
        Handled := true;
    end;

    // ---------- Open Document ----------
    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Workflow Response Handling",
        OnOpenDocument,
        '',
        false,
        false)]
    local procedure OnOpenDocument(
        RecRef: RecordRef;
        var
        Handled: Boolean)
    var
        Customer: Record Customer;
        CustomerApprovalManagement: Codeunit "Customer Approval Management";
    begin
        if Handled then
            exit;

        if RecRef.Number <> Database::Customer then
            exit;

        RecRef.SetTable(Customer);
        CustomerApprovalManagement.SetOpen(Customer);
        RecRef.GetTable(Customer);
        Handled := true;
    end;
}