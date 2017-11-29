url = "https://api.harvestapp.com/v2/users/me"

Set wshShell = CreateObject("WScript.Shell")
authorization = wshShell.ExpandEnvironmentStrings("Bearer %HARVEST_ACCESS_TOKEN%")
accountID = wshShell.ExpandEnvironmentStrings("%HARVEST_ACCOUNT_ID%")

Set request = CreateObject("MSXML2.ServerXMLHTTP.6.0")
request.open "GET", url

request.setRequestHeader "User-Agent", "VBScript Harvest API Sample"
request.setRequestHeader "Authorization", authorization
request.setRequestHeader "Harvest-Account-ID", accountID

request.send

WScript.echo request.responseText
