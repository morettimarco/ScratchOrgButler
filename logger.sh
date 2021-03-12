

#!/bin/bash

function chatter(){
if [[ "$1" == "WARN" ]]; then
    printf '\e[1;33m%-6s\e[m\n' "$2"
elif [[ "$1" == "LOG"* ]]; then
    printf '\e[1;34m%-6s\e[m\n' "$2"
elif [[ "$1" == "ERR" ]]; then
    printf '\e[1;31m%-6s\e[m\n' "$2"
    notifier "$2"
fi
}

function notifier(){
    # Display a notification for the specfic OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display notification \"$1\" with title \"Scratch Org Butler\" sound name \"Blow\""
        say "$1"&
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            : #NEED TO COMPLETE FOR SPECIFIC OS
    elif [[ "$OSTYPE" == "cygwin" ]]; then
            : #NEED TO COMPLETE FOR SPECIFIC OS
    elif [[ "$OSTYPE" == "msys" ]]; then
            : #NEED TO COMPLETE FOR SPECIFIC OS
    elif [[ "$OSTYPE" == "win32" ]]; then
            : #NEED TO COMPLETE FOR SPECIFIC OS
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
            : #NEED TO COMPLETE FOR SPECIFIC OS
    else
            : #NEED TO COMPLETE FOR SPECIFIC OS
    fi
}