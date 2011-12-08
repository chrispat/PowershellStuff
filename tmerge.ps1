if ($args.Length -lt 3) {
    write-host "usage: tmerge <base> <theirs> <mine>"
    return
}

$tortoise = (Get-ItemProperty "HKLM:\Software\TortoiseSVN" –ea SilentlyContinue).TMergePath

if ($tortoise -eq $null) {
    throw "Error: Could not find TortoiseProc.exe"
}

$commandLine = '/base:"' + $args[0] + '" /theirs:"' + $args[1] + '" /mine:"' + $args[2] + '"'
& $tortoise $commandLine
