###################################################
# This should go OUTSIDE the prompt function, it doesn't need re-evaluation
# We're going to calculate a prefix for the window title 
# Our basic title is "PS - C:\Your\Path\Here" showing the current path
if(!$global:WindowTitlePrefix) {
   # But if you're running "elevated" on vista, we want to show that ...
   if( ([System.Environment]::OSVersion.Version.Major -gt 5) -and ( # Vista and ...
         new-object Security.Principal.WindowsPrincipal (
            [Security.Principal.WindowsIdentity]::GetCurrent()) # current user is admin
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) )
   {
      $global:WindowTitlePrefix = "PS (ADMIN)"
   } else {
      $global:WindowTitlePrefix = "PS"
   }
}

function prompt {
   # FIRST, make a note if there was an error in the previous command
   $err = !$?

   # Make sure Windows and .Net know where we are (they can only handle the FileSystem)
   [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
   # Also, put the path in the title ... (don't restrict this to the FileSystem
   $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix,$pwd.Path,$pwd.Provider.Name
   
   # Determine what nesting level we are at (if any)
   $Nesting = "$([char]0xB7)" * $NestedPromptLevel

   # Generate PUSHD(push-location) Stack level string
   $Stack = "+" * (Get-Location -Stack).count
   
   # my New-Script and Get-PerformanceHistory functions use history IDs
   # So, put the ID of the command in, so we can get/invoke-history easier
   # eg: "r 4" will re-run the command that has [4]: in the prompt
   $nextCommandId = (Get-History -count 1).Id + 1
   
   # Output prompt string
   # If there's an error, set the prompt foreground to "Red", otherwise, "Yellow"
   if($err) { $fg = "Red" } else { $fg = "Yellow" }
   # Notice: no angle brackets, makes it easy to paste my buffer to the web
   Write-Host "[${Nesting}${nextCommandId}${Stack}]:" -NoNewLine -Fore $fg
   
   return " "
}

$env:path += ';' + $env:userprofile + '\Utils\SysInternals'


function VsVars32($version = "10.0")
{
    $key = "HKLM:SOFTWARE\Wow6432Node\Microsoft\VisualStudio\" + $version
    $VsKey = get-ItemProperty $key
    $VsInstallPath = [System.IO.Path]::GetDirectoryName($VsKey.InstallDir)
    $VsToolsDir = [System.IO.Path]::GetDirectoryName($VsInstallPath)
    $VsToolsDir = [System.IO.Path]::Combine($VsToolsDir, "Tools")
    $BatchFile = [System.IO.Path]::Combine($VsToolsDir, "vsvars32.bat")
    Get-Batchfile $BatchFile
    $global:WindowTitlePrefix = "VS " + $version + " " +  $global:WindowTitlePrefix
}


function Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}

function script:append-path {
    $oldPath = get-content Env:\Path;
    $newPath = $oldPath + ";" + $args;
    set-content Env:\Path $newPath;
}