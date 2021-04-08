# linuxswapwarner
As Linux user you probably have to deal with memory limits. The not so nice thing is that linux desktop suddendly looses reaction in case both, main memory and swap are full. 
This script, runs in background (or can be modified and installed as a cronjob). it checks the left swap and asks user for interaction in case the amount is less than defined threshold. You can ignore the prompt and free the memory yourself, or let the script do this. In my case usually killing the Webbrowser gives the most memory back and saves me from freesing the desktop.

There are three variables that can be configured at the beginning of the script:

#Grafic progressbar should work everywhere with zenity. If 0 the bash PB will be used
GPROGRESS=1

#What is the lowest percentage of free swap to alert for
threshold=20

#What should happen if user agrees to clean swap?
function killOnDemand {
    echo "Kill Chrome"
    killall -9 chrome
}

Enjoy

Credits:
The bash progressbar was taken from https://github.com/fearside/ProgressBar/
