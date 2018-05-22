$TenantName = "M365x126372"
$clientRequestId = [GUID]::NewGuid().Guid

<#
See following for more details
https://techcommunity.microsoft.com/t5/Office-365-Blog/Announcing-Office-365-endpoint-categories-and-Office-365-IP/ba-p/177638 
https://support.office.com/en-us/article/managing-office-365-endpoints-99cab9d4-ef59-4207-9f2b-3728eb46bf9a?ui=en-US&rs=en-US&ad=US#ID0EACAAA=4._Web_service

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
#$proxy = "http://165.227.94.207:8080"



$epdatas = (Invoke-WebRequest -Uri ("https://endpoints.office.com/endpoints/O365USGovDoD?ClientRequestId=" + $clientRequestId) -Proxy $proxy -ProxyUseDefaultCredentials).content | ConvertFrom-Json


#Loop through each ID in the returned data
foreach ($epdata in $epdatas){


# Loop to test Optimize URLs if they have Optimize TCP Ports

if(($epdata.optimizeUrls -ne $null) -and ($epdata.optimizeTcpPorts -ne $null)){
    $OptimizeUrlPorts = $epdata.optimizeTcpPorts.split(",")
    Foreach($optimizeurlport in $optimizeurlports){
        Foreach($optimizeurl in $epdata.optimizeUrls){
           If($optimizeurl -match "\*"){continue}
           If($optimizeurlport -eq "443"){
            try {
                Write-host "Testing Optimize Url $optimizeurl $optimizeurlport via Proxy $proxy"
                $result = Invoke-WebRequest -UseBasicParsing -uri https://$optimizeurl -Proxy $proxy -ProxyUseDefaultCredentials
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
            If($optimizeurlport -eq "80"){
            try {
                Write-host "Testing Optimize Url $optimizeurl $optimizeurlport via Proxy $proxy"
                $result = Invoke-WebRequest -UseBasicParsing -uri http://$optimizeurl -Proxy $proxy -ProxyUseDefaultCredentials
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


# Loop to test Allow URLs if they have Allow TCP Ports
if(($epdata.allowUrls -ne $null) -and ($epdata.allowTcpPorts -ne $null)){
    $AllowUrlPorts = $epdata.allowTcpPorts.split(",")
    Foreach($allowurlport in $allowurlports){
        Foreach($allowurl in $epdata.allowUrls){
           If($allowurl -match "\*"){continue}
           If($allowurlport -eq "443"){
            try {
                Write-host "Testing Allow Url $allowurl $allowurlport via Proxy $proxy"
                $result = Invoke-WebRequest -UseBasicParsing -uri https://$allowurl -Proxy $proxy -ProxyUseDefaultCredentials
                If($result.StatusCode -eq "200"){write-host "Connected Successfully" $result.StatusCode -ForegroundColor Green}
                }
            catch {
                $ErrorMessage = $_.Exception.Message
                If($ErrorMessage -match "504"){Write-Host "$allowurl $allowurlport $ErrorMessage" -ForegroundColor Red}
                ElseIf($ErrorMessage -match "400"){Write-Host "$allowurl $allowurlport $ErrorMessage" -ForegroundColor Green}
                ElseIf($ErrorMessage -match "404"){Write-Host "$allowurl $allowurlport $ErrorMessage" -ForegroundColor Green}
                Else{Write-Host "$allowurl $allowurlport $ErrorMessage" -ForegroundColor Yellow}
                }

            }
            If($allowurlport -eq "80"){
            try {
                Write-host "Testing Allow Url $allowurl $allowurlport via Proxy $proxy"
                $result = Invoke-WebRequest -UseBasicParsing -uri http://$allowurl -Proxy $proxy -ProxyUseDefaultCredentials
                If($result.StatusCode -eq "200"){write-host "Connected Successfully" $result.StatusCode -ForegroundColor Green}
                }
            catch {
                $ErrorMessage = $_.Exception.Message
                If($ErrorMessage -match "504"){Write-Host "$allowurl $allowurlport $ErrorMessage" -ForegroundColor Red}
                ElseIf($ErrorMessage -match "400"){Write-Host "$allowurl $allowurlport $ErrorMessage" -ForegroundColor Green}
                ElseIf($ErrorMessage -match "404"){Write-Host "$allowurl $allowurlport $ErrorMessage" -ForegroundColor Green}
                Else{Write-Host "$allowurl $allowurlport $ErrorMessage" -ForegroundColor Yellow}
                }

            }
            }
        }
    }


# Loop to test Default URLs if they have Allow TCP Ports
if(($epdata.defaultUrls -ne $null) -and ($epdata.defaultTcpPorts -ne $null)){
    $defaultUrlPorts = $epdata.defaultTcpPorts.split(",")
    Foreach($defaulturlport in $defaulturlports){
        Foreach($defaulturl in $epdata.defaultUrls){
           If($defaulturl -match "\*"){continue}
           If($defaulturlport -eq "443"){
            try {
                Write-host "Testing Default Url $defaulturl $defaulturlport via Proxy $proxy"
                $result = Invoke-WebRequest -UseBasicParsing -uri https://$defaulturl -Proxy $proxy -ProxyUseDefaultCredentials
                If($result.StatusCode -eq "200"){write-host "Connected Successfully" $result.StatusCode -ForegroundColor Green}
                }
            catch {
                $ErrorMessage = $_.Exception.Message
                If($ErrorMessage -match "504"){Write-Host "$defaulturl $defaulturlport $ErrorMessage" -ForegroundColor Red}
                ElseIf($ErrorMessage -match "400"){Write-Host "$defaulturl $defaulturlport $ErrorMessage" -ForegroundColor Green}
                ElseIf($ErrorMessage -match "404"){Write-Host "$defaulturl $defaulturlport $ErrorMessage" -ForegroundColor Green}
                Else{Write-Host "$defaulturl $defaulturlport $ErrorMessage" -ForegroundColor Yellow}
                }

            }
            If($defaulturlport -eq "80"){
            try {
                Write-host "Testing Default Url $defaulturl $defaulturlport via Proxy $proxy"
                $result = Invoke-WebRequest -UseBasicParsing -uri http://$defaulturl -Proxy $proxy -ProxyUseDefaultCredentials
                If($result.StatusCode -eq "200"){write-host "Connected Successfully" $result.StatusCode -ForegroundColor Green}
                }
            catch {
                $ErrorMessage = $_.Exception.Message
                If($ErrorMessage -match "504"){Write-Host "$defaulturl $defaulturlport $ErrorMessage" -ForegroundColor Red}
                ElseIf($ErrorMessage -match "400"){Write-Host "$defaulturl $defaulturlport $ErrorMessage" -ForegroundColor Green}
                ElseIf($ErrorMessage -match "404"){Write-Host "$defaulturl $defaulturlport $ErrorMessage" -ForegroundColor Green}
                Else{Write-Host "$defaulturl $defaulturlport $ErrorMessage" -ForegroundColor Yellow}
                }

            }
            }
        }
    }




}
