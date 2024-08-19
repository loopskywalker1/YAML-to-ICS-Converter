# DynamicEventGenerator.psm1

function Get-NextOccurrence {
    param (
        [DateTime]$startDate,
        [string]$dayOfWeek,
        [string]$time
    )
    
    $dow = [System.DayOfWeek]::$dayOfWeek
    $daysUntilNext = ($dow - $startDate.DayOfWeek + 7) % 7
    $nextDate = $startDate.AddDays($daysUntilNext)
    $timeSpan = [TimeSpan]::Parse($time)
    
    return $nextDate.Date.Add($timeSpan)
}

function Convert-ToIcsDate {
    param ([DateTime]$date)
    return $date.ToString("yyyyMMddTHHmmss")
}

function Get-EventsForWeek {
    param (
        [array]$eventTemplates,
        [DateTime]$weekStart
    )
    
    $events = @()
    foreach ($template in $eventTemplates) {
        $eventDate = Get-NextOccurrence -startDate $weekStart -dayOfWeek $template.day -time $template.time
        $events += @{
            summary = $template.summary
            start = $eventDate
            end = $eventDate.AddMinutes($template.duration)
            description = $template.description
        }
    }
    return $events
}

function ConvertTo-IcsContent {
    param ([array]$events)
    
    $icsContent = @"
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
"@

    foreach ($event in $events) {
        $startDate = Convert-ToIcsDate $event.start
        $endDate = Convert-ToIcsDate $event.end

        $icsContent += @"

BEGIN:VEVENT
DTSTART:$startDate
DTEND:$endDate
SUMMARY:$($event.summary)
DESCRIPTION:$($event.description)
END:VEVENT
"@
    }

    $icsContent += @"

END:VCALENDAR
"@

    return $icsContent
}

function Generate-DynamicEvents {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigFile,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFile,
        
        [Parameter(Mandatory=$true)]
        [string]$DateFlag
    )

    # Check if config file exists
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Config file not found. Please provide a valid path."
        return
    }

    # Read and parse the YAML config file
    $config = Get-Content -Path $ConfigFile | ConvertFrom-Yaml

    # Determine the start date for event generation based on the DateFlag
    $currentDate = Get-Date
    switch -Regex ($DateFlag) {
        "CurrentWeek" {
            $startDate = $currentDate.Date.AddDays(-([int]$currentDate.DayOfWeek))
        }
        "NextWeek" {
            $startDate = $currentDate.Date.AddDays(7 - [int]$currentDate.DayOfWeek)
        }
        "^(\d{1,2}/\d{1,2})$" {
            $parts = $DateFlag -split "/"
            $month = [int]$parts[0]
            $day = [int]$parts[1]
            $year = $currentDate.Year
            $startDate = New-Object DateTime($year, $month, $day)
        }
        "^(\d{1,2}/\d{1,2}/\d{2,4})$" {
            $parts = $DateFlag -split "/"
            $month = [int]$parts[0]
            $day = [int]$parts[1]
            $year = if ($parts[2].Length -eq 2) { 2000 + [int]$parts[2] } else { [int]$parts[2] }
            $startDate = New-Object DateTime($year, $month, $day)
        }
        default {
            Write-Host "Invalid DateFlag. Please use 'CurrentWeek', 'NextWeek', 'MM/DD', or 'MM/DD/YY(YY)'."
            return
        }
    }

    # Generate events
    $events = Get-EventsForWeek -eventTemplates $config.events -weekStart $startDate

    # Create ICS content
    $icsContent = ConvertTo-IcsContent -events $events

    # Write to ICS file
    $icsContent | Out-File -FilePath $OutputFile -Encoding ASCII

    Write-Host "ICS file has been created: $OutputFile"
}

# Export the main function
Export-ModuleMember -Function Generate-DynamicEvents
