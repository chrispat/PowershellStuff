param (
	[string] $addonname = $(throw "addonname required."), #required parameter
	[string] $source = "wowace"
)

$wc = new-object System.Net.WebClient;

$api_key = "?api-key=8bb80a603bcd39e65d95c137bef853696250c2de"

if ($source -eq "wowace") {
	$urlBase = "http://www.wowace.com"
} elseif ($source -eq "curseforge") {
	$urlBase = "http://www.curseforge.com"
} else {
	throw 'Invalid $source provided'
}

$html = $wc.DownloadString("$urlBase/projects/$addonname/$api_key")
$html -match ".*<a href=`"(?<url>.*)`"><span>Download</span></a>.*"

$url_path = $matches["url"]

$url = "$urlBase$url_path$api_key"
$html2 = $wc.DownloadString($url)

$html2 -match ".*<a href=`"(?<url>.*)`"><span>Download</span></a>.*"

$zipurl = $matches["url"]
$filename = $zipurl.Split("/")[-1]

$wc.DownloadFile($zipurl, "$home\Desktop\$filename")
