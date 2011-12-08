#requires -version 2.0

# Wintellect .NET Debugging Code
# (c) 2009 by John Robbins\Wintellect - Do whatever you want to do with it
# as long as you give credit. 

<#.SYNOPSIS
Sets up a computer with symbol server values in both the environment and in 
VS 2010.
.DESCRIPTION
Sets up both the _NT_SYMBOL_PATH environment variable and Visual Studio 2010
to use a common symbol cache directory as well as common symbol servers.
.PARAMETER Internal
Sets the symbol server to use to \\SYMBOLS\SYMBOLS. Visual Studio will not use 
the public symbol servers. This will turn off the .NET Framework Source Stepping
You must specify either -Internal or -Public to the script.
.PARAMETER Public
Sets the symbol server to use as the two public symbol servers from Microsoft. 
All the appropriate settings are configured to properly have .NET Reference 
Source stepping working.
.PARAMETER CacheDirectory
Defaults to C:\SYMBOLS\PUBLIC for -Public and C:\SYMBOLS\INTERNAL for -Internal. 
Note that if -Public is set, the public symbols will go into 
<CacheDirectory>\MicrosoftPublicSymbols because Visual Studio 2010 is hard coded to 
use that location.
.PARAMETER SymbolServers
A string array of additional symbol servers to use. If -Internal is set, these 
additional symbol servers will appear after \\SYMBOLS\SYMBOLS. If -Public is 
set, these symbol servers will appear after the public symbol servers so both
the environment variable and Visual Studio have the same search order
#>
[CmdLetBinding(SupportsShouldProcess=$true)]
param ( [switch]   $Internal       ,
		[switch]   $Public         ,
		[string]   $CacheDirectory ,
		[string[]] $SymbolServers   )
        
# Always make sure all variables are defined.
Set-PSDebug -Strict         

# Creates the cache directory if it does not exist.
function CreateCacheDirectory ( [string] $cacheDirectory )
{
	if ( ! $(Test-path $cacheDirectory -type "Container" ))
	{
		if ($PSCmdLet.ShouldProcess("Destination: $cacheDirectory" , 
                                    "Create Directory"))
		{
			New-Item -type directory -Path $cacheDirectory > $null
		}
	}
}

function Set-ItemPropertyScript ( $path , $name , $value , $type )
{
    if ( $path -eq $null )
    {
        Write-Error "Set-ItemPropertyScript path param cannot be null!"
        exit
    }
    if ( $name -eq $null )
    {
        Write-Error "Set-ItemPropertyScript name param cannot be null!"
        exit
    }
	$propString = "Item: " + $path.ToString() + " Property: " + $name
	if ($PSCmdLet.ShouldProcess($propString ,"Set Property"))
	{
        if ($type -eq $null)
        {
		  Set-ItemProperty -Path $path -Name $name -Value $value
        }
        else
        {
		  Set-ItemProperty -Path $path -Name $name -Value $value -Type $type
        }
	}
}

# Do the parameter checking.
if ( $Internal -eq $Public )
{
    Write-Error "You must specify either -Internal or -Public"
    exit
}

# Check if VS is running. 
if (Get-Process 'devenv' -ea SilentlyContinue)
{
    Write-Error "Visual Studio is running. Please close all instances before running this script"
    exit
}

$dbgRegKey = "HKCU:\Software\Microsoft\VisualStudio\10.0\Debugger"

