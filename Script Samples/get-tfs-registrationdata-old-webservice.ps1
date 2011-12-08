param (
    [string] $serverUrl = $(throw 'serverUrl parameter is required'),
    [string] $toolId = ''
)

$getAllToolsCall = ('<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <GetRegistrationEntries xmlns="http://schemas.microsoft.com/TeamFoundation/2005/06/Services/Registration/03">
      <toolId>{0}</toolId>
    </GetRegistrationEntries>
  </soap:Body>
</soap:Envelope>' -f $toolId)


# try to get the registration entries xml
$registrationWebService = $serverUrl + '/services/v1.0/registration.asmx'
trap { 
    "Could not fetch registration data from $registrationWebService"
    break
} (call-webservice $registrationWebService $getAllToolsCall)