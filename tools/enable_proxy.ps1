$ports = @(6363);

$wslAddress = $($(wsl hostname -I).Trim());
$listenAddress = "0.0.0.0";

foreach ($port in $ports) {
    Write-Host "Proxying port $port to WSL2"
    Invoke-Expression "netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$listenAddress";
    Invoke-Expression "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$listenAddress connectport=$port connectaddress=$wslAddress";
}
