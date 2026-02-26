#Requires -Version 5.1
<#
.SYNOPSIS
    Cursor Agent CLI wrapper script - code implementation role (Windows PowerShell)
.DESCRIPTION
    Used by cursor-code-agent skill to call Cursor Agent with GPT-5.3 Codex model.
    This is the Windows equivalent of cursor-run.sh.
.EXAMPLE
    .\cursor-run.ps1 -File C:\tmp\prompt.txt -Dir .\my-project
    .\cursor-run.ps1 -Review -File C:\tmp\review-prompt.txt -Dir .\project -Output C:\tmp\review.txt
#>

param(
    [string]$Model = "gpt-5.3-codex",

    [Alias("d")]
    [string]$Dir = ".",

    [Alias("t")]
    [int]$Timeout = 900,

    [Alias("f")]
    [string]$File = "",

    [Alias("r")]
    [switch]$Review,

    [ValidateSet("enabled", "disabled", "")]
    [string]$Sandbox = "",

    [Alias("o")]
    [string]$Output = "",

    [Alias("h")]
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$PromptArgs
)

$ErrorActionPreference = "Stop"

# Escape arguments for use in Process.StartInfo.Arguments
function Join-CommandArguments {
    param([string[]]$Arguments)
    $escaped = foreach ($arg in $Arguments) {
        if ($null -eq $arg) {
            '""'
        }
        elseif ($arg -match '[\s"`"]') {
            '"' + ($arg -replace '([\\"])', '\$1') + '"'
        }
        else {
            $arg
        }
    }
    return ($escaped -join ' ')
}

# Resolve the actual executable path for the cursor 'agent' CLI
# npm/pnpm on Windows may generate .ps1 wrappers that Process.Start() cannot directly execute
function Resolve-AgentStartInfo {
    param([string[]]$AgentArgs)

    $cmd = Get-Command "agent" -ErrorAction Stop
    $cmdPath = $cmd.Source
    $argString = Join-CommandArguments -Arguments $AgentArgs

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    if ($cmdPath -match '\.ps1$') {
        # Prefer the .cmd version generated alongside .ps1 by npm/pnpm
        $cmdVersion = $cmdPath -replace '\.ps1$', '.cmd'
        if (Test-Path $cmdVersion) {
            $startInfo.FileName = $cmdVersion
            $startInfo.Arguments = $argString
        }
        else {
            # Fall back to running via powershell.exe
            $psExe = if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
                (Get-Command "pwsh").Source
            } else { "powershell.exe" }
            $startInfo.FileName = $psExe
            $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$cmdPath`" $argString"
        }
    }
    else {
        $startInfo.FileName = $cmdPath
        $startInfo.Arguments = $argString
    }

    return $startInfo
}

if ($Help) {
    @"
Usage: cursor-run.ps1 [OPTIONS] [prompt...]

Options:
  -Model <model>           Model to use (default: gpt-5.3-codex)
  -Dir <directory>         Working directory (default: current directory)
  -Timeout <seconds>       Timeout in seconds (default: 900)
  -File <file>             Read prompt from file (recommended)
  -Review                  Use plan mode (read-only code analysis, no modifications)
  -Sandbox <mode>          Sandbox mode: enabled | disabled
  -Output <file>           Write output to file
  -Help                    Show this help message

Examples:
  .\cursor-run.ps1 -File C:\tmp\prompt.txt -Dir .\my-project
  .\cursor-run.ps1 -File C:\tmp\prompt.txt -Output C:\tmp\result.txt -Dir .\project
  .\cursor-run.ps1 -Review -File C:\tmp\review.txt -Output C:\tmp\review-result.txt -Dir .\project
  .\cursor-run.ps1 -Model gpt-5.3-codex-high -File C:\tmp\prompt.txt -Dir .\project
"@
    exit 0
}

# --- Get prompt: file > args > stdin ---
$Prompt = ""
if ($File) {
    if (-not (Test-Path $File)) {
        Write-Error "Error: Prompt file not found: $File"
        exit 1
    }
    # Read as UTF-8, strip BOM if present
    $Prompt = Get-Content -Path $File -Raw -Encoding UTF8
}
elseif ($PromptArgs -and $PromptArgs.Count -gt 0) {
    $Prompt = $PromptArgs -join " "
}
elseif ([System.Console]::IsInputRedirected) {
    $Prompt = [System.Console]::In.ReadToEnd()
}
else {
    Write-Error "Error: No prompt provided. Use -File, arguments, or pipe stdin."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Prompt)) {
    Write-Error "Error: Empty prompt."
    exit 1
}

# --- Validate working directory ---
if (-not (Test-Path $Dir -PathType Container)) {
    Write-Error "Error: Working directory not found: $Dir"
    exit 1
}

# --- Build cursor agent command arguments ---
$agentArgs = @(
    "--print",
    "--trust",
    "--workspace", $Dir,
    "--model", $Model
)

if ($Review) {
    # Plan mode: read-only code analysis without file modifications
    $agentArgs += "--mode", "plan"
}
else {
    # Default: yolo mode (auto-approve all tool calls)
    $agentArgs += "--yolo"
}

if ($Sandbox) {
    $agentArgs += "--sandbox", $Sandbox
}

# Append prompt as the final positional argument
$agentArgs += $Prompt

Push-Location $Dir
try {
    Write-Host "=== Cursor Code Agent Starting ===" -ForegroundColor Cyan
    Write-Host "Model: $Model | Dir: $Dir | Timeout: ${Timeout}s | Review: $($Review.IsPresent)" -ForegroundColor DarkGray
    Write-Host "---" -ForegroundColor DarkGray

    $startInfo = Resolve-AgentStartInfo -AgentArgs $agentArgs
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $startInfo

    $proc.Start() | Out-Null

    # Async output reading to prevent deadlock on large outputs
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()

    $completed = $proc.WaitForExit($Timeout * 1000)

    if (-not $completed) {
        $proc.Kill()
        Write-Error "Error: Cursor Agent execution timed out after ${Timeout}s"
        exit 124
    }

    # Flush async readers
    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result

    if ($stdout) {
        Write-Host $stdout
        # Optionally write to output file
        if ($Output) {
            $stdout | Out-File -FilePath $Output -Encoding UTF8
        }
    }
    if ($stderr) { Write-Host $stderr -ForegroundColor DarkGray }

    exit $proc.ExitCode
}
finally {
    Pop-Location
}
