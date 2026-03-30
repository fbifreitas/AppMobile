$ErrorActionPreference = 'Stop'

function Resolve-GitHubCli {
  $command = Get-Command gh -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $windowsPath = "$env:ProgramFiles\GitHub CLI\gh.exe"
  if (Test-Path $windowsPath) {
    return $windowsPath
  }

  throw 'GitHub CLI nao encontrado no PATH nem no diretorio padrao.'
}

$gh = Resolve-GitHubCli

$projectNumber = 1
$owner = 'fbifreitas'
$projectId = 'PVT_kwHOECRsGc4BTNJY'

$fieldStatus = 'PVTSSF_lAHOECRsGc4BTNJYzhAg4tI'
$optTodo = 'f75ad846'
$optInProgress = '47fc9ee4'
$optDone = '98236657'

$fieldBacklogId = 'PVTF_lAHOECRsGc4BTNJYzhAg5yE'
$fieldDominio = 'PVTSSF_lAHOECRsGc4BTNJYzhAg5yI'
$optMobile = '1b59871b'

$fieldTipo = 'PVTSSF_lAHOECRsGc4BTNJYzhAg5yM'
$optFix = '88959677'
$optDebito = 'ea660505'
$optEvolutivo = '5ef47319'

$fieldPrioridade = 'PVTSSF_lAHOECRsGc4BTNJYzhAg5yQ'
$optCritica = '3fb282e7'
$optAlta = 'c2553e74'
$optMedia = '293dcf1d'
$optBaixa = 'ccff8a5e'

$fieldRisco = 'PVTSSF_lAHOECRsGc4BTNJYzhAg5yU'
$optRiscoBaixo = '3e413614'
$optRiscoModerado = 'a7f487d8'
$optRiscoAlto = '63c0cc25'

$fieldPacote = 'PVTF_lAHOECRsGc4BTNJYzhAg5yY'
$fieldCriterio = 'PVTF_lAHOECRsGc4BTNJYzhAg5zI'
$fieldRelease = 'PVTF_lAHOECRsGc4BTNJYzhAg5z8'

function Set-FieldText([string]$itemId, [string]$fieldId, [string]$text) {
  & $gh project item-edit --id $itemId --project-id $projectId --field-id $fieldId --text "$text" | Out-Null
}

function Set-FieldSelect([string]$itemId, [string]$fieldId, [string]$optionId) {
  & $gh project item-edit --id $itemId --project-id $projectId --field-id $fieldId --single-select-option-id $optionId | Out-Null
}

$lines = Get-Content 'docs/BACKLOG_FUNCIONALIDADES.md'
$rows = @()

foreach ($line in $lines) {
  if ($line -match '^\|.*BL-\d{3}.*\|$') {
    $parts = $line.Split('|') | ForEach-Object { $_.Trim() }
    $idValue = ($parts[2] -replace '\*', '').Trim()
    if ($parts.Length -ge 7 -and $idValue -match '^BL-\d{3}$') {
      $rows += [pscustomobject]@{
        Id = $idValue
        Func = $parts[3]
        Status = $parts[4]
        Prioridade = $parts[5]
        Criterio = $parts[6]
      }
    }
  }
}

$rows = $rows | Sort-Object Id -Unique

$existing = & $gh project item-list $projectNumber --owner $owner --limit 500 --format json | ConvertFrom-Json
$map = @{}

foreach ($it in $existing.items) {
  $bid = $null
  if ($it.PSObject.Properties.Name -contains 'backlog ID') {
    $bid = $it.'backlog ID'
  }
  if ([string]::IsNullOrWhiteSpace($bid) -and $it.title -match '(BL-\d{3})') {
    $bid = $Matches[1]
  }
  if (-not [string]::IsNullOrWhiteSpace($bid)) {
    $map[$bid] = $it.id
  }
}

$created = 0
$updated = 0

foreach ($r in $rows) {
  if ($map.ContainsKey($r.Id)) {
    $itemId = $map[$r.Id]
    $updated++
  } else {
    $title = "$($r.Id) $($r.Func)"
    $body = 'Sincronizado automaticamente de docs/BACKLOG_FUNCIONALIDADES.md em 2026-03-30.'
    $newItem = & $gh project item-create $projectNumber --owner $owner --title "$title" --body "$body" --format json | ConvertFrom-Json
    $itemId = $newItem.id
    $created++
  }

  $statusOpt = $optTodo
  $s = $r.Status.ToLowerInvariant()
  if ($s -like '*conclu*') {
    $statusOpt = $optDone
  } elseif ($s -like '*em andamento*') {
    $statusOpt = $optInProgress
  }

  $prioOpt = $optMedia
  $p = $r.Prioridade.ToLowerInvariant()
  if ($p -like '*crit*') {
    $prioOpt = $optCritica
  } elseif ($p -like '*alta*') {
    $prioOpt = $optAlta
  } elseif ($p -like '*baixa*') {
    $prioOpt = $optBaixa
  }

  $tipoOpt = $optEvolutivo
  if ($r.Id -in @('BL-013', 'BL-014', 'BL-036')) {
    $tipoOpt = $optDebito
  }
  if ($r.Id -in @('BL-040', 'BL-041', 'BL-042', 'BL-043', 'BL-044', 'BL-045', 'BL-046', 'BL-047', 'BL-048', 'BL-049')) {
    $tipoOpt = $optFix
  }

  $riskOpt = $optRiscoModerado
  if ($prioOpt -eq $optCritica) {
    $riskOpt = $optRiscoAlto
  } elseif ($prioOpt -eq $optBaixa) {
    $riskOpt = $optRiscoBaixo
  }

  Set-FieldSelect $itemId $fieldStatus $statusOpt
  Set-FieldText $itemId $fieldBacklogId $r.Id
  Set-FieldSelect $itemId $fieldDominio $optMobile
  Set-FieldSelect $itemId $fieldTipo $tipoOpt
  Set-FieldSelect $itemId $fieldPrioridade $prioOpt
  Set-FieldSelect $itemId $fieldRisco $riskOpt
  Set-FieldText $itemId $fieldPacote 'Backlog Mobile Unificado'
  Set-FieldText $itemId $fieldCriterio $r.Criterio
  Set-FieldText $itemId $fieldRelease 'v1.2.12+'
}

$after = & $gh project item-list $projectNumber --owner $owner --limit 500 --format json | ConvertFrom-Json
$projIds = @($after.items | ForEach-Object { $_.'backlog ID' } | Where-Object { $_ -match '^BL-\d{3}$' } | Sort-Object -Unique)

Write-Output "sync_rows=$($rows.Count) created=$created updated=$updated project_bl=$($projIds.Count)"
