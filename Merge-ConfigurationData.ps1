function Merge-ConfigurationData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ParameterSetName="Data")]
        [System.Collections.Hashtable]
        $Template,
        [Parameter(Mandatory=$true,ParameterSetName="Data")]
        [System.Collections.Hashtable]
        $Deployment,
        [Parameter(Mandatory=$true,ParameterSetName="FilePath")]
        [System.String]
        $TemplateFilePath,
        [Parameter(Mandatory=$true,ParameterSetName="FilePath")]
        [System.String]
        $DeploymentFilePath,
        [Parameter(Mandatory=$false)]        
        [System.Collections.Hashtable]
        $Output
    )

    if($PSCmdlet.ParameterSetName -eq "FilePath"){
        $Template = Import-PowerShellDataFile -Path $TemplateFilePath
        $Deployment = Import-PowerShellDataFile -Path $DeploymentFilePath
    }
    
    if($Output -eq $null){
        $Output = $Deployment
    }

    foreach($Property in $Template.GetEnumerator()){
        if($Property.Value -is [System.Collections.Hashtable]){
            Write-Verbose "Key [$($Property.Name)] is a Hashtable"
            if($Deployment.$($Property.Name) -ne $null){
                Write-Verbose "Key [$($Property.Name)] is present in Deployment Data"
                $Output.($Property.Name) = Merge-ConfigurationData -Template $Template.$($Property.Name) -Deployment $Deployment.$($Property.Name) -Output $Output.$($Property.Name)
            }else{
                Write-Verbose "Key [$($Property.Name)] is not present in Deployment Data"
                $Output.Add($($Property.Name),$Template.$($Property.Name))
            }
        }elseif($Property.Value -is [System.Array]){
            Write-Verbose "$($Property.Name) is ein Array"
            Write-Verbose "Total Items in Template Array [$($Property.Value.Count)]"
            Write-Verbose "Total Items in Deployment Array [$($Deployment.$($Property.Name).Count)]"
            if($Deployment.$($Property.Name) -ne $null){
                Write-Verbose "Array is defined in Deployment"
                for($i=0;$i -lt $Property.Value.Count; $i++){ 
                    
                    $SearchItem = $($Property.Value[$i].GetEnumerator() | Where-Object {($_.Value -is [String]) -and ($_.Name -like "*Name")})[0]
                    if($($Deployment.$($Property.Name) | ? { $_.($SearchItem.Name) -eq $SearchItem.Value })){
                        Merge-ConfigurationData -Template $Property.Value[$i] -Deployment $($Deployment.$($Property.Name) | ? { $_.($SearchItem.Name) -eq $SearchItem.Value }) -Output $($Output.$($Property.Name) | ? { $_.($SearchItem.Name) -eq $SearchItem.Value }) | Out-Null
                    }else{
                        Write-Verbose "Pair $($Key.Name) - $($Key.Value) not present"
                        $Output.$($Property.Name) += $Property.Value[$i]
                    }
                }
            }else{
                Write-Verbose "Array is not defined in Deployment"
                $Output.$($Property.Name) = $Template.$($Property.Name)
            }
        }else{
            Write-Verbose "$($Property.Name) is a String or Integer Value"
            if($Deployment.$($Property.Name) -eq $null){

                $Output.Add($Property.Name,$Template.($Property.Name))

            }elseif($Deployment.$($Property.Name) -ne $Property.Value){

            }
        }
    }
    return $Output
}