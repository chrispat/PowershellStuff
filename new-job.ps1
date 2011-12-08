# New-Job.ps1
# This script creates an object that can be used to invoke a 
# scriptblock asynchronously.
#
param ( [scriptblock]$scriptToRun )
##
## Object Created - Custom Object
##
## METHODS
##
## void InvokeAsync([string] $script, [array] $input = @())  
## Invokes a script asynchronously.
## void Stop([bool] $async = $false) # Stop the pipeline.
## 
## PROPERTIES
##
## [System.Management.Automation.Runspaces.LocalPipeline] LastPipeline      
##      The last pipeline that executed.
## [bool] IsRunning                                                         
##      Whether the last pipeline is still running.
## [System.Management.Automation.Runspaces.PipelineState] LastPipelineState 
##      The state of the last pipeline to be created.
## [array] Results                                                          
##      The output of the last pipeline that was run.
## [array] LastError                                                        
##      The errors produced by the last pipeline run.
## [object] LastException                                                   
##      If the pipeline failed, the exception that caused it to fail.
##
## Private Fields
##
## [array] _lastOutput    # The objects output from the last pipeline run.
## [array] _lastError     # The errors output from the last pipeline run.
#region Message
$MultiplePipeline = "A pipeline was already running.   " +
    "Cannot invoke two pipelines concurrently."
##
## MAIN
##
# First check to be sure that there is a Job array
if ( test-path variable:jobs )
{
    if ( $global:jobs -isnot [array] )
    {
        throw '$jobs exists and is not an array'
    }
}
else
{
    $global:jobs = @()
}

# Create a runspace and open it
$config = [Management.Automation.Runspaces.RunspaceConfiguration]::Create()
$runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($config)
$runspace.Open()
# Create the object - we'll use this as the collector for the entire job.
$object = new-object System.Management.Automation.PsObject
# Add the object as a note on the runspace
$object | add-member Noteproperty Runspace $runspace 
# Add a field for storing the last pipeline that was run.
$object | add-member Noteproperty LastPipeline $null 
# Add an invoke method to the object that takes a script to invoke asynchronously.
$invokeAsyncBody = {
  if ($args.Count -lt 1)
  {
    throw 'Usage: $obj.InvokeAsync([string] $script, [Optional][params][array]$inputObjects)'
  }
  & { 
    [string]$script, [array] $inputArray =  @($args[0])
    $PipelineRunning = [System.Management.Automation.Runspaces.PipelineState]::Running
    # Check that there isn't a currently executing pipeline.
    # Only one pipeline may run at a time.
    if ($this.LastPipeline -eq $null -or 
        $this.LastPipeline.PipelineStateInfo.State -ne $PipelineRunning )
    {
      $this.LastPipeline = $this.Runspace.CreatePipeline($script)
      # if there's input, write it into the input pipeline.
      if ($inputArray.Count -gt 0)
      {
        $this.LastPipeline.Input.Write($inputArray, $true) 
      }
      $this.LastPipeline.Input.Close()
      # Set the Results and LastError to null.
      $this.Results   = $null
      $this.LastError = $null
      # GO!
      $this.LastPipeline.InvokeAsync()
    }
    else
    {
      # A pipeline was running.  Report an error.
      throw 
    }
  } $args
}
$object | add-member ScriptMethod InvokeAsync $invokeAsyncBody 
# Adds a getter script property that lets you determine whether the runspace is still running.
$get_isRunning = { 
  $PipelineRunning = [System.Management.Automation.Runspaces.PipelineState]::Running  
  return -not ($this.LastPipeline -eq $null -or
               $this.LastPipeline.PipelineStateInfo.State -ne $PipelineRunning  )
}
$object | add-member ScriptProperty IsRunning $get_isRunning
# Add a getter for finding out the state of the last pipeline.
$get_PipelineState = { return $this.LastPipeline.PipelineStateInfo.State }
$object | add-member ScriptProperty LastPipelineState $get_PipelineState
# Add a getter script property that lets you get the last output.
$get_lastOutput = {
  if ($this._lastOutput -eq $null -and -not $this.IsRunning)
  {
    $this._lastOutput = @($this.LastPipeline.Output.ReadToEnd())
  }
  return $this._lastOutput
}
$set_lastOutput = { $this._lastOutput = $_ }
$object | add-member ScriptProperty Results $get_lastOutput $set_lastOutput
$object | add-member Noteproperty _lastOutput $null 
# Add a getter for finding out the last exception thrown if any.
$get_lastException = {
  if ($this.LastPipelineState -eq "Failed" -and -not $this.IsRunning)
  {
    return $this.LastPipeline.PipelineStateInfo.Reason
  }
}
$object | add-member ScriptProperty LastException $get_lastException
# Add a getter script property that lets you get the last errors.
$get_lastError = {
  if ($this._lastError -eq $null -and -not $this.IsRunning)
  {
    $this._lastError = @($this.LastPipeline.Error.ReadToEnd())
  }
  return $this._lastError
}
$set_lastError = { $this._lastError = $args[0] }
$object | add-member ScriptProperty LastError $get_lastError $set_lastError
$object | add-member Noteproperty _lastError $null 
# Add a script method for stopping the execution of the pipeline.
$stopScript = {
  if ($args.Count -gt 1)
  {
    throw 'Too many arguments.  Usage: $object.Stop([optional] [bool] $async'
  }
  if ($args.Count -eq 1 -and [bool] $args[0])
  {
    $this.LastPipeline.StopAsync()
  }
  else
  {
    $this.LastPipeline.Stop()
  }
}
$object | add-member ScriptMethod Stop $stopScript 
# finally, attach the script to run to the object
$object | add-member Noteproperty Command $scriptToRun  
# Ensure that the object has a "type" for which we can build a 
# formatting file.
$object.Psobject.typenames[0] = "PowerShellJobObject"
$object.InvokeAsync($scriptToRun)
#$object
$object | add-member NoteProperty JobId $jobs.count 
"Job " + $jobs.count + " Started"
# Since we add this job to the we need to be sure that
# we can remove jobs.  The clear-job function will allow for that
$global:jobs += $object

