set no-exit-message
set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']


[script]
[working-directory('../')]
gen_age_secret:
    if [ ! -f age.key ]; then
        just log info "Generating age key"
        age-keygen -pq -o ./age.key
    else 
        just log info "Age key exists"
    fi

