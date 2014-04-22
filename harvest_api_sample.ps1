#REQUIRES -Version 2.0
<#  
.SYNOPSIS  
    A simple example of how to call the Harvest Time Tracking API with basic authentication to list projects.        
.DESCRIPTION  

    Basic API demo. Use this sample as a starting point on how to connect, authenticate, and send requests 
    to the Harvest API from PowerShell. This is not a libary!
    
.NOTES  
    Author         : Joakim Westin (joakim@jwab.net)
    Prerequisite   : PowerShell V2 over Vista and upper.

#>


param(
    [string]$account = 'subdomain',
    [string]$username = 'user@example.com',
    [string]$password = 'yourpassword'
)

# Set the account specific URI
$uri = "https://$account.harvestapp.com/projects"

# Build the authorization header from username & password
$auth = 'Basic ' + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($username+":"+$password ))


# Create the web client and set the required headers
$req = New-Object System.Net.WebClient
$req.Headers.Add('Content-Type', 'application/xml')
$req.Headers.Add('Accept', 'application/xml')
$req.Headers.Add('Authorization', $auth )


# Issue the reqest and store the rewturned XML in the 
[xml]$result = $req.DownloadString($uri)

<# 
    Now the response is available for anything you may want to do with it in the $result variable. To simply 
    list the projects you can try this:
#>

# List all project names, code and notes using a Grid-View (or in whateer way you like)
$result.projects.project | select name, Code, Notes | Out-GridView

