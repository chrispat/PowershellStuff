if ($args.Length -lt 2) {
    write-host "usage: tdiff <file1> <file2>"
    return
}

$tortoise = (Get-ItemProperty "HKLM:\Software\TortoiseSVN" –ea SilentlyContinue).TMergePath

if ($tortoise -eq $null) {
    throw "Error: Could not find TortoiseProc.exe"
}

$commandLine = '/base:"' + $args[0] + '" /mine:"' + $args[1] + '"'
& $tortoise $commandLine
