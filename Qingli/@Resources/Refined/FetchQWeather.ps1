# Windows PowerShell 5.1, used by Rainmeter's bundled RunCommand plugin.
# HTTPS + automatic gzip decoding. Credentials never appear in arguments/stdout.
param(
    [ValidateSet('current','daily')][string]$Kind,
    [ValidateRange(-90,90)][double]$Latitude,
    [ValidateRange(-180,180)][double]$Longitude
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$client = $null
$response = $null
$stream = $null
$buffered = $null
try {
    Add-Type -AssemblyName System.Net.Http
    $configPath = Join-Path $PSScriptRoot 'QWeather.local.json'
    if ((Get-Item -LiteralPath $configPath).Length -gt 8192) { throw 'Invalid configuration' }
    $config = Get-Content -Raw -LiteralPath $configPath -Encoding UTF8 | ConvertFrom-Json
    if ($config.apiHost -isnot [string] -or $config.apiKey -isnot [string]) { throw 'Invalid configuration' }
    if ($config.apiHost.Length -gt 253 -or $config.apiHost -notmatch '^(?:[a-z0-9-]+\.)+qweatherapi\.com$') { throw 'Invalid host' }
    if ($config.apiKey -notmatch '^[A-Za-z0-9_-]{16,256}$') { throw 'Invalid credential' }
    $lat = $Latitude.ToString('F2',[Globalization.CultureInfo]::InvariantCulture)
    $lon = $Longitude.ToString('F2',[Globalization.CultureInfo]::InvariantCulture)
    # City products match the city website's forecast instead of the v1 grid.
    # Official v7 is still available but marked for deprecation; revisit on migration.
    $endpoint = 'now'
    if ($Kind -eq 'daily') { $endpoint = '7d' }
    $uri = 'https://' + $config.apiHost + '/v7/weather/' + $endpoint + '?location=' + $lon + '%2C' + $lat + '&lang=zh'
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AutomaticDecompression = [Net.DecompressionMethods]::GZip -bor [Net.DecompressionMethods]::Deflate
    $handler.AllowAutoRedirect = $false
    $handler.Proxy = [Net.WebRequest]::GetSystemWebProxy()
    $handler.UseProxy = $true
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(25)
    $null = $client.DefaultRequestHeaders.TryAddWithoutValidation('X-QW-Api-Key',$config.apiKey)
    $null = $client.DefaultRequestHeaders.TryAddWithoutValidation('Accept','application/json')
    $response = $client.GetAsync($uri,[Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
    if ([int]$response.StatusCode -ne 200) {
        [Console]::Write('{"error":true,"status":' + [int]$response.StatusCode + '}')
    } else {
        $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $buffered = New-Object IO.MemoryStream
        $buffer = New-Object byte[] 8192
        while (($count = $stream.Read($buffer,0,$buffer.Length)) -gt 0) {
            if ($buffered.Length + $count -gt 1048576) { throw 'Response too large' }
            $buffered.Write($buffer,0,$count)
        }
        [Console]::Write([Text.Encoding]::UTF8.GetString($buffered.ToArray()))
    }
} catch {
    # Do not serialize the exception: its message can contain the private host.
    [Console]::Write('{"error":true,"status":0}')
} finally {
    if ($stream) { $stream.Dispose() }
    if ($buffered) { $buffered.Dispose() }
    if ($response) { $response.Dispose() }
    if ($client) { $client.Dispose() }
}
