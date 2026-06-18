#!/bin/bash

#set -euo pipefail

_me=$(basename "$0")

_CFG=""
_PATCH_CR="false"
_ERROR=0

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
_INST_TMP_FOLDER="/tmp"
setTemporaryFolder () {
  _OK=0
  _ERR_MSG_FOLDER="is a folder"
  _ERR_MSG_PERMISSIONS=""
  if [[ ! -z "${CP4BA_INST_TMP_FOLDER}" ]]; then
    if [[ -d "${CP4BA_INST_TMP_FOLDER}" ]]; then
      if [[ -r "${CP4BA_INST_TMP_FOLDER}" ]] && [[ -w "${CP4BA_INST_TMP_FOLDER}" ]]; then 
        _OK=1
      else
        _ERR_MSG_PERMISSIONS=", you have not rights to read and/or write"
        _OK=-1
      fi
    else
      _ERR_MSG_FOLDER="is NOT a folder"
    fi

    if [[ $_OK -lt 1 ]]; then
      echo -e "${_CLR_RED}[✗] ERROR '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' is not a valid temporary folder, check if it is a folder or if you have write permissions !${_CLR_NC}"
      echo -e "${_CLR_RED} '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' ${_ERR_MSG_FOLDER}${_ERR_MSG_PERMISSIONS}${_CLR_NC}"
      exit 1
    fi
    export _INST_TMP_FOLDER="${CP4BA_INST_TMP_FOLDER}"
  fi
  log_info "${_CLR_GREEN}Running with temporary folder '${_CLR_YELLOW}${_INST_TMP_FOLDER}${_CLR_GREEN}'${_CLR_NC}"

}

#--------------------------------------------------------
# read command line params
while getopts c:p flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        p) _PATCH_CR="true";;        
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -p (optional)patch-cr"
  exit
fi

source "${_CFG}" 2>/dev/null

