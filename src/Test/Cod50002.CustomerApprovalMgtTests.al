codeunit 50002 "Customer Approval Mgt. Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        CustomerApprovalManagement: Codeunit "Customer Approval Management";
        MandatoryFieldErr: Label 'must be filled before the customer can be released or sent for approval', Locked = true;
        WorkflowEnabledErr: Label 'Customer Approval Workflow is enabled', Locked = true;
        ReopenOnlyReleasedErr: Label 'Only customers with Approval Status "Released" can be reopened', Locked = true;
        PanDuplicateErr: Label 'already exists for customer', Locked = true;

    // ---------- Status defaults on Insert ----------

    [Test]
    procedure NewCustomerDefaultsToOpenAndBlockedAll()
    var
        Customer: Record Customer;
    begin
        // When a new customer is created
        CreateBasicCustomer(Customer);

        //Then it defaults to open and blocked = all
        Customer.Get(Customer."No.");
        Assert.AreEqual(Customer."Approval Status"::Open, Customer."Approval Status", 'New Customer should default to open.');
        Assert.AreEqual(Customer.Blocked::All, Customer.Blocked, 'New Customer should default to Blocked = All.');
    end;

    // ---------- SetOpen / SetPending / SetReleased pair Approval Status with Blocked ----------

    [Test]
    procedure SetPendingSetsBlockedAll()
    var
        Customer: Record Customer;
    begin
        CreateReadyCustomer(Customer);

        CustomerApprovalManagement.SetPending(Customer);

        Customer.Get(Customer."No.");

        Assert.AreEqual(
            Customer."Approval Status"::"Pending for Approval",
            Customer."Approval Status",
            'Status should be Pending for Approval');

        Assert.AreEqual(
            Customer.Blocked::All,
            Customer.Blocked,
            'Pending customer must remain blocked = All.');
    end;

    [Test]
    procedure SetReleasedSetsBlockedBlank()
    var
        Customer: Record Customer;
    begin
        CreateReadyCustomer(Customer);

        CustomerApprovalManagement.SetReleased(Customer);

        Customer.Get(Customer."No.");

        Assert.AreEqual(
            Customer."Approval Status"::Released,
            Customer."Approval Status",
            'Status should be Released.');

        Assert.AreEqual(
            Customer.Blocked::" ",
            Customer.Blocked,
            'Released customer must have Blocked = blank');
    end;

    [Test]
    procedure SetOpenSetsBlockedAll()
    var
        Customer: Record Customer;

    begin
        CreateReadyCustomer(Customer);

        CustomerApprovalManagement.SetReleased(Customer);

        CustomerApprovalManagement.SetOpen(Customer);

        Customer.Get(Customer."No.");
        Assert.AreEqual(
            Customer."Approval Status"::Open,
            Customer."Approval Status",
            'Status should be open.');

        Assert.AreEqual(
            Customer.Blocked::All,
            Customer.Blocked,
            'Reopen Customer must be Blocked = All.');
    end;

    // ---------- PAN No. uniqueness ----------
    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure DuplicatePanNoIsRejected()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        PanNo: Code[10];

    begin
        // [GIVEN] A released customer with a PAN No.
        CreateReadyCustomer(Customer1);
        PanNo := Customer1."PAN No";

        CustomerApprovalManagement.ReleaseCustomer(Customer1);

        // [WHEN] A second customer tries to use the same PAN No.
        CreateBasicCustomer(Customer2);
        asserterror Customer2.Validate("PAN No", PanNo);

        // [THEN] It is rejected
        Assert.ExpectedError(PanDuplicateErr);
    end;

    // ---------- Mandatory field validation ----------

    [Test]
    procedure ReleaseFailsWhenMandatoryFieldsMissing()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] A customer missing PAN No. (and other mandatory fields)
        CreateBasicCustomer(Customer);

        // [WHEN] Release is attempted
        asserterror CustomerApprovalManagement.ReleaseCustomer(Customer);

        // [THEN] It fails with a mandatory-field error
        Assert.ExpectedError(MandatoryFieldErr);
    end;

    // ---------- Release (workflow disabled path) ----------

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]

    procedure ReleaseSucceedWhenWorkflowDisabledAndFieldsComplete()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] A fully completed customer, no Customer Approval Workflow enabled in this test company
        CreateReadyCustomer(Customer);

        // [WHEN] Release is clicked
        CustomerApprovalManagement.ReleaseCustomer(Customer);

        // [THEN] Customer is Released
        Customer.Get(Customer."No.");
        Assert.AreEqual(
            Customer."Approval Status"::Released,
            Customer."Approval Status",
            'Customer should be Released.');
    end;

    // ---------- Reopen ----------
    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]

    procedure ReopenSucceedsWhenReleased()
    var
        Customer: Record Customer;
    begin
        CreateReadyCustomer(Customer);

        CustomerApprovalManagement.ReleaseCustomer(Customer);

        CustomerApprovalManagement.ReopenCustomer(Customer);

        Customer.Get(Customer."No.");
        Assert.AreEqual(
            Customer."Approval Status"::Open,
            Customer."Approval Status",
            'Customer should be open again.');

        Assert.AreEqual(
            Customer.Blocked::All,
            Customer.Blocked,
            'Reopened customer must be Blocked = All.');
    end;

    [Test]
    procedure ReopenFailsWhenOpen()
    var
        Customer: Record Customer;
    begin
        CreateBasicCustomer(Customer);

        asserterror CustomerApprovalManagement.ReopenCustomer(Customer);

        Assert.ExpectedError(ReopenOnlyReleasedErr);
    end;

    [Test]
    procedure ReopenFailsWhenPending()
    var
        Customer: Record Customer;
    begin
        CreateReadyCustomer(Customer);
        CustomerApprovalManagement.SetPending(Customer);

        asserterror CustomerApprovalManagement.ReopenCustomer(Customer);

        Assert.ExpectedError(ReopenOnlyReleasedErr);
    end;

    // ---------- Helpers ----------

    local procedure CreateBasicCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer.Insert(true);
        Customer.Validate(
            Name,
            'Test Customer ' +
            Format(
                LibraryRandom.RandIntInRange(10000, 99999)));
        Customer.Modify(true);
    end;

    local procedure CreateReadyCustomer(var Customer: Record Customer)
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CreateBasicCustomer(Customer);

        if GenBusPostingGroup.FindFirst()
        then
            Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);

        if VATBusPostingGroup.FindFirst()
        then
            Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup.Code);

        if CustomerPostingGroup.FindFirst()
        then
            Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);

        Customer.Validate(
            "PAN No",
            'PAN' +
            Format(
                LibraryRandom.RandIntInRange(100000, 999999)));
        Customer.Modify(true);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(
        Question: Text[1024];
        var
        Reply: Boolean)
    begin
        Reply := true;
    end;
}