$TenantName = "M365x126372"
$clientRequestId = [GUID]::NewGuid().Guid

<#

Optimize - for a small number of endpoints that require low latency unimpeded connectivity which should bypass proxy servers, network SSL break and inspect devices, and network hairpins. (Represents about 70% of O365 traffic)
Allow - for a larger number of endpoints that benefit from low latency unimpeded connectivity. Although not expected to cause failures, we also recommend bypassing proxy servers, network SSL break and inspect devices, and network hairpins. Good connectivity to these endpoints is required for Office 365 to operate normally.
Default - for other Office 365 endpoints which can be directed to the default internet egress location for the company WAN.

#>


function Get-InternetProxy
 { 
    <# 
            .SYNOPSIS 
                Determine the internet proxy address
            .DESCRIPTION
                This function allows you to determine the the internet proxy address used by your computer
            .EXAMPLE 
                Get-InternetProxy
            .Notes 
                Author : Antoine DELRUE 
                WebSite: http://obilan.be 
    #> 

    $proxies = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').proxyServer

    if ($proxies)
    {
        if ($proxies -ilike "*=*")
        {
            $proxies -replace "=","://" -split(';') | Select-Object -First 1
        }

        else
        {
            "http://" + $proxies
        }
    }    
}

$proxy = Get-InternetProxy
#MANUALLY SET PROXY SERVER COMMENT AFTER TESTING
$proxy = "http://165.227.94.207:8080"


$epdatas = (Invoke-WebRequest -Uri ("https://endpoints.office.com/endpoints/O365USGovDoD?ClientRequestId=" + $clientRequestId) -Proxy $proxy -ProxyUseDefaultCredentials).content | ConvertFrom-Json


#Loop through each ID in the returned data
foreach ($epdata in $epdatas){

#Test Connection to 

if($epdata.optimizeUrls -ne $null){
    $OptimizeUrlPorts = $epdata.optimizeTcpPorts.split(",")
    Foreach($optimizeurlport in $optimizeurlports){
        Foreach($optimizeurl in $epdata.optimizeUrls){
           If($optimizeurl -match "*"){continue}
           If($optimizeurlport -eq "443"){
            try {
                Write-host "Testing $optimizeurl $optimizeurlport"
                $result = Invoke-WebRequest -UseBasicParsing -uri https://$optimizeurl -Proxy $proxy
                If($result.StatusCode -eq "200"){write-host "Connected Successfully" $result.StatusCode -ForegroundColor Green}
                }
            catch {
                $ErrorMessage = $_.Exception.Message
                If($ErrorMessage -match "504"){Write-Host "$optimizeurl $optimizeurlport $ErrorMessage" -ForegroundColor Red}
                ElseIf($ErrorMessage -match "400"){Write-Host "$optimizeurl $optimizeurlport $ErrorMessage" -ForegroundColor Green}
                ElseIf($ErrorMessage -match "404"){Write-Host "$optimizeurl $optimizeurlport $ErrorMessage" -ForegroundColor Green}
                Else{Write-Host "$optimizeurl $optimizeurlport $ErrorMessage" -ForegroundColor Yellow}
                }

            }
            }
        }
    }

if($epdata.allowUrls -ne $null){
    $allowurlports = $epdata.allowTcpPorts.split(",")
    Foreach($allowurlport in $allowurlports){
        Foreach($allowurl in $epdata.allowUrls){
            write-host "Allow URLS" $allowurl $allowurlport
            }
        }
    }

if($epdata.defaultUrls -ne $null){
    $defaulturlports = $epdata.defaultTcpPorts.split(",")
    Foreach($defaulturlport in $defaulturlports){
        Foreach($defaulturl in $epdata.defaultUrls){
            write-host "Default URLS" $defaulturl $defaulturlport
            }
        }
    }

#write-host $EPdata.id

}
