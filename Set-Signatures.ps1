param ( $password = $(throw '$password is required' ) )
# My script to sign all my PowerShell scripts in the current directory.
$certFile = "..\JohnRobbins-Wintellect.pfx"
$cert = Get-PfxCertificate $certFile
$timeServer = "http://timestamp.comodoca.com/authenticode"
$files = $(get-childitem *.ps1 -exclude Set-Signatures.ps1)
Set-AuthenticodeSignature -FilePath $files -Certificate $cert -TimestampServer $timeServer

# Now do the .JS files.
signtool sign /f $certFile /t $timeServer /p $password *.js