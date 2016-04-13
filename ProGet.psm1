<#
.SYNOPSIS  
    A module for working with the Proget API
.DESCRIPTION  
    This module queries the APIs for our hosted ProGet servers
.NOTES  
    File Name    : ProGet.psm1
    Author       : Joel Newton - jnewton@springcm.com
    Requires     : PowerShell V3
    Dependencies : Nuget.exe, NuGet.ServerExtensions.dll

#>

######################
#CONSTANTS

$ScriptLocation = split-path -parent $MyInvocation.MyCommand.Path
$ProGetSettings = Get-Content -Path "$ScriptLocation\Settings.json" | Out-String | ConvertFrom-Json

$API_KEY = $ProGetSettings.API_KEY
$API_BaseURI = "$ProGetServerURL/api/json"

$NuGet_API_Key = $ProGetSettings.NuGet_API_Key

######################


Function Get-FeedList {

    [CmdletBinding()]
    param (
   	    [Parameter(Mandatory=$true)]
        $ProGetServerURL
    )

    begin {

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

        $SourceFeed = "$ProGetServerURL/nuget/$OriginFeedName"
        $ListTargetPackage = "$ProGetServerURL/nuget/$DestinationFeedName"
        $PushPackageURL = "$ProGetServerURL/api/v2/package/$DestinationFeedName"

    }
    process{

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
            cmd /c $ScriptLocation\bin\nuget.exe mirror $PackageName $ListTargetPackage $PushPackageURL -version $PackageVersion -source $SourceFeed -apikey $NuGet_API_Key -NoCache

        }

    }

}