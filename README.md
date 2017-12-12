# settings
Setting files

# windows
## Cmd
HKEY_CURRENT_USER -> Environment -> PROMPT (REG_SZ) = CMD$S[$D $T$H$H$H]$S$M$_$P$G

Or system settings environment variable PROMPT.

## PS1
notepad $profile

Add:
function prompt
{
  "PS [$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))] " + $(get-location) + "`n> "
}

