
function Set-BBServerCommitBuildStatus
{
    <#
    .SYNOPSIS
    Sets the build status of a commit in Bitbucket Server.

    .DESCRIPTION
    The `Set-BBServerCommitBuildStatus` function sets the build status of a specific commit in Bitbucket Server. The status can be in progress, successful, or failed. When a build status is set, Bitbucket Server will show a blue "in progress" icon for in progress builds, a green checkmark icon for successful builds, and a red failed icon for failed builds.

    Data about the commit is read from the environment set up by supported build servers, which arethe Jenkins and TeamCity. Bitbucket Server must have the commit ID, a key that uniquely identifies this specific build, and a URI that points to the build's report. The build name is optional, but when running under a supported build server, is also pulled from the environment.

    If a commit already has a status, this function will overwrite it.

    .EXAMPLE
    Set-BBServerCommitBuildStatus -Connection $conn -Status InProgress

    Demonstrates how this function should be called when running under a build server. Currently, Jenkins and TeamCity are supported.

    .EXAMPLE
    Set-BBServerCommitBuildStatus -Connection $conn -Status Successful -CommitID 'e24e50bba38db28fb8cf433d00c0d3372f8405cf' -Key 'jenkins-WhsInit-140' -BuildUri 'https://jenkins.dev.webmd.com/job/WhsInit/140/' -Name 'WhsInit' -Verbose

    Demonstrates how to set the build status for a commit using your own custom commit ID, key, and build URI.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The connection to the Bitbucket Server. Use `New-BBServerConnection` to create one.
        $Connection,

        [Parameter(Mandatory=$true)]
        [ValidateSet('InProgress','Successful','Failed')]
        # The status of the build.
        $Status,

        [ValidateLength(1,255)]
        [string]
        # The ID of the commit. The default value is read from environment variables set by build servers.
        #
        # If running under Jenkins, the `GIT_COMMIT` environment variable is used.
        #
        # If runnning under TeamCity, the `BUILD_VCS_NUMBER` environment variable is used.
        #
        # If not running under a build server, and none of the above environment variables are set, this function write an error and does nothing.
        $CommitID,

        [ValidateLength(1,255)]
        [string]
        # A value that uniquely identifies the build. The default value is pulled from environment variables that get set by build servers.
        # 
        # If running under Jenkins the `BUILD_TAG` environment variable is used.
        #
        # If running under TeamCity, the file defined in `TEAMCITY_BUILD_PROPERTIES_FILE` environment variable is loaded and the `teamcity.buildType.id` and `teamcity.build.id` properties are combined (separated by an underscore) to create a key.
        #
        # If not running under a build server, and none of the above environment variables are set, this function write an error and does nothing.
        $Key,

        [ValidateScript({ $_.ToString().Length -lt 450 })]
        [uri]
        # A URI to the build results. The default is read from the environment variables that get set by build servers.
        #
        # If running under Jenkins, the `JOB_URL` environment variable is used.
        #
        # If running under TeamCity, the URL is constructed from information defined in configuration files that TeamCity creates. A TeamCity build URL format is `SERVER_URI/viewLog.html?buildId=BUILD_ID&buildTypeID=BUILD_TYPE_ID`. `BUILD_TYPE_ID` and `BUILD_ID` are read from the `teamcity.buildType.id` and `teamcity.build.id` properties in the file defined in `TEAMCITY_BUILD_PROPERTIES_FILE` environment variable. `SERVER_URL` is read from the `teamcity.serverUrl` property in the file defined by the `teamcity.configuration.properties.file` property that is defined in the file defined by the `TEAMCITY_BUILD_PROPERTIES_FILE` environment variable.
        #
        # If not running under a build server, and none of the above environment variables are set, this function write an error and does nothing.
        $BuildUri,

        [ValidateLength(1,255)]
        [string]
        # The name of the build. The default value is read from environment variables that get set by build servers.
        #
        # If running under Jenkins, the `JOB_NAME` environment variable is used.
        #
        # If running under TeamCity, the job name is read from the `teamcity.buildType.id` property in the file defined by the `TEAMCITY_BUILD_PROPERTIES_FILE` environment variable.
        #
        # If not running under a build server, and none of the above environment variables are set, this function write an error and does nothing.
        $Name,

        [string]
        [ValidateLength(1,255)]
        # A description of the build. Useful if the state is failed. Default is an empty string.
        $Description = ''
    )

    Set-StrictMode -Version 'Latest'

    # We're in Jenkins
    if( (Test-Path 'env:GIT_COMMIT') )
    {
        $body = @{
                    state = $Status.ToUpperInvariant();
                    key = (Get-Item -Path 'env:BUILD_TAG').Value;
                    name = (Get-Item -Path 'env:JOB_NAME').Value;
                    url = (Get-Item -Path 'env:JOB_URL').Value;
                    description = $Description;
                 }
        $resourcePath = 'commits/{0}' -f (Get-Item -Path 'env:GIT_COMMIT').Value
    }
    else
    {
        <#
        $body = @{
                    state = $Status.ToUpperInvariant();
                    key = $Key
                    name = $Name
                    url = $BuildUri
                    description = $Description;
                 }
        $resourcePath = 'commits/{0}' -f $CommitID
        #>
    }

    $body | Invoke-BBServerRestMethod -Connection $Connection -Method Post -ApiName 'build-status' -ResourcePath $resourcePath
}
