# This is Cyberark SAAS login uri to authenticate...if using on prem change this.
$EPMLoginUri = "https://login.epm.cyberark.com/EPM/API/23.10.2.3733/Auth/EPM/Logon"

$Username = "changeme@doamin.com"
$Password = "changeme"
$SetID = "changeme"
$ApplicationID = "your company name" # <-- This can be anything, its used to tag your api calls for cyberark
$ComputerName = "changeme" # Dont assign a prefix or suffix to this. dont use: computer.domain.com, just use computername
$Username = "DOMAIN\changeme"
$Duration = "8" # Values Allowed 1-72
$Date = Get-Date -Format yyyy-MM-dd-mm-ss
$PolicyName = "JIT" + "-" + $Date

## AUTHENTICATE ##

$EPMBody = @{ 

        "Username" = $Username;
        "Password" = $Password;
        #This can be change to anything to identify who is requesting the authentication
        "ApplicationID" = $ApplicationID
    } | ConvertTo-Json

$EpmHeader = @{ "Authorization" ="Basic"}
$epmauth = Invoke-WebRequest -Uri $EPMLoginUri -ContentType application/json -Body $EPMBody -Method Post


# CYBERARK AUTH HEADERS BUILD FOR ENTIERE SCRIPT
$epmcontent = $epmauth.content | Convertfrom-Json
$authtoken =  $epmcontent.EPMAuthenticationResult
$EpmHeader = @{ "Authorization" ="Basic " + $AuthToken }


# NA180.epm.cyberark.com is one of many instances. to get yours, just log into cyberark and see which one you are on.
$NewPolicyURI = "https://na180.epm.cyberark.com/EPM/API/Sets/$SetID/Policies/Server"
$ComputerEPMAPI = "https://na180.epm.cyberark.com/EPM/API/Sets/$SetID/Computers?`$filter=ComputerName eq '$($ComputerName)'"

# URI TO DO A STARTS WITH QUERY
#$ComputerEPMAPI = "https://na180.epm.cyberark.com/EPM/API/Sets/3af74ebe-50b0-46b6-b9ed-e33ec1b2c515/Computers?`$filter=contains(ComputerName, 'T1209')"

$DeviceWebRequest = Invoke-WebRequest -Uri $ComputerEPMAPI -ContentType application/json -Method GET -Headers $EpmHeader

$Computer = $DeviceWebRequest.Content | ConvertFrom-Json
$Computers = $Computer.Computers

# If you want to do multiple computers, loop through the $Computers object and for each loop, get the agent id & do the rest call.
$AgentID = $Computers.AgentId

$JITBody = @{
    "Name"= "$($PolicyName)";
    "IsActive" = "true";
    "IsAppliedToAllComputers"= "false";
    "PolicyType"= 40;
    "Action"= 20;
    "Duration"= $Duration;
    "KillRunningApps"= "false";
    "Audit"= "true";
    "Executors"= @(
        [pscustomobject]@{
            "Id"= "$($AgentID)";
            "ExecutorType"= 1
        }
        );
    
    "Accounts"= @(
        [pscustomobject]@{
            "DisplayName" = "$($Username)";
            "SamName" = "$($Username)";
            "AccountType"= 1
        }
        );
    
    "TargetLocalGroups" = @(
        [pscustomobject]@{
            "AccountType"= 0;
            "DisplayName"= "Administrators"
        }
        )
} | ConvertTo-Json -Depth 5

Invoke-WebRequest -Uri $NewPolicyURI -ContentType application/json -Method Post -Headers $EpmHeader -Body $JITBody


