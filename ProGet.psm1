<#
.SYNOPSIS  
    A module for working with the Proget API
.DESCRIPTION  
    This module uses the REST API on a ProGet server to work with feeds and Nuget packages
.NOTES  
    File Name    : ProGet.psm1
    Author       : Joel Newton - jnewton@springcm.com
    Requires     : PowerShell V3
    Dependencies : none

#>

######################
#CONSTANTS

$ScriptLocation = split-path -parent $MyInvocation.MyCommand.Path
$ProGetSettings = Get-Content -Path "$ScriptLocation\Settings.json" | Out-String | ConvertFrom-Json

$API_KEY = $ProGetSettings.API_KEY

$NuGet_API_Key = $ProGetSettings.NuGet_API_Key

######################


Function Get-FeedList {

    [CmdletBinding()]
    param (
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL
    )

    begin {

        $API_BaseURI = "$ProGetServerURL/api/json"

    }

    process {
        #Retrieve the package and version requested
        $URI = "$API_BaseURI/Feeds_GetFeeds?API_Key=$API_KEY"
        $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing
        $Feeds = $Request.Content | ConvertFrom-Json
        $Feeds.Feed_Name

    }
}


Function Get-FeedID{

    
    [CmdletBinding()]
    param (

   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName
    )

    begin {

        $API_BaseURI = "$ProGetServerURL/api/json"

    }

    process {

        #Retrieve the ID for the feed
        $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$FeedName" -UseBasicParsing
        $Feed = $Request.Content | ConvertFrom-Json

        Write-Output($Feed.Feed_Id)

    }

}


Function Test-PackageIsInFeed {

    [CmdletBinding()]
    param (
    
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName,
        [Parameter(Mandatory=$true)]
        $PackageName

    )

    begin {

        $API_BaseURI = "$ProGetServerURL/api/json"

    }

    process {

        #Retrieve the ID for the feed
        $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$FeedName" -UseBasicParsing
        $Feed = $Request.Content | ConvertFrom-Json

        #Retrieve the package and version requested
        $URI = "$API_BaseURI/NuGetPackages_GetLatest?API_Key=$API_KEY&Feed_Id=" + $Feed.Feed_Id + "&PackageIds_Psv=$PackageName"
        $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing
        $Package = $Request.Content | ConvertFrom-Json

        #If it is found, return TRUE
        If ($Package){

            Write-Verbose "$PackageName package found at $API_BaseURI"
            Write-Output $true
        }
        #Otherwise, return false
        Else {
    
            Write-Verbose "$PackageName package not found at $API_BaseURI"
            Write-Output $false
        }

    }
}


Function Test-PackageVersionIsInFeed {

    [CmdletBinding()]
    param (

   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName,
        [Parameter(Mandatory=$true)]
        $PackageName,
        [Parameter(Mandatory=$true)]
        $PackageVersion
    )

    begin {
 
        $API_BaseURI = "$ProGetServerURL/api/json"

   }

    process {

        #Retrieve the ID for the feed
        $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$FeedName" -UseBasicParsing
        $Feed = $Request.Content | ConvertFrom-Json

        #Retrieve the package and version requested
        $URI = "$API_BaseURI/NuGetPackages_GetPackage?API_Key=$API_KEY&Feed_Id=" + $Feed.Feed_Id + "&Package_Id=$PackageName&Version_Text=$PackageVersion"
        $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing
        $Package = $Request.Content | ConvertFrom-Json

        #If they exist, return TRUE
        If ($Package.NuGetPackages_Extended){

            Write-Verbose "$PackageName version $Package.Version_Text found at $API_BaseURI"
            Write-Output $true
        }
        #Otherwise, return false
        Else {
    
            Write-Verbose "$PackageName version $PackageVersion not found at $API_BaseURI"
            Write-Output $false
        }

    }
}

Function Remove-PackageVersionFromFeed {

    [CmdletBinding(SupportsShouldProcess=$true,
        ConfirmImpact="High")]
    param (

   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName,
        [Parameter(Mandatory=$true)]
        $PackageName,
        [Parameter(Mandatory=$true)]
        $PackageVersion,
        [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]
        $Credentials
       
    )

    begin {

        $URI = "$ProGetServerURL/nuget/$FeedName/$PackageName/$PackageVersion"
    
    }

    process {

        If ($PScmdlet.ShouldProcess("Delete this package version?")){
            Invoke-RestMethod -Method Delete -Uri "$URI" -Credential $Credentials -Headers @{"Content-Type"="text/html";"X-NuGet-ApiKey"="$NuGet_API_Key"}
        }

    }
}


Function Get-LatestPackageVersion {

    [CmdletBinding()]
    param (
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName,
        [Parameter(Mandatory=$true)]
        $PackageName
    )

    begin {

        $API_BaseURI = "$ProGetServerURL/api/json"

    }

    process {

        #Retrieve the ID for the feed
        $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$FeedName" -UseBasicParsing
        $Feed = $Request.Content | ConvertFrom-Json

        #Retrieve the package and version requested
        $URI = "$API_BaseURI/NuGetPackages_GetLatest?API_Key=$API_KEY&Feed_Id=" + $Feed.Feed_Id + "&PackageIds_Psv=$PackageName"
        $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing
        $PackageVersion = $Request.Content | ConvertFrom-Json

        Write-Output($PackageVersion.Version_Text)

    }
}

