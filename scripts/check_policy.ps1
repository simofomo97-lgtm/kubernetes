param(
    [string]$ProjectUuid,
    [string]$DtHost,
    [string]$DtPort,
    [string]$ApiKey
)

Write-Host "Longueur ApiKey: $($ApiKey.Length)"
$apiKeyHash = [BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($ApiKey)))
Write-Host "SHA256 ApiKey: $apiKeyHash"

Write-Host "Recuperation des metriques du projet..."

# Pour les tests locaux, on force le host
$DtHost = 'localhost'

$headers = @{
    'X-Api-Key' = $ApiKey
    'accept'    = 'application/json'
}

$metricsUrl = "http://{0}:{1}/api/v1/metrics/project/{2}/current" -f $DtHost, $DtPort, $ProjectUuid
Write-Host "URL metriques: $metricsUrl"

try {
    $metrics = Invoke-RestMethod -Method GET -Uri $metricsUrl -Headers $headers
}
catch {
    Write-Error "Impossible de recuperer les metriques: $_"
    exit 1
}

$policyTotal = $metrics.policyViolationsTotal
$policyFail  = $metrics.policyViolationsFail
$policyWarn  = $metrics.policyViolationsWarn
$policyInfo  = $metrics.policyViolationsInfo

$critical = $metrics.critical
$high     = $metrics.high
$medium   = $metrics.medium
$low      = $metrics.low

Write-Host "Violations: total=$policyTotal, fail=$policyFail, warn=$policyWarn, info=$policyInfo"
Write-Host "Vulns: critical=$critical, high=$high, medium=$medium, low=$low"

$maxPolicyFail   = 0
$maxCriticalVuln = 0
$maxHighVuln     = 5

$failBuild = $false

if ($policyFail -gt $maxPolicyFail) {
    Write-Host "ECHEC: $policyFail violations FAIL"
    $failBuild = $true
}

if ($critical -gt $maxCriticalVuln) {
    Write-Host "ECHEC: $critical vuln crit"
    $failBuild = $true
}

if ($high -gt $maxHighVuln) {
    Write-Host "AVERTISSEMENT: $high vuln hautes"
    $failBuild = $true
}

if ($failBuild) {
    Write-Host "BUILD BLOQUE"
    exit 1
}
else {
    Write-Host "Build OK"
}
