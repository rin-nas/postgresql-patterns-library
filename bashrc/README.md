# Удобное цветное приглашение командной строки в `bash`

![bashrc](bashrc.png)

Добавьте код ниже в конец файла `~/.bashrc` и перезапустите терминал.

```bash
PROMPT_COMMAND=__prompt_command  # Function to generate PS1 after CMDs

__prompt_command() {
    local EXIT="$?" # This needs to be first

    # https://robotmoon.com/bash-prompt-generator/
    local Red='\[\e[1;31m\]'
    local Green='\[\e[0;32m\]'
    local Yellow='\[\e[38;5;220m\]'
    local Blue='\[\e[38;5;39m\]'
    local Orange='\[\e[38;5;214m\]'
    local Magenta='\[\e[0;35m\]'
    local Cyan='\[\e[0;36m\]'
    local White='\[\e[0;37m\]'
    local Reset='\[\e[0m\]'

    PS1="\n"           #newline
    PS1+="${Cyan}$(date --rfc-3339=seconds) " #datetime
    PS1+="${Yellow}\u" #user
    PS1+="${Cyan}@"    #@
    PS1+="${Orange}\h" #host
    PS1+="${Cyan} "    #
    PS1+="${Blue}\w"   #directory
    PS1+="\n"
    
    if [ $EXIT != 0 ]; then
        PS1+="${Red}${EXIT} \$ ${Reset}"
    else
        PS1+="${Green}\$ ${Reset}"
    fi
}
```
