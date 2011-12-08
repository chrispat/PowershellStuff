if ($args.Length -lt 1) {
    write-host "usage: tsvn <command>"
    return
}

$tortoise = (Get-ItemProperty "HKLM:\Software\TortoiseSVN" –ea SilentlyContinue).ProcPath

if ($tortoise -eq $null) {
    throw "Error: Could not find TortoiseProc.exe"
}

$commandLine = '/command:' + $args[0] + ' /notempfile /path:"' + ((get-location).Path) + '"'
& $tortoise $commandLine
