
function Get-FromGpt3 {
    param(
        [Parameter(Mandatory = $False)]
        [String]$Question = "",
        [Parameter(Mandatory = $false)]
        [String]$Session = "",
        [Parameter(Mandatory = $false)]
        [ValidateScript({ $Session -ne "" })]
        [switch]$ListSessions,
        [Parameter(Mandatory = $false)]
        [switch]$DeleteSessions,
        [Parameter(Mandatory = $false)]
        [switch]$Tips,
        [decimal]$Temperature=0.7,
        [string]$Model="text-davinci-003",
        [int]$MaxTokens=200
    )
    # Set-Item -Path Env:OpenApiKey -Value <apikeyfromopenai>
    $openApiBase64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":{0}" -f $env:OpenApiKey)))

    if ($Tips)
    {
        @(
            "Ask for it to play the the role of a client, colleague, or talented expert.",
            "Ask for examples of what contradicts or challenge the common thought. Ask it to provoke thought.",
            "Ask for making uncommon angles or approaches to the problem.",
            "Since AI is generatating derivative work anyway, copy something good and ask AI to expand on it.",
            "Use it for brainstorming, ask for a list of important things on a subject. Ask it to narrow the list to the most common. Ask it for a summary of each.",
            "AI can create a syllabus for any topic.",
            "Explore the tonality. Ask for the answer in a satirical or clickbaity way.",
            "Lead by example to set the context. Provide one or more sentences to surrounding limitations or possibilities.",
            "Use some of these properties in a prompt> `'TASK:`', `'ACT AS:`', `'VOICE AND STYLE:`', `'TITLE:`'"
        ) | Write-Host "* $_"
        return
    }

    Write-Debug "Session: `'$Session`' - Question: `'$Question`' - List: `'$ListSessions`' - Delete: `'$DeleteSessions`'"

    $Sessions = [System.Management.Automation.OrderedHashtable]((Get-Item -Path "Env:OpenApiSessions" -ErrorAction SilentlyContinue).Value | ConvertFrom-Json -AsHashtable -NoEnumerate -ErrorAction SilentlyContinue)
    if ($Sessions -eq $null)
    {
        $Sessions = [System.Management.Automation.OrderedHashtable]@{}
    }    
    if ($ListSessions)
    {
        foreach ($k in $Sessions.Keys)
        {
            Write-Host "Listing contents of: $k" -ForegroundColor Cyan
            Write-Host $Sessions[$k].Prompts -ForegroundColor DarkCyan
        }
        return
    }
    if ($DeleteSessions)
    {
        Remove-Item -Path "Env:OpenApiSessions" -ErrorAction SilentlyContinue
        return
    }
    # Create or update if we have a question
    if (($Session -ne "") -and ($Question -ne ""))
    {
        if ($Sessions.ContainsKey($Session) -and $Sessions[$Session].ContainsKey("Prompts") -and $Sessions[$Session].ContainsKey("Updated") -and ($Question -ne ""))
        {
            $Sessions[$Session]["Prompts"] += $Question
            $Sessions[$Session]["Updated"] = (Get-Date).ToString("yyyy-MM-dd")
        } else {
            $Sessions[$Session] = @{ "Prompts"=[string[]]($Question);"Updated"=(Get-Date).ToString("yyyy-MM-dd") }
        }
    }

    # Read from session that contains whole context, or just use the question
    if ($Session -ne "")
    {
        $prompt = $Sessions[$Session]["Prompts"] -join "`n"
    } else {
        $prompt = $Question
    }
    $body = [ordered]@{ "model"=$Model; "temperature"=$Temperature; "stop"="\n"; "prompt"=$prompt; "max_tokens"=$MaxTokens }
    Write-Host "Asking:" -ForegroundColor Green
    Write-Host ($prompt | ConvertTo-Json) -ForegroundColor DarkGreen
    $response = Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $openApiBase64AuthInfo)} -Uri "https://api.openai.com/v1/completions" -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"
    Write-Host "Response:" -ForegroundColor Blue
    Write-Host ($response | ConvertTo-Json) -ForegroundColor DarkBlue

    # Append to our Sessions
    if (($Session -ne "") -and ($Question -ne "") -and ($response.choices[0].text -ne ""))
    {
        $Sessions[$Session]["Prompts"] += ($response.choices[0].text).Trim() + "`n`n"
        Set-Item -Path "Env:OpenApiSessions" -Value ($Sessions | ConvertTo-Json)  
    }
    Write-Debug $Sessions[$Session]
}
