param ([string] $tfsServer = $(throw 'tfs server is required'))

$tfsServer = normalize-server-url $tfsServer
write-debug "Normalized TFS server to $tfsServer"
$adminAsmxUrl = get-tfs-wss-adminAsmxUrl $tfsServer
write-debug "Found admin.asmx URL for server of $adminAsmxUrl"
$languages = get-wss-languages $adminAsmxUrl
write-debug "Got languages response of $languages"

# convert to a more meaningful string with CultureInfo
$languages |
 %{ '{0} = {1}' -f $_, (new-object 'globalization.cultureinfo' ([int]$_)).DisplayName }
