#########################################################################
# Name: update-dkp.ps1
# Version: 1.0
# Author: Peter Provost <peter@provost.org>
#
# Usage: update-dkp
#
# Remarks: This is a simple powershell script for updating your
#		dkpsystem.com raid leader data files. 
#

# Configuration - change these as needed
if (test-path "HKLM:\SOFTWARE\Blizzard Entertainment\World of Warcraft")
{
	$wowDir = (Get-ItemProperty -path "HKLM:\SOFTWARE\Blizzard Entertainment\World of Warcraft").InstallPath;
	$wowAddonDir = join-path $wowDir "Interface\Addons";
}
else
{
	$wowAddonDir = "C:\Program Files\World of Warcraft\Interface\Addons";
}

$uri = "http://benethugs.dkpsystem.com/luadkp.php"
$target = join-path $wowAddonDir "GuildRaidSnapShot\GRSS_Data.lua"
$wc = new-object System.Net.WebClient;

if (test-path $target)
{
	write-host "Backing up existing $target..." -noNewLine;
	$backup = join-path $wowAddonDir "GuildRaidSnapShot\GRSS_Data.lua.bak"
	copy-item -path $target -destination $backup -force
	write-host "done.";
}

write-host "`tDownloading $uri to $($target)..." -noNewLine;
$wc.DownloadFile( $uri, $target );
write-host "done.";


