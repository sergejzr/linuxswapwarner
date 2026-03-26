#!/usr/bin/env bash
set -u

#============= User Variables START ===================
GPROGRESS=1
threshold=20
check_interval=10
cooldown=300   # seconds between alerts

kill_on_demand() {
    echo "Closing Chrome gracefully..."
    pkill -TERM -x chrome 2>/dev/null || true
    pkill -TERM -x google-chrome 2>/dev/null || true
    pkill -TERM -x chromium 2>/dev/null || true
    sleep 5

    echo "Force killing remaining Chrome processes..."
    pkill -KILL -x chrome 2>/dev/null || true
    pkill -KILL -x google-chrome 2>/dev/null || true
    pkill -KILL -x chromium 2>/dev/null || true
}
#============= User Variables END =====================

progress_bar() {
    local current=$1
    local total=$2
    local progress done left fill empty

    (( total > 0 )) || return 1

    progress=$(( current * 100 / total ))
    done=$(( progress * 40 / 100 ))
    left=$(( 40 - done ))

    fill=$(printf "%${done}s")
    empty=$(printf "%${left}s")
    printf "\rProgress : [%s%s] %d%%" "${fill// /#}" "${empty// /-}" "$progress"
}

get_swap_values() {
    local total free
    while read -r key value _; do
        case "$key" in
            SwapTotal:) total=$value ;;
            SwapFree:)  free=$value ;;
        esac
    done < /proc/meminfo

    echo "${total:-0} ${free:-0}"
}

last_alert=0

while true; do
    read -r swap_total swap_free < <(get_swap_values)

    if (( swap_total == 0 )); then
        echo "No swap configured; sleeping."
        sleep "$check_interval"
        continue
    fi

    freeperc=$(( swap_free * 100 / swap_total ))

    if (( freeperc < threshold )); then
        now=$(date +%s)
        if (( now - last_alert < cooldown )); then
            sleep "$check_interval"
            continue
        fi
        last_alert=$now

        notify-send "Swap critical" "Free swap is at ${freeperc}%."

        if zenity --question \
            --title="Low swap" \
            --text="Swap critical (${freeperc}% free). Kill configured apps and clean swap?"; then

            kill_on_demand

            if ! sudo -n true 2>/dev/null; then
                notify-send "Swap cleanup failed" "sudo requires a password."
                echo "sudo requires password; cannot run swapoff/swapon non-interactively."
                sleep "$check_interval"
                continue
            fi

            echo "Turning swap off..."
            if (( GPROGRESS == 0 )); then
                sudo swapoff -a && sudo swapon -a
                echo "Swap cleaned."
            else
                (
                    echo "10"
                    echo "# Turning swap off..."
                    sudo swapoff -a || exit 1

                    echo "70"
                    echo "# Turning swap on..."
                    sudo swapon -a || exit 1

                    echo "100"
                    echo "# Done"
                ) | zenity --progress \
                    --title="Cleaning swap" \
                    --percentage=0 \
                    --auto-close \
                    --auto-kill
            fi

            notify-send "Swap cleaned" "Swap was cycled successfully."
        else
            echo "User cancelled."
        fi
    fi

    sleep "$check_interval"
done
