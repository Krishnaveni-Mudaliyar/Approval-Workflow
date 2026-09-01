pageextension 50000 CustomerCardExt extends "Customer Card"
{
    layout
    {
        addafter(Name)
        {
            field("Approval Status"; Rec."Approval Status")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the approval status of the customer.';
            }
            field("PAN No"; Rec."PAN No")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the PAN No. of the customer.';
            }
        }
    }
    actions
    {
        addlast("Request Approval")
        {
            action(Reopen)
            {
                Caption = 'Reopen';
                ApplicationArea = All;
                Image = ReOpen;
                Promoted = true;
                PromotedCategory = process;

                trigger OnAction()
                var
                    CustomerApprovalManagement: Codeunit "Customer Approval Management";
                begin
                    CustomerApprovalManagement.ReopenCustomer(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Release)
            {
                Caption = 'Release';
                ApplicationArea = All;
                Image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CustomerApprovalManagement: Codeunit "Customer Approval Management";
                begin
                    CustomerApprovalManagement.ReleaseCustomer(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}