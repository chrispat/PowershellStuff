########################################################
# Loads the vsvars32.bat file

if (test-path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7") {
	$vcdir = (Get-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7")."10.0"
} else {
	$vcdir =  (Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7")."10.0"
}

pushd $vcdir
cmd /c "vcvarsall.bat&set" | % { 
  if ($_ -match "=") { 
    $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])" 
  } 
} 
popd 

$global:WindowTitlePrefix = "VS2010 - "
