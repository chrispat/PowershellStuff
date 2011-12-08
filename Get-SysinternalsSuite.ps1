#requires -version 2.0

# Wintellect .NET Debugging Code
# (c) 2008 - 2009 by John Robbins\Wintellect - Do whatever you want to do with 
# it as long as you give credit. 

<#.SYNOPSIS
Gets all the wonderful Sysinternals tools
.DESCRIPTION
Downloads and extracts the Sysinternal tools to the directory you specify. This
script requires the excellent (and free) 7Z.EXE in the path to extract the 
.ZIP file. You can get 7z at http://www.7-zip.org.
.PARAMETER Extract
The directory where you want to extract the Sysinternal tools.
.PARAMETER Save
The default is to download the SysinternalsSuite.zip file and remove it after
extracting the contents. If you want to keep the file, specify the save 
directory with this parameter.
#>

param ( [string] $Extract = ($env:userprofile + "\utils\sysinternals" ) ,
        [string] $Save )

function CreateDirectoryIfNeeded ( [string] $directory )
{
    if ( ! ( Test-Path $directory -type "Container" ) ) 
    { 
        New-Item -type directory -Path $directory > $null
    }
}

##################################################################
# Main execution starts here.

$paramLog = @"
Param Extract   = $Extract
Param Save      = $Save
"@
Write-Debug $paramLog

[string]$sevenZName = "7Z.EXE"
# Verify I can find UNZIP.EXE in the path.
[string]$sevenZPath = $(Get-Command $sevenZName).Definition
if ( $sevenZPath.Length -eq 0 )
{
    Write-Error "Unable to find $sevenZName in the path."
    exit
}

# If the extract directory does not exist, create it.
CreateDirectoryIfNeeded ( $Extract )
# If there's a save directory set, us that otherwise, use the %TEMP% directory.
[Boolean]$deleteZipFile = $TRUE
[String]$downloadFile = ""
if ( $Save.Length -gt 0 )
{ 
    CreateDirectoryIfNeeded ( $Save )
    $downloadFile = $Save
    $deleteZipFile = $FALSE
}
else
{ 
    # Use the %TEMP% path for the user.
    $downloadFile = $env:temp
}

# Build up the full location and filename.
$downloadFile = $(Get-item $downloadFile).FullName
$downloadFile = Join-Path -path $downloadFile -childpath "SysinternalsSuite.zip" 
 
# Let the download begin!
Write-Output "Starting download of the Sysinternals Suite"
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile("http://download.sysinternals.com/Files/SysinternalsSuite.zip" ,
                        $downloadFile)
Write-Output "Sysinternals suite downloaded to $downloadFile"

# I don't like to see all the output from 7z unless there's a problem so I'll
# redirect to a temporary file and if there's any problems, I'll show it.
$temp7zOutput = [System.IO.Path]::GetTempFileName() 

# Since the -o option to 7Z.EXE cannot have a space between it and the
# directory there's a bit of a problem. PowerShell does not expand the
# line -o$Extract if passed directly on the command line.
$outputOption = "-o$Extract"
Write-Output "Extracting files into $Extract"
&$sevenZPath x -y $outputOption $downloadFile > $temp7zOutput
if ( $LASTEXITCODE -ne 0 )
{ 
    # There was a problem extracting. 
    Get-Content $temp7zOutput 
    # Don't delete the download file. 
    $deleteZipFile = $FALSE 
    Write-Error "Error extracting the .ZIP file" 
    Write-Error "The downloaded .ZIP file is at $downloadFile and will not be deleted."
}
# Delete the file that held the extraction output.
del $temp7zOutput
# Delete the downloaded .ZIP file if I'm supposed to.
if ( $deleteZipFile -eq $TRUE )
{
    Remove-Item $downloadFile
} 
# SIG # Begin signature block
# MIIOkQYJKoZIhvcNAQcCoIIOgjCCDn4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7AbysY1hQT5IPRqPBoFLINGN
# 8CaggglnMIIEXDCCA0SgAwIBAgIQT2PQMPgVo6WzRGlABj0WiTANBgkqhkiG9w0B
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
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFNSNxwPsYevQxMUtnVWZEz+n1lbAMA0GCSqG
# SIb3DQEBAQUABIIBAKl2ouzFQ/1uqHOoVdlcTyInlrLzwCPnhZwhFJ14zsAaxhKR
# f+i7MDNyLPJE4Sb6vO0GVFDIuqmvX8enh6VDulY/gr11KreSuuEwODgCEpCy9rLx
# YxyJfnjKOuJwJNwtpbmHDjXyKH0C3ANa1szZ1EplAmqG0+LwdGM0hRIyZhT5Q1DM
# 5zODm7vqrjR5NUDPYCt4v/iKsPlcDOqgFB7H/Nn52/kQDPca+FyG7hsmsP3P3SpF
# Bh3npAtW+qQf5044XXL1ZBu8mVkZ4UQjmFEKYoSC/4Jw+JpElq79B+nD2M9hX4zp
# ldjz9wz+sAzVyPTQLWHTGs6pl3iqt2WLrLmaZqqhggJEMIICQAYJKoZIhvcNAQkG
# MYICMTCCAi0CAQEwgaowgZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUG
# A1UEBxMOU2FsdCBMYWtlIENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0
# d29yazEhMB8GA1UECxMYaHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQD
# ExRVVE4tVVNFUkZpcnN0LU9iamVjdAIQT2PQMPgVo6WzRGlABj0WiTAJBgUrDgMC
# GgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcN
# MDkxMTI0MDE1OTM2WjAjBgkqhkiG9w0BCQQxFgQUOtofETnIUktKJdBRAiCJ7U0w
# jNQwDQYJKoZIhvcNAQEBBQAEggEAmyFFSNrvszS3mU8u2Z66fx7aBdvSNWAEo9vp
# htmhKkix/28AZhbRoyiBavvi1NI813swmYdO4YwW71P8NBNC59wuMpL5u0CrS3zV
# +ziZVxLBJ53usRP2oFB6hXcUAU1DiTpoRUEIIxo8nAx7hg29dV6anm95naAk37GO
# 7OPqjHxX1+/cBD6PhygdXZjOBnYBrp7SLr49WeNKTNYP7L+wTpoOuTy1NEMPLpGY
# Fu045e/l7nyCCdJA3YANMIjsp4PzqVygAkLjC6+h2RKdcVuAiV5cKlF/JdzbpOGr
# LLSrkYSPZan+seI73x6ml8iOd95Vb/GyIV8clzO1p2cqF9xh/g==
# SIG # End signature block
