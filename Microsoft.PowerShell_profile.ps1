
Set-Item -Path Env:OpenApiKey -Value sk-XXXXXXXXXXXX

function Get-FromGpt3 {
    param(
        [Parameter(Mandatory = $False)]
        [String]$Question = "",
        [Parameter(Mandatory = $false)]
        [String]$Session = "",
        [string[]]$ListSession,
        [switch]$ListSessions,
        [switch]$DeleteSessions,
        [string[]]$DeleteSession,
        [switch]$ExpandOnLast,
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

    if ($Session -eq "")
    {
        $Session = "Last"
    }

    Write-Debug "Session: `'$Session`' - Question: `'$Question`' - ListSessions: `'$ListSessions`' - ListSession: `'$ListSession`' - DeleteSessions: `'$DeleteSessions`' - DeleteSession: `'$DeleteSession`'"

    $Sessions = ((Get-Item -Path "Env:OpenApiSessions" -ErrorAction SilentlyContinue).Value | ConvertFrom-Json -AsHashtable -NoEnumerate -ErrorAction SilentlyContinue)

    if ($Sessions -eq $null)
    {
        $Sessions = [ordered]@{}
    } 
    if ($ListSessions)
    {
        if ($Sessions.Keys.Count -eq 0)
        {
            Write-Host "No sessions."
            return
        }
        $ListSession = $Sessions.Keys
    }
    if ($ListSession)
    {
        foreach ($k in $Sessions.Keys)
        {
            Write-Host "Listing contents of: $k" -ForegroundColor DarkCyan
            Write-Host $Sessions[$k].Prompt -ForegroundColor Cyan
        }
        return
    }
    if ($DeleteSessions)
    {
        if ($Sessions.Keys.Count -eq 0)
        {
            Write-Host "No sessions."
            return            
        }        
        $DeleteSession = $Sessions.Keys
    }
    if ($DeleteSession)
    {
        foreach ($k in $DeleteSession)
        {
            if ($Sessions.Keys -contains $k)
            {
                Write-Warning "Deleting session $k"
                $Sessions.Remove($k)
            }
        }
        Set-Item -Path "Env:OpenApiSessions" -Value ($Sessions | ConvertTo-Json)  
        return
    }
    if ($Question -eq "")
    {
        throw "No question provided."
    }

    # Read previous value, unless session Last and not ExpandOnLast
    if ($Sessions.Keys -contains $Session)
    {
        if (($Session -eq "Last") -and (-not $ExpandOnLast))
        {
            # Do nothing, this will overwrite session Last with current Question
        } else {
            $Question = $Sessions[$Session]["Prompt"] + "`n`n" + $Question 
        }
    } 

    $body = [ordered]@{ "model"=$Model; "temperature"=$Temperature; "stop"="\n"; "prompt"=$Question; "max_tokens"=$MaxTokens }
    Write-Host "Asking:" -ForegroundColor DarkGreen
    Write-Host ($Question | ConvertTo-Json) -ForegroundColor Green
    $response = Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $openApiBase64AuthInfo)} -Uri "https://api.openai.com/v1/completions" -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"
    Write-Host "Response:" -ForegroundColor DarkGreen
    if ($response.choices[0].text.Trim() -ne "")
    {
        $Answer = $response.choices[0].text.Trim()
        Write-Host $Answer -ForegroundColor Blue
    } else {
        Write-Error "Unkown response:"
        Write-Error ($response | ConvertTo-Json) 
        return
    }

    if ($Answer -ne "")
    {
        $Sessions[$Session] = @{ "Prompt"=($Question + "`n`n" + $Answer) }
        Set-Item -Path "Env:OpenApiSessions" -Value ($Sessions | ConvertTo-Json)  
    }

    Write-Debug "All sessions:"
    Write-Debug ($Sessions | ConvertTo-Json) 

    Write-Debug "Current session:"
    Write-Debug ($Sessions[$Session] | ConvertTo-Json)
}
