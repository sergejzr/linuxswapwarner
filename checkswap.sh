#!/bin/bash


#=============User Variables START===================
#Grafic progressbar should work everywhere with zenity
GPROGRESS=1

#What is the lowest percentage of free swap to alert for
threshold=20

#What should happen if user agrees to clean swap?
function killOnDemand {
    echo "Kill Chrome"
    killall -9 chrome
}

#=============User Variables END===================





# Shel based progress bar
function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:                           
# 1.2.1.1 Progress : [########################################] 100%
    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}



#START Logic
while true; do

#Calculate free swap percentage 
swapfree=$(sed -n '/SwapFree/s/[^[:digit:]]*\([[:digit:]]*\).*/\1/p' /proc/meminfo)

swapall=$(sed -n '/SwapTotal/s/[^[:digit:]]*\([[:digit:]]*\).*/\1/p' /proc/meminfo)

freeperc=$(( $swapfree * 100 / $swapall ))



if [[ $freeperc -lt $threshold ]] ; then
    notify-send 'title' 'Swap critical! Clean-Dialog will popup now'
    $(zenity --question --text="Swap critical ($freeperc %) ! Kill defined apps and free swap?")

    if [[ $? -eq 0 ]]; then
    
        killOnDemand
    
        echo "Swap Off-Signal"
        sudo swapoff -a 
        echo "Wait of OS to free swap"
        if [[ $GPROGRESS -eq 0 ]]; then
            # Variables
            _start=1

            # This accounts as the "totalState" variable for the ProgressBar function
            _end=400

            # Proof of concept
            for number in $(seq ${_start} ${_end})
            do
                sleep 0.1
                ProgressBar ${number} ${_end}
            done
        printf '\nFinished!\n'

        elif [[ $GPROGRESS -eq 1 ]]; then
    
            ( 
            echo "10"; sleep 3
            echo "20"; sleep 3
            echo "30"; sleep 3
            echo "40"; sleep 3
            echo "50"; sleep 3
            echo "60"; sleep 3
            echo "70"; sleep 3
            echo "80"; sleep 3
            echo "90"; sleep 3
            echo "100"; sleep 3
            )  | zenity --progress --auto-close --auto-kill --title="Wait of OS to free swap" --percentage=0
    
        fi

        #sudo swapon -a 
        echo "Swap cleaned"

    elif [[ $? -eq 1 ]]; then
        echo "Cancel"
    fi
fi
sleep 10
done
