param (
    [uri] $wssAdminAsmxUrl = $(throw 'wssAdminAsmxUrl is required')
)

$request = '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                   xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
                   xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
            <GetLanguages xmlns="http://schemas.microsoft.com/sharepoint/soap/" />
        </soap:Body>
    </soap:Envelope>
'

$soapAction = 'http://schemas.microsoft.com/sharepoint/soap/GetLanguages';

$response = call-webservice $wssAdminAsmxUrl $request $soapAction
write-debug "Got GetLanguages response of $($response)"

get-matches $response '<LCID>(.*?)</LCID>'
