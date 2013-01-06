#!/bin/bash
# ver.: 0.0.1
# Script fixed dpms support when you wach flash video
# Author: drunia drunia@xakep.ru

MAX_CPU=

declare -r VER="0.0.1 alpha"
declare -r LOG_FILE="/tmp/$(basename $0).log"
declare -r ACTION_KEY=Ctrl
declare -r XDOTOOL=xdotool
declare -r FLASH_LIB="libflashplayer.so"
declare -r REFRESH_TIME=3s 
declare -i cpu_load=0

# Function get cputime by FLASH_LIB
get_cpu_percent() {
	local flash_pid=$(ps axww | grep -v grep | grep $FLASH_LIB | awk '{print $1}')
	[ -n "$flash_pid" ] || {
		cpu_load=0
		return 1
	}
	#echo "PID=$flash_pid"
	cpu_load=$(top -n 1 -p $flash_pid -b | tail -n 2 | head -n 2 | sed 's/.*PID.*$//g' | awk '{print $9}' | sed 's/[\.,].*//g')
	return $?
}

# Function set screen ON
do_action() {
	echo "$(date): CPU: $cpu_load% > $MAX_CPU% - Do action (Press key $ACTION_KEY)"
	$XDOTOOL key $ACTION_KEY
	return $?
}

# Function check depends
check_depends() {
	local s=$(whereis $XDOTOOL | sed 's/.*\://g')
	if [ -z "$s" ] 
	then
		echo $XDOTOOL not found, please install it before use this script.
		exit 1
	fi 
	return 0
}

calculate_cpu_power() {
	# Exit if freq setted nanually
	[ -z "$MAX_CPU" ] || {
		echo "MAX_CPU on working flashplayer manualy set to $MAX_CPU%"
		echo "for automatically set erase constant value MAX_CPU on script header."
		echo "Example: MAX_CPU="
		return 0
	}
	local mhz=$(cat /proc/cpuinfo | grep MHz | head -n 1 | sed 's/.*\://g' | sed 's/[\.,].*//g')
	MAX_CPU=$(expr  40 - \( $mhz / 100 \))
	echo "MAX_CPU on working flashplayer automaticaly set to $MAX_CPU%"
	echo "for manualy set initialize constant MAX_CPU on script header."
	return 0 
}

echo "adobe_dpms_flash_fix ver.: $VER"
echo ""
check_depends
calculate_cpu_power
echo ""

# Main program cicle
while [ 0 ]
do
	get_cpu_percent
	if [ $cpu_load -gt $MAX_CPU ]
	then
		echo "$(date): Detect active $FLASH_LIB load CPU: $cpu_load%"
		do_action
	else
		echo "$(date): $FLASH_LIB not active detected CPU: $cpu_load%"
	fi  
	sleep $REFRESH_TIME	
done

#good bye
exit 0