Function Get-Latest {

    [CmdletBinding()]
    param (
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName
    )

    begin {

        $API_BaseURI = "$ProGetServerURL/api/json"

    }

    process {

        #Retrieve the ID for the feed
        $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$FeedName" -UseBasicParsing
        $Feed = $Request.Content | ConvertFrom-Json

        #Retrieve the package and version requested
        $URI = "$API_BaseURI/NuGetPackages_GetLatest?API_Key=$API_KEY&Feed_Id=" + $Feed.Feed_Id 
        $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing
        $PackageVersion = $Request.Content | ConvertFrom-Json

        Write-Output($PackageVersion)

    }
}

Function Get-Package{

    [CmdletBinding()]
    param (
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName,
        [Parameter(Mandatory=$true)]
        $PackageName
    )

    begin{

        $URI = "$ProGetServerURL/nuget/$FeedName/Packages()?`$format=json&`$filter=Id eq '$PackageName'"

    }

    process {

        $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing

        $PackageVersion = $Request.Content | ConvertFrom-Json

        Write-Output($PackageVersion.d.results)
    }
}



Function Copy-PackageToFeed {
<#
.SYNOPSIS
   This script retrieves the latest versions of the packages on the specified origin feed and pushes them to the specified destination feed
	
.NOTES
    PARAMETERS:
    $ProGetServerURL
    $PackageName
    $PackageVersion
    $OriginFeedName
    $DestinationFeedName

.EXAMPLE
    Copy-PackageToFeed -ProGetServerURL http://progetserver -PackageName Web -PackageVersion 1.1.0 -OriginFeedName Branch -DestinationFeedName Release

#>
    [CmdletBinding()]
    param(
 
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
	    [Parameter(Mandatory=$true)]
        [string[]]$PackageList,
   	    [Parameter(Mandatory=$true)]
        $PackageVersion,
   	    [Parameter(Mandatory=$true)]
        $OriginFeedName,
   	    [Parameter(Mandatory=$true)]
        $DestinationFeedName
    )

    begin{

        $API_BaseURI = "$ProGetServerURL/api/json"
        $SourceFeed = "$ProGetServerURL/nuget/$OriginFeedName"
        $ListTargetPackage = "$ProGetServerURL/nuget/$DestinationFeedName"
        $PushPackageURL = "$ProGetServerURL/api/v2/package/$DestinationFeedName"

        $TempDir = $env:TEMP + '\ProGet_'+ ((get-date -Format o) -replace ':','-')
        New-Item -Path $TempDir -ItemType Directory | Out-Null

        #For encoding content
        $CODEPAGE = "iso-8859-1" 
        #Linefeed character
        $LF = "`r`n"

    }
    process{

        ForEach ($PackageName in $PackageList){

            #Make sure the package name and version exist in the origin feed before trying to promote
            $PackageFound = Test-PackageVersionIsInFeed -ProGetServerURL $ProGetServerURL -FeedName $OriginFeedName -PackageName $PackageName -PackageVersion $PackageVersion 
            If ($PackageFound -eq $false){

                $ThrowMessage = "Package $PackageName version $PackageVersion was not found in $SourceFeed."
                Throw($ThrowMessage)
            }

            #Make sure this version of this package doesn't exist in the destination feed before trying to promote
            $PackageFound = Test-PackageVersionIsInFeed -ProGetServerURL $ProGetServerURL -FeedName $DestinationFeedName -PackageName $PackageName -PackageVersion $PackageVersion 
            If ($PackageFound -eq $true){

                $ThrowMessage = "Package $PackageName version $PackageVersion already exists in $ListTargetPackage."
                Throw($ThrowMessage)
            }

            #Retrieve the ID for the feed
            $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$OriginFeedName"
            $Feed = $Request.Content | ConvertFrom-Json

            #Download the package locally
            $url = ($SourceFeed + '/package/' + $PackageName + '/' + $PackageVersion)
            $LocalPackage = "$TempDir\$PackageName.$PackageVersion.nupkg"
            (New-Object System.Net.WebClient).DownloadFile($url, $LocalPackage)

            #Construct destination URL and headers
            $DestinationURL = "http://progetna11/nuget/$DestinationFeedName/package/"
            $headers = @{ "Content-Type"="multipart/form-data";"X-NuGet-ApiKey"="$NuGet_API_Key" }

            #Read file byte-by-byte
            $fileBin = [System.IO.File]::ReadAllBytes($LocalPackage)

            #Convert byte-array to string
            $enc = [System.Text.Encoding]::GetEncoding($CODEPAGE)
            $fileEnc = $enc.GetString($fileBin)

            #Create a boundary indicating the beginning and end of the package data
            $boundary = [System.Guid]::NewGuid().ToString()

            #Build the body
            $bodyLines = @(
            "------$boundary",
            "Content-Disposition: form-data; name=`"package`"; filename=`"$PackageName.$PackageVersion.nupkg`"",
            "Content-Type: application/octet-stream$LF",
            $fileEnc,
            "------$boundary--$LF"
            ) -join $LF

            try {
                # Submit form-data with Invoke-RestMethod-Cmdlet
                Invoke-RestMethod -Uri $DestinationURL -Method PUT -ContentType "multipart/form-data; boundary=----$boundary" -Body $bodyLines -Headers $headers
            } catch {
                $message = $_.ErrorDetails.Message | ConvertFrom-json | Select-Object -expandproperty message
                $ErrorOutput = '"{0} {1}: {2}' -f $_.Exception.Response.StatusCode.value__,$_.Exception.Response.StatusDescription,($message,$ErrorMessage -ne $null)[0] 
                Write-Error $ErrorOutput
            }

            #Remove the temp local folder
            Remove-Item -Path $TempDir -Recurse | Out-Null

        }

    }

}