# YAML-to-ICS-Converter
YAML Converter

Example YAML

events:
  - summary: Email Follow-up
    day: Monday
    time: "15:00"
    duration: 30
    description: Weekly email follow-up
  - summary: Send Follow-up
    day: Monday
    time: "17:00"
    duration: 30
    description: Send weekly follow-up

Import the module
Import-Module .\DynamicEventGenerator.psm1

Example shell usage
# For current week
Generate-DynamicEvents -ConfigFile "path\to\event_config.yaml" -OutputFile "mycalendar.ics" -DateFlag "CurrentWeek"

# For next week
Generate-DynamicEvents -ConfigFile "path\to\event_config.yaml" -OutputFile "mycalendar.ics" -DateFlag "NextWeek"

# For a specific date (e.g., May 15th of the current year)
Generate-DynamicEvents -ConfigFile "path\to\event_config.yaml" -OutputFile "mycalendar.ics" -DateFlag "05/15"

# For a specific date with year (e.g., May 15th, 2024)
Generate-DynamicEvents -ConfigFile "path\to\event_config.yaml" -OutputFile "mycalendar.ics" -DateFlag "05/15/2024"