if ( $Internal )
{
    $CacheDirectory = "C:\SYMBOLS\INTERNAL" 

    CreateCacheDirectory $CacheDirectory
    
    # Default to \\SYMBOLS\SYMBOLS and add any additional symbol servers to 
    # the end of the string.
    $symPath = "SRV*$CacheDirectory*\\vsncstor\symbols*\\cpvsbuild\drops\symbols*\\SYMBOLS\SYMBOLS"
    $vsPaths = ""
    $pathState = ""

	for ( $i = 0 ; $i -lt $SymbolServers.Length ; $i++ )
	{
        $symPath += "*"
        $symPath += $SymbolServers[$i]
        
        $vsPaths += $SymbolServers[$i]
        $vsPaths += ";"
        $pathState += "1"
	}
    $symPath += ";"
    
    Set-ItemPropertyScript HKCU:\Environment _NT_SYMBOL_PATH $symPath
    
    # Turn off .NET Framework Source stepping.
    Set-ItemPropertyScript $dbgRegKey FrameworkSourceStepping 0 DWORD
    # Turn off using the Microsoft symbol servers.
    Set-ItemPropertyScript $dbgRegKey SymbolUseMSSymbolServers 0 DWORD
    # Set the symbol cache dir to the same value as used in the environment
    # variable.
    Set-ItemPropertyScript $dbgRegKey SymbolCacheDir $CacheDirectory
    # Set the VS symbol path to any additional values
    Set-ItemPropertyScript $dbgRegKey SymbolPath $vsPaths
    # Tell VS that to the additional servers specified.
    Set-ItemPropertyScript $dbgRegKey SymbolPathState $pathState
    
}
else
{
    $CacheDirectory = "C:\SYMBOLS\PUBLIC" 

    CreateCacheDirectory $CacheDirectory
    
    # It's public so we have a little different processing to do. I have to 
    # add the MicrosoftPublicSymbols as VS hardcodes that onto the path.
    # This way both WinDBG and VS are using the same paths for public
    # symbols.
    $refSrcPath = "$CacheDirectory\MicrosoftPublicSymbols*http://referencesource.microsoft.com/symbols"
    $msdlPath = "$CacheDirectory\MicrosoftPublicSymbols*http://msdl.microsoft.com/download/symbols"
    $extraPaths = ""
    $enabledPDBLocations ="11"
    
    # Poke on any additional symbol servers. I've keeping everything the
    # same between VS as WinDBG.
	for ( $i = 0 ; $i -lt $SymbolServers.Length ; $i++ )
	{
        $extraPaths += ";"
        $extraPaths += $SymbolServers[$i]
        $enabledPDBLocations += "1"
	}

    $envPath = "SRV*$refSrcPath;SRV*$msdlPath$extraPaths"
    
    Set-ItemPropertyScript HKCU:\Environment _NT_SYMBOL_PATH $envPath
    
    # Turn off Just My Code.
    Set-ItemPropertyScript $dbgRegKey JustMyCode 0 DWORD
    
    # Turn on .NET Framework Source stepping.
    Set-ItemPropertyScript $dbgRegKey FrameworkSourceStepping 1 DWORD
    
    # Turn on Source Server Support.
    Set-ItemPropertyScript $dbgRegKey UseSourceServer 1 DWORD
    
    # Turn on Source Server Diagnostics as that's a good thing. :)
    Set-ItemPropertyScript $dbgRegKey ShowSourceServerDiagnostics 1 DWORD
    
    # It's very important to turn off requiring the source to match exactly.
    # With this flag on, .NET Reference Source Stepping doesn't work.
    Set-ItemPropertyScript $dbgRegKey UseDocumentChecksum 0 DWORD
    
    # Turn on using the Microsoft symbol servers.
    Set-ItemPropertyScript $dbgRegKey SymbolUseMSSymbolServers 1 DWORD
    
    # Set the VS SymbolPath setting.
    $vsSymPath =" $refSrcPath;$msdlPath$extraPaths"
    Set-ItemPropertyScript $dbgRegKey SymbolPath $vsSymPath
    
    # Tell VS that all paths set are active (you see those as check boxes in 
    # the Options dialog, Debugging\Symbols page).
    Set-ItemPropertyScript $dbgRegKey SymbolPathState $enabledPDBLocations
    
    # Set the symbol cache dir to the same value as used in the environment
    # variable.
    Set-ItemPropertyScript $dbgRegKey SymbolCacheDir $CacheDirectory
    
}
""
"Please log out to activate the new symbol server settings"
""
# SIG # Begin signature block
# MIIOkQYJKoZIhvcNAQcCoIIOgjCCDn4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAmLSr8rIWV1q8HZNWKDJr9js
# WnKggglnMIIEXDCCA0SgAwIBAgIQT2PQMPgVo6WzRGlABj0WiTANBgkqhkiG9w0B
# AQUFADCBlTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0
# IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYD
# VQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VS
# Rmlyc3QtT2JqZWN0MB4XDTA1MDUxNzAwMDAwMFoXDTEwMDUxNjIzNTk1OVowfjEL
# MAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
# BxMHU2FsZm9yZDEaMBgGA1UEChMRQ29tb2RvIENBIExpbWl0ZWQxJDAiBgNVBAMT
# G0NvbW9kbyBUaW1lIFN0YW1waW5nIFNpZ25lcjCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBALw1oDZwIoERw7KDudMoxjbNJWupe7Ic9ptRnO819O0Ijl44
# CPh3PApC4PNw3KPXyvVMC8//IpwKfmjWCaIqhHumnbSpwTPi7x8XSMo6zUbmxap3
# veN3mvpHU0AoWUOT8aSB6u+AtU+nCM66brzKdgyXZFmGJLs9gpCoVbGS06CnBayf
# UyUIEEeZzZjeaOW0UHijrwHMWUNY5HZufqzH4p4fT7BHLcgMo0kngHWMuwaRZQ+Q
# m/S60YHIXGrsFOklCb8jFvSVRkBAIbuDlv2GH3rIDRCOovgZB1h/n703AmDypOmd
# RD8wBeSncJlRmugX8VXKsmGJZUanavJYRn6qoAcCAwEAAaOBvTCBujAfBgNVHSME
# GDAWgBTa7WR0FJwUPKvdmam9WyhNizzJ2DAdBgNVHQ4EFgQULi2wCkRK04fAAgfO
# l31QYiD9D4MwDgYDVR0PAQH/BAQDAgbAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/
# BAwwCgYIKwYBBQUHAwgwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2NybC51c2Vy
# dHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0LmNybDANBgkqhkiG9w0BAQUF
# AAOCAQEASo/8HjCoPHXoR+dzrrBperJNvFDWmo+BtmAq9wKlSDoeFccYaxwYpMnf
# /fHO97gq1m2nzeV9IT0eP3TIorh5liiu4fpzQ/J6voAuZwTaF/qeWpb1nG1+foxs
# gSdQf2jYifp9BFlnDy105JmH18HhXRFKJvcmEIBnwsP3zzQbxHkhzGA1v6lgd57L
# vFIyImyt2t9t3fMuNs3Fp1Tg9KTM4/XUYk+ZBgzlb1lvEcfPWCS/ryUdRRF3mWWu
# MdRdSJ2Mw3JyKZnlCvG5zFo8SNP/QM7NEAM9vzOcCPMQIipHsHcr7ltOZeDTIzwD
# xM8uRWJpDhvSC/nzIA9TGtB8cfE40DCCBQMwggProAMCAQICEAagBWkwBM7q0PKO
# CWWI7eQwDQYJKoZIhvcNAQEFBQAwgZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJV
# VDEXMBUGA1UEBxMOU2FsdCBMYWtlIENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJV
# U1QgTmV0d29yazEhMB8GA1UECxMYaHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0w
# GwYDVQQDExRVVE4tVVNFUkZpcnN0LU9iamVjdDAeFw0wNzEyMTgwMDAwMDBaFw0x
# MDEyMTcyMzU5NTlaMIGqMQswCQYDVQQGEwJVUzEOMAwGA1UEEQwFOTgxMjExCzAJ
# BgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQJDAhVbml0ICNFNDEV
# MBMGA1UECQwMMjAyMSAxc3QgQXZlMSAwHgYDVQQKDBdKb2huIFJvYmJpbnMvV2lu
# dGVsbGVjdDEgMB4GA1UEAwwXSm9obiBSb2JiaW5zL1dpbnRlbGxlY3QwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDY0nEbQGJDWzEMPvhBv64poRE67XXK
# +vWBFGDr8hqeIz+pCinhRhr154HCTIb60tZKcHLhSWmw7l1bpuvYRWkfG8C7EwD2
# uLqaMrsoSMYOU7yWJSY+GCvKtsEqp5dEMJgdyIiB6RdWgjsy/GxOFpg+3rIzeG42
# evVtOJVZErlQVuwLb5C+1yiH1zeXxBHRqBUmZfyQ8HZCcpH4+GIu8C2IH9EnMp0y
# rleHn/3+ktJgFAbvKd5Zvd8y25q00IsEgnDh9lVQW14u9IT/7eMPJFX5jl7+tLRp
# on0zESO6s/wF1DeRmDMf3YUrH+9MuPem9wWdqA/qydeZW2MILZhZENYBAgMBAAGj
# ggE2MIIBMjAfBgNVHSMEGDAWgBTa7WR0FJwUPKvdmam9WyhNizzJ2DAdBgNVHQ4E
# FgQU5WhsWlzWc1O+dlk1OaqKBBn2TzswDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB
# /wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMEYG
# A1UdIAQ/MD0wOwYMKwYBBAGyMQECAQMCMCswKQYIKwYBBQUHAgEWHWh0dHBzOi8v
# c2VjdXJlLmNvbW9kby5uZXQvQ1BTMEIGA1UdHwQ7MDkwN6A1oDOGMWh0dHA6Ly9j
# cmwudXNlcnRydXN0LmNvbS9VVE4tVVNFUkZpcnN0LU9iamVjdC5jcmwwHgYDVR0R
# BBcwFYETam9obkB3aW50ZWxsZWN0LmNvbTANBgkqhkiG9w0BAQUFAAOCAQEAJsf+
# TRTjeQNVevP1BCLwAVs9J3+Ti2w1FNoJhTEpW/kfZWy6vPvnZdB1FjE8zWnpYRzu
# mMT6JFtG13d954iLu21njsDsq4Eemi6TVmCbH1rHWqcViW9B0U4chc6PznFY1G7w
# rauc6VYqOlmQ23J3etJddzExDQ6axhJ/K4XRBwb1G7JfqtLxk03EljB/MeHBfEbW
# qUc7sNih9uj6qBehPFFsgX1y/XN0n75Z30LoGAyTWbGjITThpX1eiiYTv2SSI0hY
# 3uZlCFo9ymPReZBQu/Ywj+T1HWDklnUrAHwjtsMclilpcCnjdvFDua3DFsGy5M6Q
# w2aGrNS3lwMD2f3n1DGCBJQwggSQAgEBMIGqMIGVMQswCQYDVQQGEwJVUzELMAkG
# A1UECBMCVVQxFzAVBgNVBAcTDlNhbHQgTGFrZSBDaXR5MR4wHAYDVQQKExVUaGUg
# VVNFUlRSVVNUIE5ldHdvcmsxITAfBgNVBAsTGGh0dHA6Ly93d3cudXNlcnRydXN0
# LmNvbTEdMBsGA1UEAxMUVVROLVVTRVJGaXJzdC1PYmplY3QCEAagBWkwBM7q0PKO
# CWWI7eQwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFJgZQgFYht0AGsYmQHePbqGpVBF8MA0GCSqG
# SIb3DQEBAQUABIIBAMf3paLXeFAnX//ZWskaWQEK7mym77DlD8MX6qm5F7/EJJlI
# tkw+zyldxwkybGLoQzxGg2fqETsFJHcR98yReQ6oYL7mLAIDnaFtCVag3n3dMFC+
# yFOJ+Iqjuq05LXV3z4Ioi8C4hbFbB9TCoDFY7VHiZXIq1D/mrbBaqPu1QkpyJpM0
# iMD2e2+k1G5r3TLr8am354bPsLq4ZkXrR3iKL26dyO3Xbe0oSi7kOxeBs7Tjw/QT
# KjwaEF8zNuCT8PqN2/NScXv+IyJzkP2k3JYSmWMQYeCEhbZMEfKG/TKUoRGF5JjQ
# 9pXn6nOeko2j2qkEBOsjE5SHZzWqZRIJikkAR/qhggJEMIICQAYJKoZIhvcNAQkG
# MYICMTCCAi0CAQEwgaowgZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUG
# A1UEBxMOU2FsdCBMYWtlIENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0
# d29yazEhMB8GA1UECxMYaHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQD
# ExRVVE4tVVNFUkZpcnN0LU9iamVjdAIQT2PQMPgVo6WzRGlABj0WiTAJBgUrDgMC
# GgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcN
# MDkxMTI0MDE1OTM3WjAjBgkqhkiG9w0BCQQxFgQUG8iMS5Y2sSf1iby+daeOUL/Z
# KAUwDQYJKoZIhvcNAQEBBQAEggEACiln8xTCaiFl1ZVUQ4i1qRuC0ydwRE2Ixn8t
# 1qPqW7W6GiEUxMeFzNYm5neI0IFQQfWV945z2XM/OW34S5QtqIMXO2cS7ovEeC04
# sXcLYYUVKZUVcqK8U4owF8XlPHBp1RnsX6xea89FI4kq3DkkfTVexkXfZQosKtOp
# phDxHd0L5jUEk0XzdkGWKTAy3S40vNmxG6T1325lAxCWryzbqqAYHNRbDllkIkTL
# JiUkIhwgbZYjUuZmsCXn0I0fU0Fo75nCM2mlztH2KzKQLu4AI0KA6NpqizGEo01v
# J/AAs0TRMFpc9kYAhWJV9PHP1xjIBHC67E6dU+V+3bcQ9tNRXg==
# SIG # End signature block
