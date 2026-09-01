tableextension 50000 "Customer Extension" extends Customer
{
    fields
    {
        field(50000; "Approval Status"; Enum "Customer Approval Status")
        {
            Caption = 'Approval Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50001; "PAN No"; Code[10])
        {
            Caption = 'PAN No';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                if "PAN No" = ''
                then
                    exit;

                Customer.SetRange("PAN No", "PAN No");
                Customer.SetFilter("No.", '<>%1', "No.");

                if Customer.FindFirst() then
                    Error(
                        'PAN No. %1 already exists for customer %2.',
                        "PAN No",
                        Customer."No.");
            end;
        }
    }

    trigger OnInsert()
    begin
        Validate("Approval Status", "Approval Status"::Open);
        Validate(Blocked, Blocked::All);
    end;
}