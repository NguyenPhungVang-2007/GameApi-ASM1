$ErrorActionPreference = 'Stop'

$Base = 'http://localhost:5080'
$SqlCmd = 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE'
$suffix = Get-Date -Format 'yyyyMMddHHmmss'
$userA = "asm1a$suffix"
$userB = "asm1b$suffix"
$pass = 'Passw0rd!'
$wrongPass = 'WrongPass1!'
$results = @()

function Invoke-Api {
    param(
        [string]$Method,
        [string]$Path,
        [object]$Body,
        [string]$Token
    )

    $uri = $Base + $Path
    $headers = @{ 'Content-Type' = 'application/json' }
    if ($Token) { $headers['Authorization'] = "Bearer $Token" }

    $json = $null
    if ($null -ne $Body) { $json = $Body | ConvertTo-Json -Depth 8 }

    try {
        if ($json) {
            $response = Invoke-WebRequest -UseBasicParsing -Method $Method -Uri $uri -Headers $headers -Body $json
        } else {
            $response = Invoke-WebRequest -UseBasicParsing -Method $Method -Uri $uri -Headers $headers
        }
        $status = [int]$response.StatusCode
        $text = [string]$response.Content
    } catch {
        $response = $_.Exception.Response
        if ($null -ne $response) {
            $status = [int]$response.StatusCode
            $stream = $response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $text = $reader.ReadToEnd()
            $reader.Dispose()
        } else {
            $status = 0
            $text = $_.Exception.Message
        }
    }

    $parsed = $null
    try { $parsed = $text | ConvertFrom-Json } catch { }

    return [pscustomobject]@{
        Status = $status
        Text   = $text
        Body   = $parsed
    }
}

function Assert-Case {
    param(
        [string]$Id,
        [bool]$Passed,
        [string]$Detail
    )

    $script:results += [pscustomobject]@{ Id = $Id; Passed = $Passed; Detail = $Detail }
    if ($Passed) {
        Write-Host "$Id PASS - $Detail" -ForegroundColor Green
    } else {
        Write-Host "$Id FAIL - $Detail" -ForegroundColor Red
    }
}

function Get-Message {
    param($Response)
    if ($null -ne $Response.Body -and $Response.Body.PSObject.Properties['message']) {
        return [string]$Response.Body.message
    }
    return ''
}

# TC01 - register success
$r = Invoke-Api 'POST' '/api/auth/register' @{ username = $userA; password = $pass } ''
$ok = ($r.Status -eq 201) -and ($r.Body.id -gt 0) -and ($r.Body.username -eq $userA)
Assert-Case 'TC01' $ok "status=$($r.Status) body=$($r.Text)"
$accountAId = 0
if ($ok) { $accountAId = [int]$r.Body.id }

# TC02 - duplicate username
$r = Invoke-Api 'POST' '/api/auth/register' @{ username = $userA; password = $pass } ''
$ok = ($r.Status -eq 409) -and ((Get-Message $r) -eq 'Tên đăng nhập đã tồn tại')
Assert-Case 'TC02' $ok "status=$($r.Status) body=$($r.Text)"

# TC03 - short username and short password
$r = Invoke-Api 'POST' '/api/auth/register' @{ username = 'ab'; password = '123' } ''
Assert-Case 'TC03' ($r.Status -eq 400) "status=$($r.Status) body=$($r.Text)"

# TC04 - login success
$r = Invoke-Api 'POST' '/api/auth/login' @{ username = $userA; password = $pass } ''
$ok = ($r.Status -eq 200) -and (-not [string]::IsNullOrWhiteSpace([string]$r.Body.token)) -and ($r.Body.username -eq $userA)
Assert-Case 'TC04' $ok "status=$($r.Status) token_issued=$(-not [string]::IsNullOrWhiteSpace([string]$r.Body.token))"
$tokenA = ''
if ($ok) { $tokenA = [string]$r.Body.token }

# TC05 - wrong password
$r = Invoke-Api 'POST' '/api/auth/login' @{ username = $userA; password = $wrongPass } ''
$ok = ($r.Status -eq 401) -and ((Get-Message $r) -eq 'Sai tên đăng nhập hoặc mật khẩu')
Assert-Case 'TC05' $ok "status=$($r.Status) body=$($r.Text)"

# TC06 - unknown username
$r = Invoke-Api 'POST' '/api/auth/login' @{ username = "no_$suffix"; password = $pass } ''
$ok = ($r.Status -eq 401) -and ((Get-Message $r) -eq 'Sai tên đăng nhập hoặc mật khẩu')
Assert-Case 'TC06' $ok "status=$($r.Status) body=$($r.Text)"

