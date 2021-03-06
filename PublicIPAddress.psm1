Function Save-PublicIPAddress
{
	<#
	.SYNOPSIS
	Get public IPv4 or IPv6 address and save the IP-address to a file.
	
	.DESCRIPTION
	Public IP-address will be saved into IPv4.txt or IPv6.txt file in the given path, depending on whether IPv6 switch-parameter is used.
	
	The given path is checked for existence of IPv4.txt/IPv6.txt and if the file exists, IP-address will be read from the file and checked against current public IP-address of specified type.
	
	Existing file will then be updated should IP-address been changed. If no file exists, then a new file will be created.
	
	API of whatismyipaddress.com will be used to query for current public IP-address of specified type. Please note that queries should not be run more frequently than once per five minutes.
	
	.PARAMETER Path
	Specifies directory path where IPv4.txt or IPv6.txt should be written to.
	
	.PARAMETER IPv6
	Queries for IPv6 address instead of IPv4. IPv4 is the default.

    .PARAMETER ScheduledTask
    When this switch is specified, a scheduled task to run Save-PublicIPAddress function every 15 minutes will be created. The scheduled task will run under SYSTEM account and thus will not be visible to regular user accounts.

    .PARAMETER ScheduledTask
    By default this function does not generate output. By specifying this switch, the function will output current public IP-address.

    .EXAMPLE
    Save-PublicIPAddress -Path C:\Users\User\Dropbox

    Queries for current public IPv4-address and saves the IP-address to IPv4.txt in C:\Users\User\Dropbox.

    .EXAMPLE
    Save-PublicIPAddress -Path C:\Users\User\Dropbox -IPv6

    Queries for current public IPv6-address and saves the IP-address to IPv6.txt in C:\Users\User\Dropbox.

    .EXAMPLE
    Save-PublicIPAddress -Path C:\Users\User\Dropbox -ScheduledTask

    Creates a scheduled task to run "Save-PublicIPAddress -Path C:\Users\User\Dropbox" every 15 minutes.

    .EXAMPLE
    Save-PublicIPAddress -Path C:\Users\User\Dropbox -IPv6 -ScheduledTask

    Creates a scheduled task to run "Save-PublicIPAddress -IPv6 -Path C:\Users\User\Dropbox" every 15 minutes.
	#>
	
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact = 'Low', DefaultParameterSetName = 'Default')]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-DirectoryPath -Path $_ })]
		[string]
		$Path,
		[switch]
		$IPv6,
        [Parameter(ParameterSetName = 'ScheduledTask')]
        [switch]
        $ScheduledTask,
        [Parameter(ParameterSetName = 'PassThru')]
        [switch]
        $PassThru
	)

    If ($ScheduledTask)
    {
		If ((Test-Administrator) -eq $false)
		{
			Write-Error -Message "PowerShell must be run as Administrator in order to create a new scheduled task." -Category PermissionDenied -ErrorAction Stop
		}

        New-SavePublicIPAddressScheduledTask -Path $Path -IPv6:$IPv6
    }
    Else
    {
	    $FileIPAddress = Get-FileIPAddress -Path $Path -IPv6:$IPv6
	    $PublicIPAddress = Get-PublicIPAddress -IPv6:$IPv6

	    If (($PublicIPAddress) -and ($FileIPAddress -ne $PublicIPAddress))
	    {
		    Set-FileIPAddress -Path $Path -IPAddress $PublicIPAddress -IPv6:$IPv6
	    }

        If ($PassThru)
        {
            $PublicIPAddress
        }
    }
}

