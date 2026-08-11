function Remove-User{
<#
.SYNOPSIS
Remove users.

.DESCRIPTION
Remove the specified users.

.PARAMETER User
Specify the user's name.

.EXAMPLE
Remove-User -User "Name"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-LocalUser).Name})]
        [String]$User
    )
    if($PSCmdlet.ShouldProcess("Users", "The user $User will be removed.")){
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
Rename users.

.DESCRIPTION
Rename user names.

.PARAMETER User
Specify the user's name.

.PARAMETER NewName
Specify the new username.

.EXAMPLE
Rename-User -User "Name" -NewName "Name"
#>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-LocalUser).Name})]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [String]$NewName
    )
    if($PSCmdlet.ShouldProcess("Users", "The user's name will be renamed.")){
        try{
            Get-LocalUser -Name $User | Rename-LocalUser -NewName $NewName -ErrorAction Stop
            Write-Verbose "Success in renaming the user."
        }   catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
function Set-PasswordUser{
<#
.SYNOPSIS
Password Change.

.DESCRIPTION
Change the passwords of system users.

.PARAMETER User
Specify the user's name.

.PARAMETER Password
Enter your password.

.EXAMPLE
Set-PasswordUser -User "Name"
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-LocalUser).Name})]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password
    )
    if($PSCmdlet.ShouldProcess("Users", "The user's password will be changed.")){
        try{
            Set-LocalUser -Name $User -Password $Password
        }   catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
function Initialize-NewUser{
<#
.SYNOPSIS
User creation.

.DESCRIPTION
Creates users and assigns them to a group.

.PARAMETER User
Specify the user's name.

.PARAMETER Password
Enter your password.

.PARAMETER RepeatPassword
Confirm the password.

.NOTES
This function is executed first in the workflow by creating the users.
#>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password,

        [Parameter(Mandatory = $true)]
        [SecureString]$RepeatPassword
    )
    if($PSCmdlet.ShouldProcess("Users", "Creating User $User.")){
        if([PsCredential]::New("A",$Password).GetNetworkCredential().Password -ne [PsCredential]::New("B",$RepeatPassword).GetNetworkCredential().Password){
            Write-Warning "Passwords don't match."
            return
        }
        try{
            New-LocalUser -Name $User -Password $Password -AccountNeverExpires -PasswordNeverExpires -ErrorAction Stop
            Write-Verbose "Successfully created user."
        }   catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
function Initialize-AddGroup{
<#
.SYNOPSIS
Add user to groups.

.DESCRIPTION
After creating the user is assigned to a specific group.

.PARAMETER User
Specify the user's name.

.PARAMETER Group
Specify the workgroup.

.NOTES
This function is responsible for adding the newly created users to the specified groups.
#>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-LocalGroup).Name})]
        [String]$Group
    )
    if($PSCmdlet.ShouldProcess("Groups", "Adding User $User to Group $Group.")){
        try{
            Add-LocalGroupMember -Member $User -Group $Group -ErrorAction Stop
            Write-Verbose "User added to the group."
        }   catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
function New-User{
<#
.SYNOPSIS
Initialize user creation.

.DESCRIPTION
Start the workflow, creating the new user and adding them to a group.

.PARAMETER User
Specify the user's name.

.PARAMETER Password
Enter your password.

.PARAMETER RepeatPassword
Confirm the password.

.PARAMETER Group
Specify the workgroup.

.EXAMPLE
PS> New-User -User "Name" -Group "Administrators"

Create the user and assign the user to a specified group.

.NOTES
This function is responsible for handling the workflow to create the user first, and secondly 
assign the user to the specified group, controlling an order of execution and error handling.
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param(
        [Parameter(Mandatory = $true)]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password,

        [Parameter(Mandatory = $true)]
        [SecureString]$RepeatPassword,

        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-LocalGroup).Name})]
        [String]$Group
    )
    if($PSCmdlet.ShouldProcess("Users", "A new user will be created and added to a group.")){
        try{
            Initialize-NewUser `
                -User $User `
                -Password $Password `
                -RepeatPassword $RepeatPassword

            Initialize-AddGroup `
                -User $User `
                -Group $Group
        }   catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
Export-ModuleMember -Function Remove-User, Rename-User, Set-PasswordUser, New-User