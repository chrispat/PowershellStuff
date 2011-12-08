# $excel = new-object -comobject excel.application
# $excel.visible = $true
# 
# $path = 'C:\Users\peterpr\Desktop\Extensibility DCR Crew Planning.xlsx'
# $workbook = $excel.Workbooks.Open($path)
# 
# # $workbook.Worksheets.Item("Planning").Activate()
# $worksheet = $workbook.Worksheets.Add()
 
$tfs = get-tfs http://vstfdevdivir:8080

$wi = $tfs.WIT.GetWorkItem(96623) 

$wi.WorkItemLinks | ? { $_.LinkType.Name -eq "Child" } | % {
	$child = $tfs.WIT.GetWorkItem($_.TargetId)
	write-host "$($child.Id) - $($child.Title) [$($child.Fields['Remaining Work'].Value)]"
}
