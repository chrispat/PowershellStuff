# Svn functions
# Peter Provost (http://www.peterprovost.org/)
# Credits: gitutils by Mark Embling (http://www.markembling.info/)
 
# Is the current directory a svn repository/working copy?
function Test-SvnWorkingDirectory {
    if ((Test-Path ".svn") -eq $TRUE) {
        return $TRUE
    }
    return $FALSE
}
 
function Get-SvnInfo {
	$result = new-object PSObject
	svn info | foreach {
		if ($_.Trim() -ne "" ) {
			$splits = $_.Split(":")
			add-member NoteProperty $splits[0] $splits[1] -inputObject $result
		}
	}
	$result
}
 
# Extracts status details about the repo
function Get-SvnStatus {
	$untracked = 0
	$modified = 0
	$added = 0
	$deleted = 0

	svn status | foreach {
		if ($_.StartsWith("?")) {
			$untracked += 1
		}
		elseif ($_.StartsWith("M")) {
			$modified += 1
		}
		elseif ($_.StartsWith("D")) {
			$deleted += 1
		}
		elseif ($_.StartsWith("A")) {
			$added += 1
		}
	}

	$result = new-object PSObject -Property @{
		Added = $added
		Untracked = $untracked	
		Modified = $modified
		Deleted = $deleted
	}
	$result
}