#----------------------------------------------------
_SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${_SCRIPT_PATH}" ]; do
  _SCRIPT_DIR="$(cd -P "$(dirname "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  _SCRIPT_PATH="$(readlink "${_SCRIPT_PATH}")"
  [[ ${_SCRIPT_PATH} != /* ]] && _SCRIPT_PATH="${_SCRIPT_DIR}/${_SCRIPT_PATH}"
done
_SCRIPT_PATH="$(readlink -f "${_SCRIPT_PATH}")"
_SCRIPT_DIR="$(cd -P "$(dirname -- "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"

#----------------------------------------------------
if [[ ! -f "$_SCRIPT_DIR/../../cp4ba-logger/scripts/logger.sh" ]]; then
  echo "Error, log package not found !"
  echo "Clone it alongside with other cp4ba-..."
  echo "use the command: git clone https://github.com/marcoantonioni/cp4ba-logger"
  exit 1
fi
source $_SCRIPT_DIR/../../cp4ba-logger/scripts/logger.sh
if [[ -z "${CP4BA_LOGGING_ENABLED}" ]]; then 
  export CP4BA_LOGGING_ENABLED=true
fi
if [[ -z "${CP4BA_LOG_LEVEL}" ]]; then 
  export CP4BA_LOG_LEVEL="INFO"
fi
if [[ -z "${CP4BA_LOG_TO_CONSOLE}" ]]; then 
  export CP4BA_LOG_TO_CONSOLE=true
fi
if [[ -z "${CP4BA_LOG_TO_FILE}" ]]; then 
  export CP4BA_LOG_TO_FILE=false
fi
if [[ -z "${CP4BA_LOG_FILE}" ]]; then 
  export CP4BA_LOG_FILE=""
fi
if [[ -z "${CP4BA_LOG_MAX_SIZE}" ]]; then 
  export CP4BA_LOG_MAX_SIZE=$((10 * 1024 * 1024))
fi
if [[ -z "${CP4BA_LOG_BACKUP_COUNT}" ]]; then 
  export CP4BA_LOG_BACKUP_COUNT=5
fi


createLibertyXMLSecret () {

  #---------------------------------------------
  # custom DB for applications
  if [[ -z "${CP4BA_INST_DB_CUSTOMDB_SERVER}" ]]; then
    export CP4BA_INST_DB_CUSTOMDB_SERVER="${CP4BA_INST_DB_1_SERVER_NAME}"
  fi
  if [[ -z "${CP4BA_INST_DB_CUSTOMDB_NAME}" ]]; then
    export CP4BA_INST_DB_CUSTOMDB_NAME="mydb"
  fi
  if [[ -z "${CP4BA_INST_DB_CUSTOMDB_USER}" ]]; then
    export CP4BA_INST_DB_CUSTOMDB_USER="myuser"
  fi
  if [[ -z "${CP4BA_INST_DB_CUSTOMDB_PWD}" ]]; then
    export CP4BA_INST_DB_CUSTOMDB_PWD="dem0s"
  fi

  if [[ -z "${CP4BA_INST_DB_CUSTOMDB_MAX_POOL_SIZE}" ]]; then
    export CP4BA_INST_DB_CUSTOMDB_MAX_POOL_SIZE="30"
  fi
  if [[ -z "${CP4BA_INST_DB_CUSTOMDB_MIN_POOL_SIZE}" ]]; then
    export CP4BA_INST_DB_CUSTOMDB_MIN_POOL_SIZE="10"
  fi


  #---------------------------------------------
  _FULL_PATH="${_SCRIPT_DIR}/../${CP4BA_INST_CUSTOM_XML_FOLDER_NAME}/${CP4BA_INST_LIBERTY_CUSTOM_XML_TEMPLATE_NAME}"
  if [[ -f "${_FULL_PATH}" ]]; then

    _SECRET_FILE_NAME="${_INST_TMP_FOLDER}/secret-baw-runtime-$USER-$RANDOM.xml"

    log_info "${_CLR_GREEN}Using Liberty xml template '${_CLR_YELLOW}${CP4BA_INST_LIBERTY_CUSTOM_XML_TEMPLATE_NAME}${_CLR_GREEN}' for secret '${_CLR_YELLOW}${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME}${_CLR_GREEN}'"
    envsubst < ${_FULL_PATH} > ${_SECRET_FILE_NAME}
    if [[ $? -ne 0 ]]; then
      log_warning "[✗] Warning, custom liberty xml file '${_SECRET_FILE_NAME}' not generated.${_CLR_NC}"
    fi

    log_debug "Secret '${_CLR_YELLOW}${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME}${_CLR_NC}'"
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME} 2> /dev/null 1> /dev/null
    oc create secret generic -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME} --from-file=sensitiveCustomConfig=${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null
    if [[ $? -gt 0 ]]; then
      _ERROR=1
      log_error "${_CLR_RED}Secret '${_CLR_YELLOW}${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME}${_CLR_RED}' NOT created !!!${_CLR_NC}"
    else
      if [[ "${CP4BA_INST_DB_CUSTOM}" = "true" ]]; then
        log_info "${_CLR_GREEN}Custom database jndi name is '${_CLR_YELLOW}jdbc/${CP4BA_INST_DB_CUSTOMDB_NAME}${_CLR_GREEN}'"
      fi
    fi
    rm ${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null
  else
    log_error "File not found '${_FULL_PATH}'"
    export CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME="null"
  fi 


}

createLombardiXMLSecret () {

  _FULL_PATH="${_SCRIPT_DIR}/../${CP4BA_INST_CUSTOM_XML_FOLDER_NAME}/${CP4BA_INST_LOMBARDI_CUSTOM_XML_TEMPLATE_NAME}"
  if [[ -f "${_FULL_PATH}" ]]; then

    #---------------------------------------------
    # dynamic values, use following vars in your template
    export _AGENT_FQDN_BASE=$(oc cluster-info | sed 's/.*https:\/\/api.//g' | sed 's/:.*//g' | head -n1)
    export _AGENT_FQDN_FULL="https://${CP4BA_INST_CPD_CONSOLE_PREFIX}.${_AGENT_FQDN_BASE}"


    _SECRET_FILE_NAME="${_INST_TMP_FOLDER}/secret-100Custom-runtime-$USER-$RANDOM.xml"

    log_info "${_CLR_GREEN}Using Lombardi xml template '${_CLR_YELLOW}${CP4BA_INST_LOMBARDI_CUSTOM_XML_TEMPLATE_NAME}${_CLR_GREEN}' for secret '${_CLR_YELLOW}${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME}${_CLR_GREEN}'"
    envsubst < ${_FULL_PATH} > ${_SECRET_FILE_NAME}
    if [[ $? -ne 0 ]]; then
      log_warning "[✗] Warning, custom lombardi xml file '${_SECRET_FILE_NAME}' not generated.${_CLR_NC}"
    fi

    log_debug "Secret '${_CLR_YELLOW}${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME}${_CLR_NC}'"
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME} 2> /dev/null 1> /dev/null
    oc create secret generic -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME} --from-file=sensitiveCustomConfig=${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null

    if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret '${_CLR_YELLOW}${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME}${_CLR_RED}' NOT created !!!${_CLR_NC}"
    fi

    rm ${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null
  else
    log_error "File not found '${_FULL_PATH}'"
    export CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME="null"
  fi
}

createCustomXMLSecrets () {
  if [[ -z "${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME}" ]]; then
    export CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME="my-liberty-custom-xml-secret"
  fi
  if [[ -z "${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME}" ]]; then
    export CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME="my-lombardi-custom-xml-secret"
  fi
  if [[ -z "${CP4BA_INST_CUSTOM_XML_FOLDER_NAME}" ]]; then
    export CP4BA_INST_CUSTOM_XML_FOLDER_NAME="templates-custom-xml"
  fi
  if [[ -z "${CP4BA_INST_LIBERTY_CUSTOM_XML_TEMPLATE_NAME}" ]]; then
    export CP4BA_INST_LIBERTY_CUSTOM_XML_TEMPLATE_NAME="liberty-custom-xml-template"
  fi
  if [[ -z "${CP4BA_INST_LOMBARDI_CUSTOM_XML_TEMPLATE_NAME}" ]]; then
    export CP4BA_INST_LOMBARDI_CUSTOM_XML_TEMPLATE_NAME="lombardi-custom-xml-template"
  fi

  createLibertyXMLSecret
  
  createLombardiXMLSecret

}

patchCR () {

  if [[ ${CP4BA_INST_OPT_COMPONENTS} == *"baw_authoring"* ]] || [[ ${CP4BA_INST_OPT_COMPONENTS} == *"wfps_authoring"* ]]; then
    log_info "${_CLR_GREEN}Patching authoring ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"

    oc patch ICP4ACluster ${CP4BA_INST_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type=json -p '[{ "op": "replace", "path": "/spec/workflow_authoring_configuration/custom_xml_secret_name", "value": '${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME}' }]' 2>/dev/null 1>/dev/null

    oc patch ICP4ACluster ${CP4BA_INST_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type=json -p '[{ "op": "replace", "path": "/spec/workflow_authoring_configuration/lombardi_custom_xml_secret_name", "value": '${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME}' }]' 2>/dev/null 1>/dev/null

  else
    log_info "${_CLR_GREEN}Patching runtime ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"

    _SECTION_NAME="baw_configuration"
    echo "Patch CR RUNTIME not yet implemented"
  fi

}

log_msg "=============================================================="
log_info "${_CLR_GREEN}Creating custom xml secrets in '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"

setTemporaryFolder

createCustomXMLSecrets
if [[ "${_PATCH_CR}" = "true" ]]; then
  patchCR
fi
