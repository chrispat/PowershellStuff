# Script to find a Team Foundation workspace
param(
    [string] $workspaceHint = $(get-location).Path
)

begin
{
    # load the needed client dll's
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.VersionControl.Client")

    # fetches a Workspace instance matching the WorkspaceInfo found in the cache file
    function getWorkspaceFromWorkspaceInfo($wsInfo)
    {
        $tfs = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($wsInfo.ServerUri.AbsoluteUri)
        $vcs = $tfs.GetService([Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer])
        $vcs.GetWorkspace($wsInfo)
        # TODO: likely add some convenience properties/methods for easier scripting support
    }
}

process
{
    # is there only 1 workspace in our cache file?  If so, use that one regardless of the hint
    $workspaceInfos = [Microsoft.TeamFoundation.VersionControl.Client.Workstation]::Current.GetAllLocalWorkspaceInfo()
    if ($workspaceInfos.Length -eq 1)
    {
        return getWorkspaceFromWorkspaceInfo($workspaceInfos[0])
    }

    if (test-path $workspaceHint)
    {
        # workspace hint is a local path, get potential matches based on path
        # is the path itself mapped?
        $workspaceInfos = [Microsoft.TeamFoundation.VersionControl.Client.Workstation]::Current.GetLocalWorkspaceInfo((resolve-path $workspaceHint))
        if ($workspaceInfos -ne $null)
        {
            # this path is mapped, so we go with this workspace info in an array by itself
            $workspaceInfos = @($workspaceInfos)
        }
        else
        {
            # this path isn't mapped, so we do a recursive check instead
            $workspaceInfos = [Microsoft.TeamFoundation.VersionControl.Client.Workstation]::Current.GetLocalWorkspaceInfoRecursively((resolve-path $workspaceHint))
        }
    }
    else
    {
        # workspace hint is NOT a local path, get potential matches based on name
        $workspaceInfos = @($workspaceInfos | ?{ $_.name -match $workspaceHint })
    }

    if ($workspaceInfos.Length -gt 1)
    {
        throw 'More than one workspace matches the workspace hint "{0}": {1}' -f
                $workspaceHint, [string]::join(', ', @($workspaceInfos | %{ $_.Name}))
    }
    elseif ($workspaceInfos.Length -eq 1)
    {
        return getWorkspaceFromWorkspaceInfo($workspaceInfos[0])
    }
    else
    {
        throw "Could not figure out a workspace based on hint $workspaceHint"
    }
}
