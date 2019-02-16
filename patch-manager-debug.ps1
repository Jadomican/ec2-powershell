#Fetch instance details from meta-data
$instanceId = (Invoke-WebRequest -UseBasicParsing -uri 'http://169.254.169.254/latest/meta-data/instance-id').Content
$az = ((Invoke-WebRequest -UseBasicParsing -uri 'http://169.254.169.254/latest/meta-data/placement/availability-zone').Content)
$region = $az.Substring(0,$az.Length-1)
Write-Host $region

#The operation to perform (Scan or Install)
$patchingOperation = 'Scan'

#This block tests S3 connectivity by attempting to download a PB snapshot
Write-Host "Attempting to download a patch baseline snapshot from S3..."
$snap = Get-SSMDeployablePatchSnapshotForInstance -SnapshotId af258f6e-7371-472f-a69a-d3e56f2df9ae -InstanceId $instanceId -Verbose 
(New-Object Net.WebClient).DownloadFile($snap.SnapshotDownloadUrl, "C:\pbsnapshot.json")

if ($?) {write-Host ('File downloaded successfully from ' + $snap.SnapshotDownloadUrl)}

#If the Amazon.PatchBaselineOperations.dll file does not exist in "C:\Program Files\Amazon\PatchBaselineOperations", it can be downloaded from here
#https://s3-<region>.amazonaws.com/aws-ssm-<region>/patchbaselineoperations/Amazon.PatchBaselineOperations-1.12.zip

if (-not (Test-Path 'C:\Program Files\Amazon\PatchBaselineOperations'))
{
    Write-Host "PatchBaselineOperations not found, downloading now..."
    if(-not ($region.Equals('us-east-1')))
    {
        (New-Object Net.WebClient).DownloadFile("https://s3-$region.amazonaws.com/aws-ssm-$region/patchbaselineoperations/Amazon.PatchBaselineOperations-1.12.zip", "C:\Program Files\Amazon\PatchBaselineOperations.zip")
    }
    else
    {
        (New-Object Net.WebClient).DownloadFile("https://s3.amazonaws.com/aws-ssm-$region/patchbaselineoperations/Amazon.PatchBaselineOperations-1.12.zip", "C:\Program Files\Amazon\PatchBaselineOperations.zip")
    }
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    function Unzip
    {
        param([string]$zipfile, [string]$outpath)

        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
    }
    Unzip "C:\Program Files\Amazon\PatchBaselineOperations.zip" "C:\Program Files\Amazon\PatchBaselineOperations"
}
else
{
    Write-Host 'PatchBaselineOperations found, performing patch operation...'
}

#This calls the Patch Baseline operation manually with the -Debug option
$psModuleInstallFile="C:\Program Files\Amazon\PatchBaselineOperations\Amazon.PatchBaselineOperations.dll"
Import-Module $psModuleInstallFile
Invoke-PatchBaselineOperation -Operation $patchingOperation -SnapshotId '' -InstanceId $instanceId -Region $region –Debug