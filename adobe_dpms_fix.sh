#!/bin/bash
# ver.: 0.0.2
# Script fixed dpms support when you watch flash video
# Author: drunia drunia@xakep.ru
#
# Version 0.0.2: Added chrome, firefox like a FLASH_LIB for monitoring proccess. 

MAX_CPU=

declare -r VER="0.0.2 alpha"
declare -r BNAME=$(basename $0)
declare -r LOG_FILE="/tmp/$(basename $0).log"
declare -r ACTION_KEY=Ctrl
declare -r XDOTOOL=xdotool
declare -r FLASH_LIB="libflashplayer.so chrome.*ppapi firefox"
declare -r REFRESH_TIME=45s 
declare -i cpu_load=0
declare proc_id=0


# Function get cputime by FLASH_LIB
get_cpu_percent() {
	proc_id=0
	local cpu=0
	#Find proccess, first libflashplayer.so
	for proccess in $FLASH_LIB; do
	  local flash_pid=$(ps aux | grep -v grep | grep $proccess | awk '{print $2}')
	  [ -n "$flash_pid" ] || continue
	  
	  #Select proccess ID with highnest CPU load
	  for pid in $flash_pid; do
	    #echo "check proccess $proccess for load CPU"
	    cpu_load=$(top -n 1 -p $pid -b | tail -n 2 | head -n 2 \
		| sed 's/.*PID.*$//g' | awk '{print $9}' | sed 's/[\.,].*//g')
	    #echo "\$cpu_load = $cpu_load | \$cpu = $cpu"
	    if [[ $cpu_load -gt $cpu ]]; then
	      proc_id=$pid
	      cpu=$cpu_load
	    fi
	  done
	done
	
	cpu_load=$cpu
	return 0
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
		read
		exit 1
	fi 
	return 0
}

calculate_cpu_power() {
	# Exit if freq setted nanually
	[ -z "$MAX_CPU" ] || {
		echo "MAX_CPU on working flashplayer manualy set to $MAX_CPU%"
		echo "for automatically erase constant MAX_CPU value on script header."
		echo "Example: MAX_CPU="
		return 0
	}
	local mhz=$(cat /proc/cpuinfo | grep MHz | head -n 1 \
		| sed 's/.*\://g' | sed 's/[\.,].*//g')
	MAX_CPU=$(expr  40 - \( $mhz / 100 \))
	echo "MAX_CPU on working flashplayer automaticaly set to $MAX_CPU%"
	echo "for manualy set initialize constant MAX_CPU on script header."
	echo "Example: MAX_CPU=15"
	return 0 
}


#Stop script
stop() {
	if [ -e /tmp/$BNAME.pid ] 
	then
		pid=$(cat /tmp/$BNAME.pid)
		ps -p $pid 1>/dev/null 2>&1
		[ $? -ne 0 ] || {
			echo -n "Stopping $BNAME..."
			rm /tmp/$BNAME.pid
			kill $pid
			[ $? -ne 0 ] || {
				echo "OK"
				exit 6
			}
			echo "FAIL"
			exit 10
		} 
		echo "Error: $BNAME not running, but pidfile exist"
		echo -n "Try remove..."
		rm /tmp/$BNAME.pid && {
			echo "OK"
			exit 0
		}
		echo "FAIL"
	else 
		echo "$BNAME not running."
	fi
	exit 0
}

#Init
case $1 in
	"stop" ) $1 ;;

	"" | "start")
	echo "adobe_dpms_flash_fix ver.: $VER"
	echo ""
	check_depends
	calculate_cpu_power
	echo ""
	
	if [ -e /tmp/$BNAME.pid ] 
	then
		pid=$(cat /tmp/$BNAME.pid)
		ps -p $pid 1>/dev/null 2>&1
		[ $? -ne 0 ] || {
			echo "Error: $BNAME already running."
			sleep 3s
			exit 5
		} 
		rm /tmp/$BNAME.pid
	fi
	exec /bin/bash $0 "--daemon" >$LOG_FILE 2>&1 &
	exit 0
	;;
 
	"--daemon" )
	echo "Daemon: OK"
	echo "adobe_dpms_flash_fix ver.: $VER"
	echo ""
	calculate_cpu_power
	echo ""
	echo $$ > /tmp/$BNAME.pid
	;;

	* ) 
	echo "Usage: $0 start | stop"
	exit 1
	;;
esac


# Main program cicle
while [ 0 ]
do
	get_cpu_percent
	if [ $cpu_load -gt $MAX_CPU ]
	then
		echo "$(date): Detect active, PID $proc_id, load CPU: $cpu_load%"
		do_action
	else
		echo "$(date): Idle, CPU: $cpu_load%"
	fi  
	sleep $REFRESH_TIME	
done

#good bye
exit 0
