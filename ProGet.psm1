<#
.SYNOPSIS  
    A module for working with the Proget API
.DESCRIPTION  
    This module queries the APIs for our hosted ProGet servers
.NOTES  
    File Name    : ProGet.psm1
    Author       : Joel Newton - jnewton@springcm.com
    Requires     : PowerShell V3
    Dependencies : (none)

#>

######################
#CONSTANTS

$ScriptLocation = split-path -parent $MyInvocation.MyCommand.Path
$ProGetSettings = Get-Content -Path "$ScriptLocation\Settings.json" | Out-String | ConvertFrom-Json

$API_KEY = $ProGetSettings.API_KEY
$NuGet_API_Key = $ProGetSettings.NuGet_API_Key
######################

Function Get-FeedList {

    param (
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL
    )

    $API_BaseURI = "$ProGetServerURL/api/json"

    #Retrieve the package and version requested
    $URI = "$API_BaseURI/Feeds_GetFeeds?API_Key=$API_KEY"
    $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing
    $Feeds = $Request.Content | ConvertFrom-Json
    $Feeds.Feed_Name

}


Function Test-PackageIsInFeed {

    param (
    
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName,
        [Parameter(Mandatory=$true)]
        $PackageName

    )

    $API_BaseURI = "$ProGetServerURL/api/json"

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


Function Test-PackageVersionIsInFeed {

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

    $API_BaseURI = "$ProGetServerURL/api/json"

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


Function Get-LatestPackageVersion {

    param (
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName,
        [Parameter(Mandatory=$true)]
        $PackageName
    )

    $API_BaseURI = "$ProGetServerURL/api/json"

    #Retrieve the ID for the feed
    $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$FeedName" -UseBasicParsing
    $Feed = $Request.Content | ConvertFrom-Json

    #Retrieve the package and version requested
    $URI = "$API_BaseURI/NuGetPackages_GetLatest?API_Key=$API_KEY&Feed_Id=" + $Feed.Feed_Id + "&PackageIds_Psv=$PackageName"
    $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing
    $PackageVersion = $Request.Content | ConvertFrom-Json

    Write-Output($PackageVersion.Version_Text)

}

Function Get-Latest {

    param (
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName
    )

    $API_BaseURI = "$ProGetServerURL/api/json"

    #Retrieve the ID for the feed
    $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$FeedName" -UseBasicParsing
    $Feed = $Request.Content | ConvertFrom-Json

    #Retrieve the package and version requested
    $URI = "$API_BaseURI/NuGetPackages_GetLatest?API_Key=$API_KEY&Feed_Id=" + $Feed.Feed_Id 
    $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing
    $PackageVersion = $Request.Content | ConvertFrom-Json

    Write-Output($PackageVersion)

}

Function Get-AllPackageVersions{

    param (
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL,
        [Parameter(Mandatory=$true)]
        $FeedName,
        [Parameter(Mandatory=$true)]
        $PackageName
    )

    $API_BaseURI = "$ProGetServerURL/api/json"

    #Retrieve the ID for the feed
    $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$FeedName" -UseBasicParsing
    $Feed = $Request.Content | ConvertFrom-Json

    #Retrieve the package and version requested
    $URI = "$API_BaseURI/NuGetPackages_GetPackage?API_Key=$API_KEY&Feed_Id=" + $Feed.Feed_Id + "&PackageIds_Psv=$PackageName"
    $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing
    $PackageVersion = $Request.Content | ConvertFrom-Json

    Write-Output($PackageVersion.Version_Text)
}



Function Copy-PackageToFeed {
<#
AUTHOR: Joel Newton
CREATED DATE: 10/19/15
LAST UPDATED DATE: 3/22/16
VERSION: 1.1

SYNOPSIS
   This script retrieves the latest versions of the packages on the specified origin feed and pushes them to the specified destination feed
	
PARAMETER 
    $PackageName
    $PackageVersion
    $OriginFeedName
    $DestinationFeedName

EXAMPLE
    
    Copy-PackageToFeed -PackageName Web -PackageVersion 1.16.2.35400 -OriginFeedName Branch -DestinationFeedName AtlasQARelease -ProGetServerURL http://progetna21.atlas.cm.com

#>
    [CmdletBinding()]
    param(
 
	    [Parameter(Mandatory=$true)]
        [string[]]$PackageList,
   	    [Parameter(Mandatory=$true)]
        $PackageVersion,
   	    [Parameter(Mandatory=$true)]
        $OriginFeedName,
   	    [Parameter(Mandatory=$true)]
        $DestinationFeedName,
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL
    )

    begin{

    }
    process{


        $API_BaseURI = "$ProGetServerURL/api/json"

        $SourceFeed = "$ProGetServerURL/nuget/$OriginFeedName"
        $ListTargetPackage = "$ProGetServerURL/nuget/$DestinationFeedName"
        $PushPackageURL = "$ProGetServerURL/api/v2/package/$DestinationFeedName"
    
        ForEach ($PackageName in $PackageList){

            #Make sure the package name and version exist before trying to promote
            $PackageFound = Test-PackageVersionIsInFeed -ProGetServerURL $ProGetServerURL -FeedName $OriginFeedName -PackageName $PackageName -PackageVersion $PackageVersion 

            If ($PackageFound -eq $false){

                $ThrowMessage = "Package $PackageName version $PackageVersion was not found in $SourceFeed."
                Throw($ThrowMessage)
            }

            #Retrieve the ID for the feed
            $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$API_KEY&Feed_Name=$OriginFeedName"
            $Feed = $Request.Content | ConvertFrom-Json

            Write-Output "Mirroring version $PackageVersion of $PackageName from $SourceFeed to $ListTargetPackage"
            cmd /c c:\NuGet\v286-signed\nuget mirror $PackageName $ListTargetPackage $PushPackageURL -version $PackageVersion -source $SourceFeed -apikey $NuGet_API_Key -NoCache


        }

    }

}