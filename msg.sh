#!/bin/bash 

case "$1" in
        warn)
            echo -n -e "\033[0;33m$2\033[0m"
            ;;
        error)
            echo -n -e "\033[31m$2\033[0m"
            ;;
        info)
            echo -n -e "\033[34m$2\033[0m"
            ;;
        success)
             echo -n -e "\033[32m$2\033[0m"
            ;;
        lol)
            echo -n "$2" | lolcat -F .4
            ;;
        *)

esac
if [[ "1" -eq $3 ]]; then echo ""; fi
