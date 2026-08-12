function Remove-User{
<#
.SYNOPSIS
Removes a local user account.

.PARAMETER User
Specifies the name of the local user account to remove.

.EXAMPLE
PS> Remove-User -User "John"

Removes the local user account named John.
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if($_ -in (Get-LocalUser).Name){
                $true
            }   else{
                throw "The local user '$_' does not exist."
            }
        })]
        [String]$User
    )
    if($PSCmdlet.ShouldProcess("Local Users", "The user $User will be removed.")){
        try{
            Remove-LocalUser -Name $User -ErrorAction Stop
            Write-Verbose "Success in removing the user $User."
        }   catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
function Rename-User{
<#
.SYNOPSIS
Renames a local user account.

.PARAMETER User
Specifies the name of the existing local user account.

.PARAMETER NewName
Specifies the new name for the local user account.

.EXAMPLE
PS> Rename-User -User "John" -NewName "JohnSmith"

Renames the user account from John to JohnSmith.
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if($_ -in (Get-LocalUser).Name){
                $true
            }   else{
                throw "The local user '$_' does not exist."
            }
        })]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if($_ -in (-not(Get-LocalUser).Name)){
                $true
            }   else{
                throw "The local user '$_' already exist."
            }
        })]
        [String]$NewName
    )
    try{
        Get-LocalUser -Name $User | Rename-LocalUser -NewName $NewName -ErrorAction Stop
        Write-Verbose "Success in renaming the user."
    }   catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
function Set-UserPassword{
<#
.SYNOPSIS
Changes the password of a local user account.

.PARAMETER User
Specifies the name of the local user account.

.PARAMETER Password
Specifies the new password as a SecureString.

.PARAMETER RepeatPassword
Confirms the new password.

.EXAMPLE
PS> Set-PasswordUser -User "John" -Password $Password -RepeatPassword $RepeatPassword

Changes the password of the local user account named John.

.NOTES
The password must match RepeatPassword.
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if($_ -in (Get-LocalUser).Name){
                $true
            }   else{
                throw "The local user '$_' does not exist."
            }
        })]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password,

        [Parameter(Mandatory = $true)]
        [SecureString]$RepeatPassword
    )
    try{
        Test-PasswordMatch
    }   catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
    if (-not (Test-PasswordMatch -Password $Password -RepeatPassword $RepeatPassword)) {
        Write-Warning "Passwords don't match."
        return
    }
    try{
        Set-LocalUser -Name $User -Password $Password -ErrorAction Stop
    }   catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
function Test-PasswordMatch{
<#
.SYNOPSIS
Compares two passwords.

.DESCRIPTION
Determines whether two SecureString passwords contain the same value.

.PARAMETER Password
Specifies the first password temporal to compare.

.PARAMETER RepeatPassword
Specifies the second password to compare.

.EXAMPLE
PS> Test-PasswordMatch -Password $Password -RepeatPassword $RepeatPassword Returns True if both passwords match; otherwise, returns False.

.NOTES
This function is intended for internal use by the module to validate password confirmation before creating or changing a local user password.
The passwords are provided as SecureString values. 
#>

    param(
        [Parameter(Mandatory)]
        [SecureString]$Password,

        [Parameter(Mandatory)]
        [SecureString]$RepeatPassword
    )

    $PasswordText = [System.Net.NetworkCredential]::new('', $Password).Password
    $RepeatPasswordText = [System.Net.NetworkCredential]::new('', $RepeatPassword).Password

    return $PasswordText -ceq $RepeatPasswordText
}
function New-LocalUserAccount{
<#
.SYNOPSIS
Creates a local user account.

.DESCRIPTION
Creates a local user account as part of the New-User workflow.

.PARAMETER User
Specifies the name of the user to create.

.PARAMETER Password
Specifies the user's password temporal as a SecureString.

.PARAMETER RepeatPassword
Confirms the user's password.

.NOTES
This function is intended to be called by New-User.
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password,

        [Parameter(Mandatory = $true)]
        [SecureString]$RepeatPassword
    )
    if (-not (Test-PasswordMatch -Password $Password -RepeatPassword $RepeatPassword)) {
        Write-Warning "Passwords don't match."
        return
    }
    try{
        New-LocalUser -Name $User -Password $Password -ErrorAction Stop
        net user $User /logonpasswordchg:yes
        Write-Verbose "Successfully created user."
    }   catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
function Add-LocalUserToGroup{
<#
.SYNOPSIS
Adds a local user to a local group.

.PARAMETER User
Specifies the name of the local user account.

.PARAMETER Group
Specifies the name of the local group.

.NOTES
This function is intended to be called by New-User.
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [String]$Group
    )
    try{
        Add-LocalGroupMember -Member $User -Group $Group -ErrorAction Stop
        Write-Verbose "User added to the group."
    }   catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
function New-User{
<#
.SYNOPSIS
Creates a local user account and adds it to a local group.

.DESCRIPTION
Creates a new local user account and adds it to the specified local group.

.PARAMETER User
Specifies the name of the user to create.

.PARAMETER Password
Specifies the user's password temporal as a SecureString.

.PARAMETER RepeatPassword
Confirms the user's password.

.PARAMETER Group
Specifies the name of the local group.

.EXAMPLE
PS> New-User -User "John" -Password $Password -RepeatPassword $RepeatPassword -Group "Users"

Creates the user John and adds the user to the Users group.

.NOTES
The password and confirmation password must match.

The user is created before being added to the specified group.
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if($_ -in (-not(Get-LocalUser).Name)){
                $true
            }   else{
                throw "The local user '$_' already exists."
            }
        })]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password,

        [Parameter(Mandatory = $true)]
        [SecureString]$RepeatPassword,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if($_ -in (Get-LocalGroup).Name){
                $true
            }   else{
                throw "The local group '$_' does not exist."
            }
        })]
        [String]$Group
    )
    try{
        Test-PasswordMatch `
            -Password $Password
            -RepeatPassword $RepeatPassword

        New-LocalUserAccount `
            -User $User `
            -Password $Password `
            -RepeatPassword $RepeatPassword

        Add-LocalUserToGroup `
            -User $User `
            -Group $Group
    }   catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
Export-ModuleMember -Function Remove-User, Rename-User, Set-UserPassword, New-User