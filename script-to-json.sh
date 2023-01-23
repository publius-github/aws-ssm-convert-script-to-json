#!/usr/bin/env bash
#
# Usage:
# ./script-for-json.sh <script's path>
#


SCRIPT_PATH=${1:-}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
JSON_FILE_PATH="${SCRIPT_DIR}/json/.template.json"
JSON_FOLDER="${SCRIPT_DIR}/json/"
SCRIPT_NAME=${SCRIPT_PATH##*/}
JSON_NAME=${SCRIPT_NAME%.*}
STEP_NAME=$(echo "${JSON_NAME}" | sed -e 's/\(^\|-\)\([a-z]\)/\1\u\2/g' | sed "s/-//g")

Error () {
    echo "[ ERR ]  ${1} ..."
    echo "Exiting..."
    exit 1
}

Info () {
    echo "[ INFO ] ${1} ..."
}

CURRENT_PATH=$(pwd)

# validation of the arguments
[ -s ${SCRIPT_PATH} -a -s ${JSON_FILE_PATH} ] || Error "Please specify the correct arguments:  <relative path to script's folder> <relative path to json template folder>"

# reading the json file
TEMP_JSON_CONTENT=`jq '.' ${JSON_FILE_PATH}`
TEMP_JSON_CONTENT=`echo ${TEMP_JSON_CONTENT} | jq '.mainSteps[].inputs.runCommand = []'`

# adding the lines of scripts to .mainSteps[].inputs.runCommand array
I=0
while read -r LINE
do
    ((I++))
    if echo ${LINE} | grep -q '^$'
    then
        continue
    fi
    TEMP_JSON_CONTENT=`echo ${TEMP_JSON_CONTENT} | jq --arg LINE "${LINE}" '.mainSteps[].inputs.runCommand += [$LINE]'`
    [ "$?" -eq "0" ] || Error "Cannot add ${LINE} #${I} of '${SCRIPT_PATH}' to json file"
done < "${CURRENT_PATH}/${SCRIPT_PATH}"

# save result back to json file
echo ${TEMP_JSON_CONTENT} | jq '.' > "${JSON_FOLDER}/${JSON_NAME}.json"

if [ `jq '.mainSteps[].inputs.runCommand | length' ${JSON_FILE_PATH}` -gt 0 ]
then
    Info "Script content of '${SCRIPT_PATH}' was added to '${JSON_FOLDER}${JSON_NAME}.json' file"
else
    Error "There was issue with script's lines adding. Exit"
fi

sed -i "s/<description>/${JSON_NAME}/g" ${JSON_FOLDER}/${JSON_NAME}.json
sed -i "s/<name>/${STEP_NAME}/g" ${JSON_FOLDER}/${JSON_NAME}.json

if [[ ${SCRIPT_NAME} =~ .sh$ ]]; then
    sed -i "s/<action>/runShellScript/g" ${JSON_FOLDER}/${JSON_NAME}.json
    sed -i "s/<platformname>/Linux/g" ${JSON_FOLDER}/${JSON_NAME}.json
elif [[ ${SCRIPT_NAME} =~ .ps1$ ]]; then
    sed -i "s/<action>/runPowerShellScript/g" ${JSON_FOLDER}/${JSON_NAME}.json
    sed -i "s/<platformname>/Windows/g" ${JSON_FOLDER}/${JSON_NAME}.json
fi
