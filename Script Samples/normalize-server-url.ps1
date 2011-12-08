param ([string] $serverName = $(throw 'serverName is required'))

# if it's already a valid URI, just return it back
if ([uri]::trycreate($serverName, [urikind]::absolute, [ref]$null))
{
   return $serverName
}

# can we find it as a registered server?
[void][reflection.assembly]::loadwithpartialname('Microsoft.TeamFoundation.Client')
$uri = [Microsoft.TeamFoundation.Client.RegisteredServers]::GetUriForServer($serverName)
if ($uri -ne $null)
{
   return $uri.AbsoluteUri
}

# guess it by way of assuming http and port 8080
# TODO: make sure $servername resolves
$guessedPath = "http://$($serverName):8080/"
if ([uri]::trycreate($guessedPath, [urikind]::absolute, [ref]$null))
{
   return $guessedPath
}

throw "Failed to translate $serverName into a valid TFS server URI"
