<#
.SYNOPSIS
   Invokes the specified batch file and retains any environment variable changes
   it makes.
.DESCRIPTION
   Invoke the specified batch file (and parameters), but also propagate any  
   environment variable changes back to the PowerShell environment that  
   called it.
.PARAMETER Path
   Path to a .bat or .cmd file.
.PARAMETER Parameters
   Parameters to pass to the batch file.
.EXAMPLE
   C:\PS> Invoke-BatchFile "$env:VS90COMNTOOLS\..\..\vc\vcvarsall.bat"       
   Invokes the vcvarsall.bat file to set up a 32-bit dev environment.  All 
   environment variable changes it makes will be propagated to the current 
   PowerShell session.
.EXAMPLE
   C:\PS> Invoke-BatchFile "$env:VS90COMNTOOLS\..\..\vc\vcvarsall.bat" amd64      
   Invokes the vcvarsall.bat file to set up a 64-bit dev environment.  All 
   environment variable changes it makes will be propagated to the current 
   PowerShell session.
.NOTES
   Author: Lee Holmes    
#>
function Invoke-BatchFile
{
   param([string]$Path, [string]$Parameters)  

   $tempFile = [IO.Path]::GetTempFileName()  

   ## Store the output of cmd.exe.  We also ask cmd.exe to output   
   ## the environment table after the batch file completes  
   cmd.exe /c " `"$Path`" $Parameters && set > `"$tempFile`" " 

   ## Go through the environment variables in the temp file.  
   ## For each of them, set the variable in our local environment.  
   Get-Content $tempFile | Foreach-Object {   
       if ($_ -match "^(.*?)=(.*)$")  
       { 
           Set-Content "env:\$($matches[1])" $matches[2]  
       } 
   }  

   Remove-Item $tempFile
}

