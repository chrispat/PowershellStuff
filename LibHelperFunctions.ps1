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