# TC07 - no bearer token
$r = Invoke-Api 'POST' '/api/characters' @{ name = 'No Token'; class = 'Warrior' } ''
Assert-Case 'TC07' ($r.Status -eq 401) "status=$($r.Status) body=$($r.Text)"

# TC08 - create character
$r = Invoke-Api 'POST' '/api/characters' @{ name = 'HeroA'; class = 'Warrior' } $tokenA
$ok = ($r.Status -eq 201) -and ($r.Body.id -gt 0) -and ($r.Body.level -eq 1) -and ($r.Body.hp -eq 100) -and ($r.Body.accountId -eq $accountAId)
Assert-Case 'TC08' $ok "status=$($r.Status) body=$($r.Text)"
$characterAId = 0
if ($ok) { $characterAId = [int]$r.Body.id }

# TC09 - invalid character name
$r = Invoke-Api 'POST' '/api/characters' @{ name = 'A'; class = 'Warrior' } $tokenA
Assert-Case 'TC09' ($r.Status -eq 400) "status=$($r.Status) body=$($r.Text)"

# TC10 - update own character
$r = Invoke-Api 'PUT' "/api/characters/$characterAId" @{ name = 'HeroA2'; class = 'Mage'; level = 7; hp = 250 } $tokenA
$ok = ($r.Status -eq 200) -and ($r.Body.name -eq 'HeroA2') -and ($r.Body.class -eq 'Mage') -and ($r.Body.level -eq 7) -and ($r.Body.hp -eq 250)
Assert-Case 'TC10' $ok "status=$($r.Status) body=$($r.Text)"

# TC11 - update another account's character
$r = Invoke-Api 'POST' '/api/auth/register' @{ username = $userB; password = $pass } ''
$okB = ($r.Status -eq 201)
$r = Invoke-Api 'POST' '/api/auth/login' @{ username = $userB; password = $pass } ''
$tokenB = ''
if ($okB -and $r.Status -eq 200) { $tokenB = [string]$r.Body.token }
$r = Invoke-Api 'POST' '/api/characters' @{ name = 'HeroB'; class = 'Archer' } $tokenB
$characterBId = 0
if ($r.Status -eq 201) { $characterBId = [int]$r.Body.id }
$r = Invoke-Api 'PUT' "/api/characters/$characterBId" @{ name = 'Stolen'; class = 'Mage'; level = 9; hp = 999 } $tokenA
$setupOk = $okB -and ($characterBId -gt 0)
$ok = $setupOk -and ($r.Status -eq 404) -and ((Get-Message $r) -eq 'Không tìm thấy nhân vật của bạn')
Assert-Case 'TC11' $ok "setup_ok=$setupOk status=$($r.Status) body=$($r.Text)"

# TC12 - update missing character
$r = Invoke-Api 'PUT' '/api/characters/99999999' @{ name = 'Ghost'; class = 'Mage'; level = 2; hp = 100 } $tokenA
$ok = ($r.Status -eq 404) -and ((Get-Message $r) -eq 'Không tìm thấy nhân vật của bạn')
Assert-Case 'TC12' $ok "status=$($r.Status) body=$($r.Text)"

# EX1 - update missing level and hp
$r = Invoke-Api 'PUT' "/api/characters/$characterAId" @{ name = 'No Stats'; class = 'Mage' } $tokenA
Assert-Case 'EX1' ($r.Status -eq 400) "status=$($r.Status) body=$($r.Text)"

# EX2 - password stored as hash in SQL Server
$hash = ''
if (Test-Path $SqlCmd) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $SqlCmd -S .\SQLEXPRESS -E -d game_asm1_demo -h -1 -W -Q "SELECT PasswordHash FROM dbo.Accounts WHERE Username='$userA';" 2>&1
    $ErrorActionPreference = $oldPreference
    $hash = @($output | Where-Object { $_ -is [string] -and $_ -like 'AQAAAA*' } | Select-Object -First 1)
}
$hashText = [string]$hash
$ok = (-not [string]::IsNullOrWhiteSpace($hashText)) -and $hashText.StartsWith('AQAAAA') -and (-not $hashText.Contains($pass))
$prefix = ''
if ($hashText.Length -gt 0) { $prefix = $hashText.Substring(0, [Math]::Min(6, $hashText.Length)) }
Assert-Case 'EX2' $ok "stored_prefix=$prefix"

$failed = @($results | Where-Object { -not $_.Passed })
Write-Host ''
Write-Host "TOTAL: $($results.Count)  PASS: $($results.Count - $failed.Count)  FAIL: $($failed.Count)"
if ($failed.Count -gt 0) { exit 1 }
exit 0
