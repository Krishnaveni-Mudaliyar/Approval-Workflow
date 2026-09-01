enum 50000 "Customer Approval Status"
{
    Extensible = true;
    
    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; "Pending for Approval")
    {
        Caption = 'Pending for Approval';
    }
    value(2; Released)
    {
        Caption = 'Released';
    }
}
