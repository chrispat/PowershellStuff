########################################################
# Chris Pattersons Powershell Profile
########################################################
# Load any custom Powershell Snapins that we want
function LoadSnapin($name)
{
	if ((Get-PSSnapin $name -registered -erroraction SilentlyContinue ) -and
			(-not (Get-PSSnapin $name -ErrorAction SilentlyContinue)) )
	{
		Add-PSSnapin $name
	}
}
   

#####################################################
# Various helper globals
if (-not $global:home) { $global:home = (resolve-path ~) }

$dl = "~\Downloads";
$programs = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]"ProgramFiles");
$scripts = (split-path $profile); # I keep my personal .PS1 files in the same folder as my $profile
$documents = [System.Environment]::GetFolderPath("Personal")
$framework = Join-Path $Env:windir "Microsoft.NET\Framework"
$framework = Join-Path $framework ([Reflection.Assembly]::GetExecutingAssembly().ImageRuntimeVersion)


########################################################
# Environmental stuff I like...
#####################################################
# Helper scripts we will want

New-PSDrive -Name Scripts -PSProvider FileSystem -Root $scripts
Get-ChildItem scripts:\Lib*.ps1 | % { 
    . $_
}

# Customize the path for PS shells
append-path (split-path $profile)    # I put my scripts in the same dir as my profile script
append-path ("C:\Program Files\7-Zip\")
append-path ("C:\Program Files (x86)\Git\bin")
append-path ("C:\Program Files (x86)\Git\cmd")
append-path ($env:userprofile + "\utils\bin")
append-path ($env:userprofile + "\utils\sysinternals")

# Import Modules
Import-Module PowerTab
Import-Module Pscx
Import-Module posh-git
Import-Module posh-hg

# Tell UNIX utilities (particulary svn.exe) to use Notepad2 for its editor 
set-content Env:\VISUAL 'notepad2.exe';

# Aliases
set-alias wide format-wide;
set-alias sudo elevate-process;
set-alias count measure-object;
set-alias reflector $($env:userprofile + "\utils\Reflector\Reflector.exe");

# Remove ri so the ruby ri works
# if (test-path alias:\ri) { remove-item -force alias:\ri }

# Load my personal types tweaks
# Update-TypeData $scripts\types.ps1xml

# I don't like the default more function, so replace it w/ less.exe
# if (test-path function:\more) { remove-item -force function:\more }
# set-alias more less

# I also don't like the built in man function and use my own script instead
# if (test-path function:\man) { remove-item -force function:\man }
# set-alias man get-help

# Use my custom set-variable2 function instead of straight up set-variable
if (test-path alias:\set) { remove-item -force alias:\set }
set-alias set set-variable2

########################################################
# Prompt
function get-CurrentDirectoryName {
	$path = ""
	$pathbits = ([string]$pwd).split("\", [System.StringSplitOptions]::RemoveEmptyEntries)
	if($pathbits.length -eq 1) {
		$path = $pathbits[0] + "\"
	} else {
		$path = $pathbits[$pathbits.length - 1]
	}

	$path
}

function prompt {
 	$realLASTEXITCODE = $LASTEXITCODE
    
	$nextId = (get-history -count 1).Id + 1;
	Write-Host "$($nextId): " -noNewLine

	# Figure out current directory name
	$currentDirectoryName = get-CurrentDirectoryName

	# Admin mode prompt?
	$wi = [System.Security.Principal.WindowsIdentity]::GetCurrent();
	$wp = new-object 'System.Security.Principal.WindowsPrincipal' $wi;
	$userLocation = $env:username + '@' + [System.Environment]::MachineName
	if ( $wp.IsInRole("Administrators") -eq 1 )
	{
		$color = "Red";
		$title = "**ADMIN** - " + $userLocation + " " + $currentDirectoryName
	}
	else
	{
		$color = "Green";
		$title = $userLocation + " " + $currentDirectoryName
	}

	# Window title and main prompt text
	$host.UI.RawUi.WindowTitle = $global:WindowTitlePrefix + $title
    Write-Host $userLocation -nonewline -foregroundcolor $color 
    Write-Host (" " + $currentDirectoryName) -nonewline

    # Reset color, which can be messed up by Enable-GitColors
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor
    
    Write-VcsStatus

    $LASTEXITCODE = $realLASTEXITCODE


	return "> "
}

Enable-GitColors

Start-SshAgent -Quiet


