<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $Credscredential
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        SCComplianceSearchAction 'SCComplianceSearchAction-Example1'
        {
            Action            = "Purge"
            PurgeType         = "SoftDelete"
            IncludeCredential = $True
            RetryOnError      = $False
            SearchName        = "Budget Mailbox Search"
            Ensure            = "Present"
            Credential        = $Credscredential
        }

        SCComplianceSearchAction 'SCComplianceSearchAction-Example2'
        {
            IncludeSharePointDocumentVersions   = $False
            Action                              = "Export"
            SearchName                          = "Budget Mailbox Search"
            FileTypeExclusionsForUnindexedItems = $null
            IncludeCredential                   = $False
            RetryOnError                        = $False
            ActionScope                         = "IndexedItemsOnly"
            EnableDedupe                        = $False
            Ensure                              = "Present"
            Credential                          = $Credscredential
        }

        SCComplianceSearchAction 'SCComplianceSearchAction-Example3'
        {
            IncludeSharePointDocumentVersions   = $False
            Action                              = "Retention"
            SearchName                          = "Budget Mailbox Search"
            FileTypeExclusionsForUnindexedItems = $null
            IncludeCredential                   = $False
            RetryOnError                        = $False
            ActionScope                         = "IndexedItemsOnly"
            EnableDedupe                        = $False
            Ensure                              = "Present"
            Credential                          = $Credscredential
        }
    }
}
