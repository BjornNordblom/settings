# settings
Setting files

# windows
## Cmd
HKEY_CURRENT_USER -> Environment -> PROMPT (REG_SZ) = CMD$S[$D $T$H$H$H]$S$M$_$P$G

Or system settings environment variable PROMPT.

## PS1
notepad $profile

Add:
```PS1
function prompt
{
  "PS [$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))] " + $(get-location) + "`n> "
}
```

## Environment

### GNU file
```PS1
[System.Environment]::SetEnvironmentVariable('MAGIC','C:\Tools\magic',[System.EnvironmentVariableTarget]::Machine)
```

### GPG Language
```PS1
[System.Environment]::SetEnvironmentVariable('LANG','C',[System.EnvironmentVariableTarget]::Machine)
```
