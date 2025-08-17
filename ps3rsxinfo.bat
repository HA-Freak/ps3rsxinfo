<# : #
@echo off
setlocal enabledelayedexpansion
for %%a in (%*) do (
    if defined argsStrg (
        set "argsStrg=!argsStrg!|%%a"
    )else (
        set "argsStrg=%%a"
    )
)
cd %~dp0 && powershell -nol -nop -ex bypass -c "iex $($PSScriptName='%~nx0';$argsStrg='%argsStrg%';type '%~dpf0' -raw)" && endlocal && goto:eof
#>
$PSScriptRoot = (gl).Path
$args = ($argsStrg -split '\|') | ForEach-Object { $_.Trim() }
$args | ForEach-Object { Write-Host "Arg: $_" }

# If you get error: ´╗┐ : # 0<# save script as UTF-8 (without BOM)

# Read the file
$lines = Get-Content -Path $args

# Initialize match counter
$matchCount = 0

foreach ($line in $lines) {
    if ($line -like "*rsx:    *") {
        $matchCount++

        if ($matchCount -eq 2) {
            # Find the position of the third closing bracket ']'
            $indexes = ([regex]::Matches($line, "\]") | ForEach-Object { $_.Index })

            if ($indexes.Count -ge 3) {
                # Cut the line at the third ]
                $cutLine = $line.Substring(0, $indexes[2] + 1)

                Write-Output $cutLine

                # Extract the token immediately after "rsx:    "
                if ($cutLine -match "rsx:\s{6}(\S+)") {
                    $token = $matches[1]

                    # Check if the token matches any of the known values
                    if ($token -contains "rsx40") {
                        Write-Output "40nm RSX"
                    } elseif ($token -contains "rsx65") {
                        Write-Output "65nm RSX"
                    } elseif ($token -contains "rsx28") {
                        Write-Output "28nm RSX"
                    } elseif ($token -contains "b03" -or $token -contains "b08") {
                        Write-Output "90nm RSX"
                	$rsx90 = $true
                    } else {
                        Write-Output "Token '$token' does not match any rsx"
                    }
                } else {
                    Write-Output "Could not extract token after 'rsx:    '"
                }
            } else {
                Write-Output "Second occurrence found, but fewer than 3 ']' characters."
            }
            $bracketMatches = [regex]::Matches($line, "\]")
            if ($bracketMatches.Count -ge 3) {
                $thirdBracketIndex = $bracketMatches[2].Index
                $cutLine = $line.Substring(0, $thirdBracketIndex + 1)

                # Extract all bracketed groups (contents between [ and ])
                $bracketGroups = [regex]::Matches($cutLine, "\[([^\]]+)\]") | ForEach-Object { $_.Groups[1].Value }

                if ($bracketGroups.Count -ge 1) {
                    $firstBracket = $bracketGroups[0]
                    $parts = $firstBracket -split ':'

                    if ($parts.Count -ge 3) {
                        $thirdValue = $parts[2]
                        if ($thirdValue -eq 1) {
                            Write-Output "TOSHIBA"
                        }elseif ($thirdValue -eq 2) {
                            Write-Output "SONY"
                        }elseif ($thirdValue -eq 3) {
                            Write-Output "FUJITSU"
                        }elseif ($thirdValue -eq 4) {
                            Write-Output "TSMC"
                        }
                    } else {
                        Write-Output "✘ Less than 3 values in first [] group."
                    }
                } else {
                    Write-Output "✘ No [] groups found in cut line."
                }
            } else {
                Write-Output "✘ Fewer than 3 ']' characters in line."
            }
            if ($rsx90) { 
                $bracketMatches = [regex]::Matches($line, "\]")
                if ($bracketMatches.Count -ge 3) {
                    $thirdBracketIndex = $bracketMatches[2].Index
                    $cutLine = $line.Substring(0, $thirdBracketIndex + 1)

                    # Extract all bracketed blocks (e.g. [1c:0:a:0:1:0:1])
                    $bracketGroups = [regex]::Matches($cutLine, "\[([^\]]+)\]") | ForEach-Object { $_.Groups[1].Value }

                    if ($bracketGroups.Count -ge 2) {
                        $secondBracket = $bracketGroups[1]
                        $parts = $secondBracket -split ':'

                        if ($parts.Count -ge 2) {
                            $secondValue = $parts[1]
                            if ($secondValue -eq 2) {
                                Write-Output "high binning"
                            }elseif ($secondValue -eq 3) {
                                Write-Output "normal binning"
                            }
                        } else {
                            Write-Output "✘ Less than two values in second [] group."
                        }
                    } else {
                        Write-Output "✘ Less than two [] groups found."
                    }
                } else {
                    Write-Output "✘ Fewer than 3 ']' characters in line."
                }
            }
            break
        }
    }
}
# Optional message if fewer than 2 matches are found
if ($matchCount -lt 2) {
    Write-Output "Less than two occurrences of 'rsx:    ' were found."
}
pause