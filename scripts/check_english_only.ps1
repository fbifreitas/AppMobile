param(
  [string[]]$Roots = @("lib", "test", "apps/backend", "apps/web-backoffice", ".github", "scripts"),
  [string[]]$Extensions = @(
    ".dart",
    ".java",
    ".kt",
    ".ts",
    ".tsx",
    ".js",
    ".jsx",
    ".mjs",
    ".cjs",
    ".ps1",
    ".sh",
    ".yml",
    ".yaml"
  )
)

$ErrorActionPreference = "Stop"

$repoRoot = (Get-Location).Path
$failed = New-Object System.Collections.Generic.List[string]
$commentWordPattern = '\b(nao|n[oó]s|para|com|sem|uma|um|duas|tres|quatro|vistoria|vistoriador|imovel|imoveis|endereco|logradouro|fachada|cozinha|banheiro|lavanderia|varanda|sala|quarto|suite|ambiente|revisao|subtipo|obrigatori[oa]s?|evid[eê]ncia|fluxo|faltando|correcao|validacao|configuracao|tratativa|retomar|sincronizacao)\b'
$excludedPathPatterns = @(
  '^lib/l10n/',
  '^docs/',
  '^apps/web-backoffice/public/',
  '^apps/web-backoffice/\.next/',
  '^apps/web-backoffice/coverage/',
  '^build/',
  '^android/',
  '^ios/',
  '^linux/',
  '^macos/',
  '^windows/'
)

function Get-RelativePath {
  param([string]$Path)

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  if ($fullPath.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $fullPath.Substring($repoRoot.Length).TrimStart('\').Replace('\', '/')
  }
  return $Path.Replace('\', '/')
}

function Test-IncludedPath {
  param([string]$RelativePath)

  foreach ($pattern in $excludedPathPatterns) {
    if ($RelativePath -match $pattern) {
      return $false
    }
  }

  foreach ($root in $Roots) {
    $normalizedRoot = $root.Replace('\', '/').TrimEnd('/')
    if ($RelativePath -eq $normalizedRoot -or $RelativePath.StartsWith("$normalizedRoot/")) {
      return $true
    }
  }

  return $false
}

function Get-ChangedFiles {
  $files = @()
  $eventName = $env:GITHUB_EVENT_NAME
  $baseRef = $env:GITHUB_BASE_REF

  if ($eventName -eq 'pull_request' -and -not [string]::IsNullOrWhiteSpace($baseRef)) {
    $mergeBase = "origin/$baseRef"
    $files = git diff --name-only --diff-filter=ACMR "$mergeBase...HEAD" 2>$null
  } else {
    git rev-parse --verify HEAD~1 *> $null
    if ($LASTEXITCODE -eq 0) {
      $files = git diff --name-only --diff-filter=ACMR HEAD~1 HEAD 2>$null
    }
  }

  return @($files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Test-CommentLanguage {
  param([string]$RelativePath, [string]$Content)

  $lines = $Content -split "`r?`n"
  $insideBlock = $false

  for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    $commentFragments = New-Object System.Collections.Generic.List[string]

    if ($insideBlock) {
      $endIndex = $line.IndexOf('*/')
      if ($endIndex -ge 0) {
        $commentFragments.Add($line.Substring(0, $endIndex))
        $insideBlock = $false
        $line = $line.Substring($endIndex + 2)
      } else {
        $commentFragments.Add($line)
        $line = ''
      }
    }

    while ($line.Length -gt 0) {
      $lineCommentIndex = $line.IndexOf('//')
      $hashCommentIndex = if ($RelativePath.EndsWith('.yml') -or $RelativePath.EndsWith('.yaml') -or $RelativePath.EndsWith('.sh') -or $RelativePath.EndsWith('.ps1')) { $line.IndexOf('#') } else { -1 }
      $blockCommentIndex = $line.IndexOf('/*')

      $candidateIndexes = @($lineCommentIndex, $hashCommentIndex, $blockCommentIndex) | Where-Object { $_ -ge 0 }
      if ($candidateIndexes.Count -eq 0) {
        break
      }

      $nextIndex = ($candidateIndexes | Measure-Object -Minimum).Minimum
      if ($nextIndex -eq $lineCommentIndex) {
        $commentFragments.Add($line.Substring($lineCommentIndex + 2))
        break
      }
      if ($nextIndex -eq $hashCommentIndex) {
        if ($RelativePath.EndsWith('.yml') -or $RelativePath.EndsWith('.yaml')) {
          if ($line.TrimStart().StartsWith('#')) {
            $commentFragments.Add($line.Substring($hashCommentIndex + 1))
          }
        } else {
          $commentFragments.Add($line.Substring($hashCommentIndex + 1))
        }
        break
      }
      if ($nextIndex -eq $blockCommentIndex) {
        $afterStart = $line.Substring($blockCommentIndex + 2)
        $endIndex = $afterStart.IndexOf('*/')
        if ($endIndex -ge 0) {
          $commentFragments.Add($afterStart.Substring(0, $endIndex))
          $line = $afterStart.Substring($endIndex + 2)
          continue
        }

        $commentFragments.Add($afterStart)
        $insideBlock = $true
        break
      }
    }

    foreach ($fragment in $commentFragments) {
      if ($fragment -match '[^\u0000-\u007F]') {
        $failed.Add("${RelativePath}:$($i + 1) contains non-ASCII characters in comments")
      }
      if ($fragment -match $commentWordPattern) {
        $word = $Matches[1]
        $failed.Add("${RelativePath}:$($i + 1) contains non-English comment token '$word'")
      }
    }
  }
}

$candidateFiles = Get-ChangedFiles
if ($candidateFiles.Count -eq 0) {
  Write-Host "[english-only] No changed files detected; validation skipped."
  exit 0
}

foreach ($path in $candidateFiles) {
  $relativePath = Get-RelativePath -Path $path
  if (-not (Test-IncludedPath -RelativePath $relativePath)) {
    continue
  }

  $extension = [System.IO.Path]::GetExtension($relativePath).ToLowerInvariant()
  if (-not ($Extensions -contains $extension)) {
    continue
  }

  if (-not (Test-Path $path)) {
    continue
  }

  $content = Get-Content $path -Raw -Encoding UTF8
  Test-CommentLanguage -RelativePath $relativePath -Content $content
}

if ($failed.Count -gt 0) {
  Write-Host "[english-only] Violations detected:" -ForegroundColor Red
  foreach ($entry in $failed | Sort-Object -Unique) {
    Write-Host " - $entry"
  }
  exit 1
}

Write-Host "[english-only] Code comments are English-only in changed files."
