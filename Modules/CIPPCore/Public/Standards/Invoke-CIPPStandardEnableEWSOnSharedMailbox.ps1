function Invoke-CIPPStandardEnableEWSOnSharedMailbox {
  <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) EnableEWSOnSharedMailbox
    .SYNOPSIS
        (Label) ISGQ only - Enable EWS on shared mailboxes accounts
    .DESCRIPTION
        (Helptext) Enable EWS on shared mailboxes, required for CW Backup to continue functioning. Can kill off from October 2026.
        (DocsDescription) Enable EWS on shared mailboxes, required for some backup products to continue functioning. Can kill off from October 2026.
    .NOTES
        CAT
            Exchange Standards
        TAG

        EXECUTIVETEXT
            Enable EWS on shared mailboxes, required for some backup products to continue functioning. Can kill off from October 2026.
        ADDEDCOMPONENT
        IMPACT
            Medium Impact
        ADDEDDATE
            2026-04-15
        POWERSHELLEQUIVALENT
            Set-CASMailbox -Identity "sharedmailbox@domain.com" -EwsEnabled $true & Set-OrganizationConfig -EwsEnabled $true
        RECOMMENDEDBY

        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards
    #>

  param($Tenant, $Settings)

  try {
    $SharedMailboxList = New-ExoRequest -tenantid $Tenant -cmdlet 'Get-Mailbox' -cmdParams @{filter = "RecipientTypeDetails -eq 'SharedMailbox'" }
  }
  catch {
    $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
    Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Could not get the SharedMailbox for $Tenant. Error: $ErrorMessage" -Sev Error
    return
  }

  if ($Settings.remediate -eq $true) {
    if ($SharedMailboxList.Count -gt 0) {
      $AuditState = (New-ExoRequest -tenantid $Tenant -cmdlet 'Get-OrganizationConfig').EwsEnabled
      if (!($AuditState)) {
        New-ExoRequest -tenantid $Tenant -cmdlet 'Set-OrganizationConfig' -cmdParams @{EwsEnabled = $true }
      }
      $Request = $SharedMailboxList | ForEach-Object {
        @{
          CmdletInput = @{
            CmdletName = 'Set-CASMailbox'
            Parameters = @{Identity = $_.UserPrincipalName; EwsEnabled = $true }
          }
        }
      }

      $BatchResults = New-ExoBulkRequest -tenantid $tenant -cmdletArray @($Request)
      $BatchResults | ForEach-Object {
        if ($_.error) {
          $ErrorMessage = Get-NormalizedError -Message $_.error
          Write-Host "Failed to enable EWS for $($_.target). Error: $ErrorMessage"
          Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to enable EWS for $($_.target). Error: $ErrorMessage" -sev Error
        }
      }

    }

    <#if ($Settings.alert -eq $true) {

        if ($SharedMailboxList) {
            Write-StandardsAlert -message "Shared mailboxes with enabled accounts: $($SharedMailboxList.Count)" -object $SharedMailboxList -tenant $Tenant -standardName 'DisableSharedMailbox' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "Shared mailboxes with enabled accounts: $($SharedMailboxList.Count)" -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'All Entra accounts for shared mailboxes are disabled.' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        $State = $SharedMailboxList ? $SharedMailboxList : @()

        $CurrentValue = [PSCustomObject]@{
            DisableSharedMailbox = @($State)
        }
        $ExpectedValue = [PSCustomObject]@{
            DisableSharedMailbox = @()
        }

    Set-CIPPStandardsCompareField -FieldName 'standards.EnableEWSOnSharedMailbox' -CurrentValue $CurrentValue -ExpectedValue $ExpectedValue -Tenant $Tenant#>
  }
}
