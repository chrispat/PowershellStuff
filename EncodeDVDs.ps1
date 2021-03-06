$handbrake = "C:\Program Files (x86)\HandBrake\HandBrakeCLI.exe"
$dirs = @(Get-ChildItem . VIDEO_TS -Recurse | Where {$_.PSIsContainer -eq $true})
foreach ($dir in $dirs) {
    $parentDir = $dir.Parent
    Write-Host $parentDir.fullname
    $files = @(Get-ChildItem $parentDir -Recurse | WHERE {$_.extension -eq '.m4v' -or $_.extension -eq '.mp4'})
    if ($files.Length -eq 0)
    {
         $newFileName = $parentDir.FullName + "\" + $parentDir.Name + '.m4v'
         $deviceFileName = $parentDir.FullName + "\" + $parentDir.Name + '_Device.m4v'
         Write-Host $newFileName
         
         &$handbrake -i "$($dir.Fullname)"-o "$newFileName" --preset "Standard" > "$($parentDir.FullName)\EncodeStatus.txt"
         &$handbrake -i "$($dir.Fullname)"-o "$deviceFileName" --preset "Phone" > "$($parentDir.FullName)\EncodeStatus_Device.txt"
            
         if ($LastExitCode -ne 0) { Write-Warning "Error converting $($parentDir.FullName)" }
    }
    else
    {
        Write-Host "Movie " -nonewline -backgroundcolor Yellow
        Write-Host $parentDir.FullName -nonewline -backgroundcolor Yellow
        Write-Host " has already been converted. " -nonewline -backgroundcolor Yellow
        Write-Host "$files" -backgroundcolor Yellow
    }
    
}