################################################################################ 
## load-assembly.msh 
## 
## Loads a given assembly by a more friendly name, while still using the strong 
## binding characteristics of Assembly.Load. 
## 
## Assembly.LoadWithPartialName has been deprecated, as it binds only by display 
## name.  It's a convenient shortcut, but opens your application and script, and 
## environment  to all sorts of reliability issues, including: 
##    backwards incompatibility, forwards incompatibility, breaking changes, 
##    and subtle assembly dependency problems. 
## 
################################################################################ 
param([string] $assemblyName) 

## Our assembly name shortcuts 
$assemblyMappings = ( 
   ("forms", "System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"), 
   ("web", "System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a") 
) 

## List the assembly shortcuts we support 
if(-not $assemblyName) 
{ 
   "Please specify an assembly name.  Supported assemblies are: " 
   foreach($assembly in $assemblyMappings) { $assembly[0] } 
   return 
} 

## Load the assembly they request 
## This fails with an error message if this specific assembly version can't 
## be loaded. 
foreach($assembly in $assemblyMappings) 
{ 
    if($assemblyName -eq $assembly[0]) 
    { 
        [void] [Reflection.Assembly]::Load($assembly[1]) 
    } 
} 
