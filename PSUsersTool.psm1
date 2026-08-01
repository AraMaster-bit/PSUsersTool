<#[
.SYNOPSIS
User creation.

.DESCRIPTION
Creates users and assigns them to a group.

.PARAMETER User
Specify the user's name.

.PARAMETER Password
Enter your password.

.NOTES
This function is executed first in the workflow by creating the users.
]#>
function Initialize-NewUser{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password
    )
    if($PSCmdlet.ShouldProcess("Creating User $User.")){
        try{
            New-LocalUser -Name $User -Password $Password -AccountNeverExpires -PasswordNeverExpires -ErrorAction Stop
            Write-Verbose "Successfully created user."
        }   catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
<#[
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
]#>
function Initialize-AddGroup{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-LocalGroup).Name})]
        [String]$Group
    )
    if($PSCmdlet.ShouldProcess("Adding User $User to Group $Group.")){
        try{
            Add-LocalGroupMember -Member $User -Group $Group -ErrorAction Stop
            Write-Verbose "User added to the group."
        }   catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
<#[
.SYNOPSIS
Initialize user creation.

.DESCRIPTION
Start the workflow, creating the new user and adding them to a group.

.PARAMETER User
Specify the user's name.

.PARAMETER Password
Enter your password.

.PARAMETER Group
Specify the workgroup.

.EXAMPLE
Initialize-CreateUser -User "Name" -Password "Password" -Group "Administrators"

Create the user, enter the password, and assign the user to a specified group.

.NOTES
This function is responsible for handling the workflow to create the user first, and secondly 
assign the user to the specified group, controlling an order of execution and error handling.
]#>
function Initialize-CreateUser{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param(
        [Parameter(Mandatory = $true)]
        [String]$User,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password,

        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-LocalGroup).Name})]
        [String]$Group
    )
    if($PSCmdlet.ShouldProcess("User $User", "A new user will be created and added to a group.")){
        try{
            Initialize-NewUser `
                -User $User `
                -Secure $Password

            Initialize-AddGroup `
                -User $User `
                -Group $Group
        }   catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
Export-ModuleMember -Function Initialize-CreateUser