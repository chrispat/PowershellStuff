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
# Helper Functions
function ff ([string] $glob) { get-childitem -recurse -filter $glob }
function logout { shutdown /l /t 0 }
function halt { shutdown /s /t 5 }
function restart { shutdown /r /t 5 }
function sleep { RunDll.exe PowrProf.dll,SetSuspendState }
function lock { RunDll.exe User32.dll,LockWorkStation }
function rmd ([string] $glob) { remove-item -recurse -force $glob }
function strip-extension ([string] $filename) { [system.io.path]::getfilenamewithoutextension($filename) } 
function cd.. { cd ..  }
function lsf { get-childitem | ? { $_.PSIsContainer -eq $false } }
function lsd { get-childitem | ? { $_.PSIsContainer -eq $true } }
function ie { & 'C:\Program Files (x86)\Internet Explorer\iexplore.exe' $args }
function firefox { & "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" $args }
function bing { ie "http://www.bing.com/search?q=$args" }
function prepend-path { $oldPath = get-content Env:\Path; $newPath = $args + ";" + $oldPath; set-content Env:\Path $newPath; }
function append-path { $oldPath = get-content Env:\Path; $newPath = $oldPath + ";" + $args; set-content Env:\Path $newPath; }

########################################################
# Environmental stuff I like...
#####################################################
# Helper scripts we will want

New-PSDrive -Name Scripts -PSProvider FileSystem -Root $scripts
Get-ChildItem scripts:\Lib*.ps1 | % { 
    . $_
    write-host "Loading library file:`t$($_.name)"
}