Function Test-DirectoryPath
{
	<#
	.SYNOPSIS
	Test whether given Path is a valid directory path and that the directory exists.
	#>
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path
	)
	
	If (-not (Test-Path -Path FileSystem::$Path -PathType Container))
	{
		throw "`"$Path`" is not a valid directory path, or the directory does not exist."
	}

	$true
}

Function Test-Administrator
{
	<#
	.SYNOPSIS
	Test whether current PowerShell instance is running with Administrator privileges.
	#>

	([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
}

Function Get-FileIPAddress
{
	<#
	.SYNOPSIS
	Get IP-address from existing IPv4.txt/IPv6.txt.
	#>
	
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path,
		[switch]
		$IPv6
	)
	
	If ($IPv6)
	{
		$FilePath = Join-Path -Path $Path -ChildPath 'IPv6.txt'
		$None = '::'
	}
	Else
	{
		$FilePath = Join-Path -Path $Path -ChildPath 'IPv4.txt'
		$None = '0.0.0.0'
	}
	
	If (Test-Path FileSystem::$FilePath -PathType Leaf)
	{
		Get-Content FileSystem::$FilePath
	}
	Else
	{
		$None
	}
}

Function Set-FileIPAddress
{
	<#
	.SYNOPSIS
	Write new IP-address to IPv4.txt/IPv6.txt in the given path.
	#>
	
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact = 'Low')]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$IPAddress,
		[switch]
		$IPv6
	)

	If ($IPv6)
	{
		$FilePath = Join-Path -Path $Path -ChildPath 'IPv6.txt'
	}
	Else
	{
		$FilePath = Join-Path -Path $Path -ChildPath 'IPv4.txt'
	}
	
    $IPAddress | Out-File -FilePath FileSystem::$FilePath -Encoding utf8
}

Function Get-PublicIPAddress
{
	<#
	.SYNOPSIS
	Get public IPv4 or IPv6 address.
	
	.DESCRIPTION
	API of whatismyipaddress.com will be used to query for current public IP-address of specified type.
	
	.PARAMETER IPv6
	Queries for IPv6 address instead of IPv4. IPv4 is the default.

    .EXAMPLE
    Get-PublicIPAddress

    Returns current public IPv4-address.

    .EXAMPLE
    Get-PublicIPAddress -IPv6

    Returns current public IPv6-address.
	#>
	
	Param (
		[switch]
		$IPv6
	)
	
	If ($IPv6)
	{
		$Uri = 'ipv6bot.whatismyipaddress.com'
	}
	Else
	{
		$Uri = 'ipv4bot.whatismyipaddress.com'
	}
	
	Invoke-WebRequest -Uri $Uri -UseBasicParsing -DisableKeepAlive | Select-Object -ExpandProperty Content
}

Function New-SavePublicIPAddressScheduledTask
{
    <#
	.SYNOPSIS
	Create a scheduled task to run Save-PublicIPAddress function every 15 minutes.
    #>

    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact = 'Low')]
    Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path,
        [switch]
        $IPv6
	)

    $xmlPath = New-ScheduledTaskXml -Path $Path -IPv6:$IPv6

    If ($IPv6)
    {
        $TaskName = 'SavePublicIPv6Address'
    }
    Else
    {
        $TaskName = 'SavePublicIPv4Address'
    }

    If ($PSCmdlet.ShouldProcess("$TaskName", "Create and run scheduled task"))
    {
        If (Test-Path -Path FileSystem::$xmlPath)
        {
            schtasks /CREATE /TN $TaskName /XML "$xmlPath" /F
            schtasks /RUN /TN $TaskName
        }
    }

    If (Test-Path -Path FileSystem::$xmlPath)
    {
        Remove-Item -Path FileSystem::$xmlPath -Force
    }
}

Function New-ScheduledTaskXml
{
    <#
	.SYNOPSIS
	Create an xml file that contains the information required to create a scheduled task. For use by schtasks.exe.
    #>

    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact = 'Low')]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path,
        [switch]
        $IPv6
	)
	
	$xml = '<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>Juho Lehto</Author>
    <Description>A scheduled task to periodically run Save-PublicIPAddress PowerShell function.</Description>
  </RegistrationInfo>
  <Triggers>
    <TimeTrigger>
      <Repetition>
        <Interval>PT15M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>1990-01-01T00:00:00</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <RunLevel>LeastPrivilege</RunLevel>
      <GroupId>NT AUTHORITY\SYSTEM</GroupId>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT10M</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-windowstyle hidden -noprofile -command "Save-PublicIPAddress -Path ''DIRPATH''"</Arguments>
    </Exec>
  </Actions>
</Task>'
	
	$xmlPath = Join-Path -Path $env:TEMP -ChildPath 'SavePublicIPAddress.xml'
    $Minute = ((Get-Date).Minute).ToString('00')
    $Second = ((Get-Date).Second).ToString('00')
    
    $xml = $xml -creplace 'T00:00:00', "T00:$($Minute):$($Second)" -creplace 'DIRPATH', $Path

    If ($IPv6)
    {
        $xml = $xml -creplace '-Path', '-IPv6 -Path'
    }

    $xml | Out-File -FilePath FileSystem::$xmlPath -Encoding unicode
    $xmlPath
}