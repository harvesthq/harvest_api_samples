$Url = "https://api.harvestapp.com/v2/users/me"
$Headers = @{}
$Headers.Add("Authorization", "Bearer " + $Env:HARVEST_ACCESS_TOKEN)
$Headers.Add("Harvest-Account-ID", $Env:HARVEST_ACCOUNT_ID)

[system.Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri $Url -Headers $Headers).RawContentStream.ToArray()) | ConvertFrom-Json 
