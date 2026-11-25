$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http

$base = 'http://localhost:5080'
$suffix = [DateTime]::UtcNow.ToString('yyyyMMddHHmmssfff')
$username = "race$suffix"
$json = @{ username = $username; password = 'Passw0rd!' } | ConvertTo-Json -Compress
$uri = "$base/api/auth/register"

$client = New-Object System.Net.Http.HttpClient
$tasks = @()
for ($i = 0; $i -lt 40; $i++) {
    $content = New-Object System.Net.Http.StringContent($json, [System.Text.Encoding]::UTF8, 'application/json')
    $tasks += $client.PostAsync($uri, $content)
}
[System.Threading.Tasks.Task]::WhenAll($tasks).Wait() | Out-Null

$statuses = @($tasks | ForEach-Object { [int]$_.Result.StatusCode })
$statuses | Group-Object | ForEach-Object { "status=$($_.Name) count=$($_.Count)" }
$fiveHundreds = @($statuses | Where-Object { $_ -ge 500 }).Count
"RACE_500=$fiveHundreds"
if ($fiveHundreds -gt 0) { exit 1 }
exit 0
