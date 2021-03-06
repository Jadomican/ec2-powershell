# Jason Domican 2018
# Take a backup before running these, you madman

# Downloads, unzips and installs the latest AWS PV Drivers on your EC2 instance
# The process will restart AWS PV Driver instances multiple times - prepare for downtime for a few minutes

$downloadFolderPath = "C:\Users\Administrator\Downloads"
$fileName = "PV-Drivers-" + (Get-Date -Format yyyy-dd-MM-ddHHmmssffff).ToString()

Invoke-WebRequest -Uri https://s3.amazonaws.com/ec2-windows-drivers-downloads/AWSPV/Latest/AWSPVDriver.zip -OutFile $downloadFolderPath\$fileName.zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
function unzip {
    param( [string]$ziparchive, [string]$extractpath )
    [System.IO.Compression.ZipFile]::ExtractToDirectory( $ziparchive, $extractpath )
}

unzip "$downloadFolderPath\$fileName.zip" "$downloadFolderPath\$fileName"
& $downloadFolderPath\$fileName\AWSPVDriverSetup.msi /quiet