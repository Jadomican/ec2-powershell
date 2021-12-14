#Take an example running instance in the account for
$exampleInstanceId = aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query Reservations[0].Instances[].InstanceId --output text

#Get base64 encoding of the screenshot
$imageb64 = aws ec2 get-console-screenshot --instance-id $exampleInstanceId --query ImageData --output text

#Convert to image in the same directory 
$filename = '.\restored.png'
$bytes = [Convert]::FromBase64String($imageb64)
[IO.File]::WriteAllBytes($filename, $bytes)
