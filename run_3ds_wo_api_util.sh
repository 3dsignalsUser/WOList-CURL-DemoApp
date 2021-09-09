#!/bin/bash

##########################################
# 3d Signals API Utility for Work Orders #
#        Version 1.01, March 2021        #
##########################################


### GLOBAL VARIABLES ###
BRIGHT="\x1b[1m"
RESET_ALL="\x1b[0m"


### FUNCTIONS ###

function config_script()
{
# Check and get configuration
CONFIG_FILE="./config.txt"
local line

if [ ! -f "$CONFIG_FILE" ] ; then
      echo "Configuration file $CONFIG_FILE does not exist! Please check it." >&2
      exit 1
 fi

# Read the contents of the configuration file and evaluate each line (even if the last line doesn't end with /n)
while read -r line || [ -n "$line" ];
do
	eval $line
done < $CONFIG_FILE
}

function get_token()
{
	# Get token from getAPIToken API and return the bearer token, which will be used in the next calls
	if [ ! -f "$CREDENTIALS_PATH" ] ; then
      echo "Credentials file $CREDENTIALS_PATH does not exist! Please check it." >&2
      exit 1
  	fi
	local credentials=$(cat $CREDENTIALS_PATH)
	local token_url="$BASE_URL/api/v1/security/getAPIToken"
	local raw_token=$(curl --silent --location --request POST "$token_url" --header "Content-Type: application/json" --data-raw "$credentials")
	local clean_token=$(echo $raw_token | sed 's/^{"token":"//g' | sed 's/"}$//g')
	bearer_token="Authorization: Bearer $clean_token"
}

function get_3ds_machines()
{
	# Get machines from machineInfo API
	local machine_url="$BASE_URL/api/v1/machineInfo"
	local machine_info=$(curl --silent --location --request GET "$machine_url" --header "$bearer_token" --data-raw '')
	local itm
	local machine_info_brackets
	local machine_info_colons
	local machine_row
	local machine_row_len
 
	machine_array=()
	IFS='{' read -r -a machine_info_brackets <<< "$machine_info"
	for itm in "${machine_info_brackets[@]}"; do 
		IFS=',' read -r -a machine_info_colons <<< "$itm"
		machine_row=$(echo "${machine_info_colons[1]} ${machine_info_colons[0]}" | grep machineUniqueId | sed 's/^"machineUniqueId":"//g' | sed 's/ "machineDisplayName":"//g' | sed 's/"/;/g')
			machine_row_len="${#machine_row}"
			if [ $machine_row_len -gt 0 ]; then
				machine_array+=("$machine_row")
			fi
	done
	if [ "$verbose" -eq 1 ]; then
		echo "Machine array: ${machine_array[@]}" >&2
		echo
	fi
}

function get_translated_machine()
{
	# Translate a display name to a machine ID by searching machine_array
	local found=0
	local machine_rec
	local machine_pair_tr
	for machine_rec in "${machine_array[@]}"; do
		IFS=';' read -r -a machine_pair_tr <<< "$machine_rec"
			if [ "$1" == "${machine_pair_tr[1]}" ]; then
				found=1
		    	echo "${machine_pair_tr[0]}"
		    	break
		    fi
	done
	if [ $found -eq 0 ]; then
		echo "WARNING: Machine $1 cannot be translated since it has found no match!" >&2
	fi
}

function get_customer_machines_and_wos()
{
	local prev_display_name
	local display_name
	local work_order
	local translated_machine

	if [ ! -f "$WO_INPUT_FILE_PATH" ] ; then
      echo "Input file $WO_INPUT_FILE_PATH does not exist" >&2
      exit 2
     else
     	prev_display_name=""

     	# Ignore title (first) line, and sort the file first (make sure the last line is read even if it doesn't end with /n)
		sed 1d "$WO_INPUT_FILE_PATH" | sort | while IFS=, read -r display_name work_order || [ -n "$display_name" ]
		do
			if [ "$display_name" != "$prev_display_name" ]; then
				translated_machine=$(get_translated_machine "$display_name")
				if [ "$translated_machine" != "" ]; then
					printf "{\"machineId\": \"$translated_machine\", \"workingOrders\": ["
					printf "\"$work_order\","
				fi
			else
					printf "\"$work_order\","
			fi
			prev_display_name="$display_name"
		done
     fi
}

function get_wos_json()
{
	# Finalize the JSON format received from get_customer_machines_and_wos()
	local raw_json=$(get_customer_machines_and_wos)
	local no_brackets=$(echo "$raw_json" | sed 's/",{/"]},{/g' | sed 's/,$/]}/g')
	echo "{\"machines\": [$no_brackets]}"
}

function put_wos_json()
{
	local wo_url="$BASE_URL/api/v1/workOrderList"
	local wo_json=$(get_wos_json)
	local http_code=$(curl --silent -o /dev/null -s -w "%{http_code}\n" --location --request PUT "$wo_url" --header "$bearer_token" --header "Content-Type: application/json" --data-raw "$wo_json")
	if [ "$verbose" -eq 1 ]; then
		echo "WO JSON: $wo_json" >&2
		echo >&2
	fi
	if [ $http_code -eq 200 ];then
		echo "$http_code: Work orders have been successfully transmitted!"
	else
		echo "$http_code: An error has occurred!"
	fi
}


### MAIN SCRIPT ###

config_script

# Handle CLI arguments
verbose=0
if [ $# -eq 1 ]; then
	if [ "$1" == "-v" ] || [ "$1" == "-verbose" ]; then
		verbose=1
	elif [ "$1" == "-h" ] || [ "$1" == "-help" ]; then
		less ./README.txt
		exit 0
	else
		echo "Unknown flag: "$1". Exiting script" >&2
		echo
		printf "${BRIGHT}Usage${RESET_ALL}:\n" >&2
		echo "$0 [ -h | -help | -v | -verbose ]"
		echo "-h | -help: shows script usage and exits"
		echo "-v | -verbose: shows additional information upon run time"
		exit 3
	fi
fi

get_token
get_3ds_machines
put_wos_json

