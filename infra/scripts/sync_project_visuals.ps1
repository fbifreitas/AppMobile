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

function Get-FieldByName($fields, $name) {
  return $fields.fields | Where-Object { $_.name -eq $name } | Select-Object -First 1
}

function Ensure-SingleSelectField($ghPath, $projectNumber, $owner, $name, $optionsCsv) {
  $fields = & $ghPath project field-list $projectNumber --owner $owner --format json | ConvertFrom-Json
  $field = Get-FieldByName $fields $name
  if (-not $field) {
    return & $ghPath project field-create $projectNumber --owner $owner --name $name --data-type SINGLE_SELECT --single-select-options $optionsCsv --format json | ConvertFrom-Json
  }

  return $field
}

$gh = Resolve-GitHubCli
$projectNumber = if ($env:PROJECT_NUMBER) { [int]$env:PROJECT_NUMBER } else { 1 }
$owner = if ($env:PROJECT_OWNER) { $env:PROJECT_OWNER } else { 'fbifreitas' }
$projectId = if ($env:PROJECT_ID) { $env:PROJECT_ID } else { 'PVT_kwHOECRsGc4BTNJY' }

if ($env:GITHUB_ACTIONS -eq 'true' -and [string]::IsNullOrWhiteSpace($env:GH_TOKEN)) {
  Write-Output 'Sincronizacao visual ignorada: configure o secret PROJECT_AUTOMATION_TOKEN com escopo de acesso ao GitHub Project.'
  exit 0
}

$semaforo = Ensure-SingleSelectField $gh $projectNumber $owner 'Semaforo' 'Em andamento,Impedido,Done'
$termometro = Ensure-SingleSelectField $gh $projectNumber $owner 'Termometro Backlog' 'Alta (Vermelho),Media (Laranja),Baixa (Azul)'

$semOptAndamento = ($semaforo.options | Where-Object { $_.name -eq 'Em andamento' } | Select-Object -First 1).id
$semOptImpedido = ($semaforo.options | Where-Object { $_.name -eq 'Impedido' } | Select-Object -First 1).id
$semOptDone = ($semaforo.options | Where-Object { $_.name -eq 'Done' } | Select-Object -First 1).id

$terOptAlta = ($termometro.options | Where-Object { $_.name -eq 'Alta (Vermelho)' } | Select-Object -First 1).id
$terOptMedia = ($termometro.options | Where-Object { $_.name -eq 'Media (Laranja)' } | Select-Object -First 1).id
$terOptBaixa = ($termometro.options | Where-Object { $_.name -eq 'Baixa (Azul)' } | Select-Object -First 1).id

$items = (& $gh project item-list $projectNumber --owner $owner --limit 500 --format json | ConvertFrom-Json).items

$updatedSemaforo = 0
$updatedTermometro = 0

foreach ($item in $items) {
  $itemId = $item.id
  $status = [string]$item.status
  $situacao = [string]$item.'situacao de execucao'
  $prioridade = [string]$item.prioridade

  $semOptionId = $null
  if ($status -eq 'Done') {
    $semOptionId = $semOptDone
  } elseif ($situacao -like 'Impedido*') {
    $semOptionId = $semOptImpedido
  } elseif ($status -eq 'In Progress') {
    $semOptionId = $semOptAndamento
  }

  if ($semOptionId) {
    & $gh project item-edit --id $itemId --project-id $projectId --field-id $semaforo.id --single-select-option-id $semOptionId | Out-Null
    $updatedSemaforo++
  } else {
    & $gh project item-edit --id $itemId --project-id $projectId --field-id $semaforo.id --clear | Out-Null
  }

  if ($status -eq 'Todo') {
    $terOptionId = $null
    if ($prioridade -eq 'Critica' -or $prioridade -eq 'Alta') {
      $terOptionId = $terOptAlta
    } elseif ($prioridade -eq 'Media') {
      $terOptionId = $terOptMedia
    } elseif ($prioridade -eq 'Baixa') {
      $terOptionId = $terOptBaixa
    }

    if ($terOptionId) {
      & $gh project item-edit --id $itemId --project-id $projectId --field-id $termometro.id --single-select-option-id $terOptionId | Out-Null
      $updatedTermometro++
    } else {
      & $gh project item-edit --id $itemId --project-id $projectId --field-id $termometro.id --clear | Out-Null
    }
  } else {
    & $gh project item-edit --id $itemId --project-id $projectId --field-id $termometro.id --clear | Out-Null
  }
}

Write-Output "updated_semaforo=$updatedSemaforo updated_termometro=$updatedTermometro"