# Customize the path for PS shells
append-path (split-path $profile)    # I put my scripts in the same dir as my profile script
append-path ("C:\Program Files\7-Zip\")
append-path ($env:userprofile + "\utils\bin")
append-path ($env:userprofile + "\utils\sysinternals")


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
# Special stuff for use with the TFC.exe program
set-alias tfc 'C:\Program Files\Team Foundation Client\tfc.exe'
set-content env:\CpcDefaultToGuiForCommit true
set-content env:\TfcDefaultToGuiForCommit true
set-content env:\CpcDefaultToGuiForStatus true
set-content env:\TfcDefaultToGuiForStatus true
set-content env:\IgnoreFile '.tfs-ignore'

$tmerge = (Get-ItemProperty "HKLM:\Software\TortoiseSVN" –ea SilentlyContinue).TMergePath

if ($tmerge -ne $null) {
	set-content env:\CpcDiffTool $tmerge
	set-content env:\CpcDiffArgs '/base:{basepath} /mine:{mypath} /basename:{basename} /minename:{myname}'
	set-content env:\CpcMergeTool $tmerge
	set-content env:\CpcMergeArgs '/base:{basepath} /mine:{mypath} /theirs:{theirpath} /basename:{basename} /minename:{myname} /theirsname:{theirname} /merged:{mergepath} /mergedname:{mergename}'

	set-content env:\TfcDiffTool (get-content env:\CpcDiffTool)
	set-content env:\TfcDiffArgs (get-content env:\CpcDiffArgs)
	set-content env:\TfcMergeTool (get-content env:\CpcMergeTool)
	set-content env:\TfcMergeArgs (get-content env:\CpcMergeArgs)
}

########################################################
# My own little sudo script
function elevate-process
{
	$file, [string]$arguments = $args;
	$psi = new-object System.Diagnostics.ProcessStartInfo $file;
	$psi.Arguments = $arguments;
	$psi.Verb = "runas";
	$psi.WorkingDirectory = get-location;
	[System.Diagnostics.Process]::Start($psi);
}


filter Format-Bytes {
	$units = 'B  ', 'KiB', 'MiB', 'GiB', 'TiB';
	$ln = [Int64]0 + $_;
	$u = 0;

	if($ln -eq 0) {
		return '0    ';
	}

	while(($ln -gt 1024) -and ($u -lt $units.Length)) {
		$ln /= 1024;
		$u++;
	}

	'{0,7:0.###} {1}' -f $ln, $units[$u];
}

function set-variable2
{
	if ($args.Count -eq 0) { get-variable }
	elseif ($args.Count -eq 1) { get-variable $args[0] }
	else { invoke-expression "set-variable $args" }
}


function du ($path = '.\', $unit="MB", $round=0) 
{ 
	get-childitem $path -force | ? { 
		$_.Attributes -like '*Directory*' } | %{ 
			dir $_.FullName -rec -force | 
			measure-object -sum -prop Length | 
			add-member -name Path -value $_.Fullname -member NoteProperty -pass | 
			select Path,Count,@{ expr={[math]::Round($_.Sum/"1$unit",$round)}; Name="Size($unit)"} 
		} 
}

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
	
	if (isCurrentDirectoryGitRepository) {
			$status = gitStatus
			$currentBranch = $status["branch"]
			
			Write-Host(' git:[') -nonewline -foregroundcolor Yellow
			if ($status["ahead"] -eq $FALSE) { # We are not ahead of origin
					Write-Host($currentBranch) -nonewline -foregroundcolor Cyan
			} else { # We are ahead of origin
					Write-Host($currentBranch) -nonewline -foregroundcolor Red
			}
			Write-Host(' +' + $status["added"]) -nonewline -foregroundcolor Yellow
			Write-Host(' ~' + $status["modified"]) -nonewline -foregroundcolor Yellow
			Write-Host(' -' + $status["deleted"]) -nonewline -foregroundcolor Yellow
			
			if ($status["untracked"] -ne $FALSE) {
					Write-Host(' !') -nonewline -foregroundcolor Red
			}
			
			Write-Host(']') -nonewline -foregroundcolor Yellow 
	}
    
    if (isCurrentDirectoryMercurialRepository) {
        $status = mercurialStatus
        $currentBranch = $status["branch"]
 
        Write-Host(' hg:[') -nonewline -foregroundcolor Yellow
        Write-Host($currentBranch) -nonewline -foregroundcolor Cyan
        Write-Host(' +' + $status["added"]) -nonewline -foregroundcolor Yellow
        Write-Host(' ~' + $status["modified"]) -nonewline -foregroundcolor Yellow
        Write-Host(' -' + $status["deleted"]) -nonewline -foregroundcolor Yellow
        
        if($status["missing"] -gt 0){
            Write-Host(' !' + $status["missing"]) -nonewline -foregroundcolor Red
        }
        
        if($status["untracked"] -gt 0){
            Write-Host(' ?' + $status["untracked"]) -nonewline -foregroundcolor Red     
        }   
 
        Write-Host(']') -nonewline -foregroundcolor Yellow
    }    

	return "> "
}



########################################################
# Custom 'cd' command to maintain directory history
#
# Usage:
#  cd					no args means cd $home
#  cd <name>	changes to that directory
#  cd -l			list your directory history
#  cd -#			change to the history entry specified by #
#
if( test-path alias:\cd ) { remove-item alias:\cd }
$global:PWD = get-location;
$global:CDHIST = [System.Collections.Arraylist]::Repeat($PWD, 1);
function cd {
	$cwd = get-location;
	$l = $global:CDHIST.count;

	if ($args.length -eq 0) { 
		set-location $HOME;
		$global:PWD = get-location;
		$global:CDHIST.Remove($global:PWD);
		if ($global:CDHIST[0] -ne $global:PWD) {
			$global:CDHIST.Insert(0,$global:PWD);
		}
		$global:PWD;
	}
	elseif ($args[0] -like "-[0-9]*") {
		$num = $args[0].Replace("-","");
		$global:PWD = $global:CDHIST[$num];
		set-location $global:PWD;
		$global:CDHIST.RemoveAt($num);
		$global:CDHIST.Insert(0,$global:PWD);
		$global:PWD;
	}
	elseif ($args[0] -eq "-l") {
		for ($i = $l-1; $i -ge 0 ; $i--) { 
			"{0,6}  {1}" -f $i, $global:CDHIST[$i];
		}
	}
	elseif ($args[0] -eq "-") { 
		if ($global:CDHIST.count -gt 1) {
			$t = $CDHIST[0];
			$CDHIST[0] = $CDHIST[1];
			$CDHIST[1] = $t;
			set-location $global:CDHIST[0];
			$global:PWD = get-location;
		}
		$global:PWD;
	}
	else { 
		set-location "$args";
	$global:PWD = pwd; 
		for ($i = ($l - 1); $i -ge 0; $i--) { 
			if ($global:PWD -eq $CDHIST[$i]) {
				$global:CDHIST.RemoveAt($i);
			}
		}

		$global:CDHIST.Insert(0,$global:PWD);
		$global:PWD;
	}

	$global:PWD = get-location;
}

function up ([int] $count = 1)
{
	1..$count | % { set-location .. }
	$global:PWD = get-location;
	$global:CDHIST.Insert(0, $global:PWD)
}


function clean-vsextcache {
	param( $ver = "10.0exp" )

	$dir = "$home\AppData\Local\Microsoft\VisualStudio\$ver\ComponentModelCache"
	if (test-path $dir) {
		write-host "Removing $dir"
		remove-item -recurse -force $dir
	}

	$dir = "$home\AppData\Local\Microsoft\VisualStudio\$ver\Extensions"
	if (test-path $dir) {
		write-host "Removing $dir"
		remove-item -recurse -force $dir
	}
}

