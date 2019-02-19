#Check PowerShell version, if less than version 5 inform user
$desiredPowershellVersion = 5

if ($PSVersionTable.PSVersion.Major -lt $desiredPowershellVersion){Write-Host "`nPowerShell less than version $desiredPowershellVersion detected, consider upgrading to version $desiredPowershellVersion!`n"}

#Fetch instance details from meta-data
$instanceId = (Invoke-WebRequest -UseBasicParsing -uri 'http://169.254.169.254/latest/meta-data/instance-id').Content
$az = ((Invoke-WebRequest -UseBasicParsing -uri 'http://169.254.169.254/latest/meta-data/placement/availability-zone').Content)
$region = $az.Substring(0,$az.Length-1)

#The operation to perform (Scan or Install)
$patchingOperation = 'Scan'
$patchBaselineModuleLocation = 'C:\Program Files\Amazon\PatchBaselineOperations'

#This block tests S3 connectivity by attempting to download a PB snapshot
Write-Host "Attempting to download a patch baseline snapshot from S3..."
$snap = Get-SSMDeployablePatchSnapshotForInstance -SnapshotId af258f6e-7371-472f-a69a-d3e56f2df9ae -InstanceId $instanceId -Verbose 
(New-Object Net.WebClient).DownloadFile($snap.SnapshotDownloadUrl, "C:\pbsnapshot.json")

if ($?) {write-Host ('File downloaded successfully from ' + $snap.SnapshotDownloadUrl)}

#If the Amazon.PatchBaselineOperations.dll file does not exist in "C:\Program Files\Amazon\PatchBaselineOperations", it can be downloaded from here
#https://s3-<region>.amazonaws.com/aws-ssm-<region>/patchbaselineoperations/Amazon.PatchBaselineOperations-1.12.zip

if (-not (Test-Path $patchBaselineModuleLocation))
{
    Write-Host "PatchBaselineOperations not found, downloading now..."
    if(-not ($region.Equals('us-east-1')))
    {
        (New-Object Net.WebClient).DownloadFile("https://s3-$region.amazonaws.com/aws-ssm-$region/patchbaselineoperations/Amazon.PatchBaselineOperations-1.12.zip", "$patchBaselineModuleLocation.zip")
    }
    else
    {
        (New-Object Net.WebClient).DownloadFile("https://s3.amazonaws.com/aws-ssm-$region/patchbaselineoperations/Amazon.PatchBaselineOperations-1.12.zip", "$patchBaselineModuleLocation.zip")
    }
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    function Unzip
    {
        param([string]$zipfile, [string]$outpath)

        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
    }
    Unzip "$patchBaselineModuleLocation.zip" "$patchBaselineModuleLocation"
}
else
{
    Write-Host 'PatchBaselineOperations found, performing patch operation...'
}

#This calls the Patch Baseline operation manually with the -Debug option
$psModuleInstallFile="$patchBaselineModuleLocation\Amazon.PatchBaselineOperations.dll"
Import-Module $psModuleInstallFile
Invoke-PatchBaselineOperation -Operation $patchingOperation -SnapshotId '' -InstanceId $instanceId -Region $region -Debug