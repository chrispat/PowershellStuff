function Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}
  
function VsVars32($version = "10.0")
{
    if (Test-Path "HKLM:SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7") 
    {
        $vcdirkey = Get-ItemProperty "HKLM:SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7"
    }
    else
    {
        $vcdirkey = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\VisualStudio\SxS\VC7"
    }
    $vcdir = Get-Member -Name "$version" -InputObject $vcdirkey
    $vcdir = $vcdir.Definition.Split('=')[1]
    $BatchFile = [System.IO.Path]::Combine($vcdir, "bin\vcvars32.bat")
    Get-Batchfile $BatchFile
    $global:WindowTitlePrefix =  ("VS " + $version + " - ")
    #Set-ConsoleIcon ($env:userprofile + "\utils\resources\vspowershell.ico")
}


#Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# DotSource the Console Icon Stuff
#. ./Set-ConsoleIcon.ps1

#Pop-Location
