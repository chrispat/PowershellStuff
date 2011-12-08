function runQuery([system.data.sqlclient.SqlConnection] $sqlConn, [string] $query) {
    $sqlCommand = new-object 'system.data.sqlclient.SqlCommand' $query, $sqlConn
    $rdr = $sqlCommand.ExecuteReader()
    while($rdr.Read())
    {
        if ($rdr.FieldCount -eq 1)
        {
            # single value, just return it
            $rdr.GetValue(0)
        }
        else
        {
            # multiple columns, create a custom result object
            $row = new-object psobject
            $row.psobject.typenames[0] = "SqlResultObject"
            for($c = 0; $c -lt $rdr.FieldCount; $c++) 
            { 
                $row | add-member noteproperty $rdr.GetName($c) $rdr.GetValue($c) 
            }
            $row
        }
    }
    $rdr.close();
}

function print-header([string] $header)
{
    write-host ''
    write-host $header
    write-host ('=' * $header.length)
}

$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Visual Studio 2005 Team Foundation Server (services) - ENU'

$tfsStatus = new-object psobject
$tfsStatus.psobject.typenames[0] = "TfsServerConfigurationObject"

### App Tier
$installLocation = $(get-itemproperty $regPath).InstallLocation
$tfsStatus | add-member noteproperty AppTierInstallLocation $installLocation

$topWebConfigPath = join-path $installLocation 'Web Services\web.config'
$tfsStatus | add-member noteproperty AppTierMainWebConfigPath $topWebConfigPath

$servicesWebConfigPath = join-path $installLocation 'Web Services\Services\web.config'
$tfsStatus | add-member noteproperty AppTierServicesWebConfigPath $servicesWebConfigPath

$topWebConfig = [xml](get-content $topWebConfigPath)
$appSettings = $topWebConfig.configuration.appSettings
$tfsNameUrl = $appSettings.SelectSingleNode('add[@key="TFSNameUrl"]').value
$tfsStatus | add-member noteproperty AppTierMainWebConfigTfsNameUrl $tfsNameUrl
$tfsStatus | add-member noteproperty AppTierMainWebConfigAllSettings $appSettings.add

$servicesWebConfig = [xml](get-content $servicesWebConfigPath)
$appSettings = $servicesWebConfig.configuration.appSettings
$connectionString = $appSettings.SelectSingleNode('add[@key="ConnectionString"]').value
$tfsStatus | add-member noteproperty AppTierServicesWebConfigConnectionString $connectionString
$tfsStatus | add-member noteproperty AppTierServicesWebConfigAllSettings $appSettings.add

### Data Tier
$sqlConn = new-object 'system.data.sqlclient.SqlConnection' $connectionString
$sqlConn.Open()

$dbConnections = runQuery $sqlConn 'select name,dbname,servername,connection from tbl_database'
$tfsStatus | add-member noteproperty DataTierDatabaseConnections $dbConnections

$serviceInterfaces = runQuery $sqlConn 'select name,url from tbl_service_interface'
$tfsStatus | add-member noteproperty DataTierServiceInterfaces $serviceInterfaces

# AT Stamp
$atStamp = runQuery $sqlConn "select value from tbl_registration_extended_attributes where name='ATMachineName'"
$tfsStatus | add-member noteproperty DataTierAppTierStamp $atStamp
$tfsStatus | add-member noteproperty DataTierAppTierStampPingCheck (ping-hostname $atstamp)

$reportsUrl = runQuery $sqlConn "select url from tbl_service_interface where name='BaseReportsUrl'"
$tfsStatus | add-member noteproperty ServicesReportsServer $reportsUrl
$tfsStatus | add-member noteproperty ServicesReportsServerCheck (ping-url $reportsUrl)

# Reports
$reportsService = runQuery $sqlConn "select url from tbl_service_interface where name='ReportsService'"
$tfsStatus | add-member noteproperty ServicesReportsWebService  $reportsService
$tfsStatus | add-member noteproperty ServicesReportsWebServiceCheck (ping-url $reportsService)

$reportsListMethods = $reportsService + '/ListSecureMethods'
$tfsStatus | add-member noteproperty ServicesReportsWebServiceListSecureMethods $reportsListMethods
$tfsStatus | add-member noteproperty ServicesReportsWebServiceListSecureMethodsCheck (ping-url $reportsListMethods)

# Sharepoint
$sharepointUrl = runQuery $sqlConn "select url from tbl_service_interface where name='BaseServerUrl'"
$tfsStatus | add-member noteproperty ServicesSharepoint $sharepointUrl
$tfsStatus | add-member noteproperty ServicesSharepointCheck (ping-url $sharepointUrl)

$sharepointSitesAsmx = $sharepointUrl + '/_vti_bin/sites.asmx'
$tfsStatus | add-member noteproperty ServicesSharepointSitesAsmx $sharepointSitesAsmx
$tfsStatus | add-member noteproperty ServicesSharepointSitesAsmxCheck (ping-url $sharepointSitesAsmx)

$sharepointAdmin = runQuery $sqlConn "select url from tbl_service_interface where name='WssAdminService'"
$tfsStatus | add-member noteproperty ServicesSharepointAdmin $sharepointAdmin
$tfsStatus | add-member noteproperty ServicesSharepointAdminCheck (ping-url $sharepointAdmin)

$sqlConn.Close()

$tfsStatus