##########################################
# 3d Signals API Utility for Work Orders #
#        Version 1.01, March 2021        #
##########################################


### GENERAL ###
The 3d Signals API Utility for Work Orders converts the contents of a CSV file to an API payload.
When the API is executed 3d Signals systems are updated with the information about which machine has which work orders.


### REQUIREMENTS ###

MACHINES AND WORK ORDERS INPUT FILE
The input file has a header row and two fields separated by a comma.
The first field contains a machine display name (as known to 3d Signals) and the second one a work order reference.
If a provided display name is unknown a warning message will be shown on screen.
The default path of the file is currently "./WO_List.csv".
To change it, edit the values in the ./config.txt file.

Here is an example for the contents of the file:
MACHINENAME,WO_DisplayName
H10,WO01
BW MCX1400,WO02
BW MCX1400,WO03
BW MCX1400,WO04
Zenith 400,WO05
Zenith 400,WO06
Zenith 400,WO07
Zenith 400,WO08
Zenith 400,WO09


CREDENTIALS FILE
A JSON file containing the username and password for getting the API token.
The default path of the file is ./credentials.json.
To change it, edit the CREDENTIALS_PATH variable in the ./config.txt file.
the contents of the file can be edited as needed.

Here is an example for the contents of the file:
{
    "userEmail":"{user@domain}",
    "password":"{password}"
}


VERBOSE MODE
For debugging the -v or -verbose flag can be added as an argument after the program name.
Examples:
./run_3ds_wo_api_util.sh -v
./run_3ds_wo_api_util.sh -verbose


USAGE HELP
For usage the -h or -help flag can be added as an argument after the program name.
Examples:
./run_3ds_wo_api_util.sh -h
./run_3ds_wo_api_util.sh -help
