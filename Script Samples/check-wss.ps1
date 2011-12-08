param ([string] $serverUrl = $(throw 'serverUrl parameter is required'))

# talk to TFS to get registration entries (toolId=Wss?)
# parse response to get the Wss base site (for a TP?)
# Try to hit some normal web service

# this should work, but gives a 403 since we can't browse
#ping-url($serverUrl)

$getAllToolsCall = '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <GetRegistrationEntries xmlns="http://schemas.microsoft.com/TeamFoundation/2005/06/Services/Registration/03">
      <toolId>wss</toolId>
    </GetRegistrationEntries>
  </soap:Body>
</soap:Envelope>'


# try to get the registration entries xml
$registrationWebService = $serverUrl + '/services/v1.0/registration.asmx'
trap { 
    "Could not fetch registration data from $registrationWebService"
    break
} $registrationEntries = [xml](call-webservice $registrationWebService $getAllToolsCall)

# we have the xml, parse out the URL's
$registrationUrls = $registrationEntries.GetElementsByTagName('Url') | 
                    # only interested in the url string itself
                    %{ $_.'#text' } |
                    # filter to only full or partial URL's (no hostname/UNC)
                    ?{ $_ -match '^http' -or $_ -match '^/' } |
                    # filter out the ones we know will fail if called directly (base sharepoint, 2 TFVC ones)
                    ?{ $_ -notmatch '/sites$' -and $_ -notmatch '/item.asmx$' -and $_ -notmatch '/upload.asmx$' }

write-host ('Found {0} registered urls to check at server {1}' -f $registrationUrls.Count, $serverUrl)
write-host ''

$registrationUrls | %{
    #write-host "testing $_"
    $fullUrl = $_
    if ($fullUrl -notmatch '^http') { $fullUrl = $serverUrl + $fullUrl }
    $result = ping-url $fullUrl
    $color = 'green'
    if ($result -match 'Failed') { $color = 'red' }
    write-host -foreground $color ('Result of pinging {0}: {1}' -f $_, $result)
}
