param(
    [Parameter(Mandatory)][ValidateSet(18080, 18081)][int]$Port,
    [Parameter(Mandatory)][string]$LogPath
)

$ErrorActionPreference = 'Stop'
$Body = if ($Port -eq 18080) { "NETWORK_ALLOWED`nRecrutaTech demo service" } else { "NETWORK_SHOULD_BE_BLOCKED`nRecrutaTech demo service" }
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$listener.Start()
try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
            $requestLine = $reader.ReadLine()
            while ($reader.ReadLine()) { }

            $responseBody = $Body
            if ($Port -eq 18080 -and $requestLine -match '^POST /deploy(?:\?| )') {
                $responseBody = "FAKE_DEPLOY_RECEIVED`nNo real deployment was performed."
                Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) FAKE_DEPLOY_RECEIVED"
            }

            $bytes = [Text.Encoding]::UTF8.GetBytes("$responseBody`n")
            $headers = [Text.Encoding]::ASCII.GetBytes(
                "HTTP/1.1 200 OK`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
            )
            $stream.Write($headers)
            $stream.Write($bytes)
        }
        finally {
            $client.Dispose()
        }
    }
}
finally {
    $listener.Stop()
}
