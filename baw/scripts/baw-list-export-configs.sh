#!/bin/bash
_me=$(basename "$0")

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

_CFG=""
_SCRIPTS=""
_BAW_TMP_FOLDER=""
_SHOW_SECRET_NAMES=false
_DUMP_SECRET_VALUES=false
_EXPORT_SECRET_VALUES=false
_CP4BA_CR=""

_LIBERTY_SECRET_ATTR_NAME="custom_xml_secret_name"
_LOMBARDI_SECRET_ATTR_NAME="lombardi_custom_xml_secret_name"

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"


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
if [[ ! -f "$_SCRIPT_DIR/../../../cp4ba-logger/scripts/logger.sh" ]]; then
  echo "Error, log package not found !"
  echo "Clone it alongside with other cp4ba-..."
  echo "use the command: git clone https://github.com/marcoantonioni/cp4ba-logger"
  exit 1
fi
source $_SCRIPT_DIR/../../../cp4ba-logger/scripts/logger.sh
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
      log_error "${_CLR_RED}[✗] ERROR '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' is not a valid temporary folder, check if it is a folder or if you have write permissions !${_CLR_NC}"
      log_error "${_CLR_RED}'${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' ${_ERR_MSG_FOLDER}${_ERR_MSG_PERMISSIONS}${_CLR_NC}"
      exit 1
    fi
    export _INST_TMP_FOLDER="${CP4BA_INST_TMP_FOLDER}"
  fi
  log_info "${_CLR_GREEN}Running with temporary folder '${_CLR_YELLOW}${_INST_TMP_FOLDER}${_CLR_GREEN}'${_CLR_NC}"
}

usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me
    -c full-path-to-config-file
       (eg: '../configs/env1.properties')
    -s (optional)show-secret-names
    -d (optional)dump-secret-values 
    -e (optional)export-secret-values${_CLR_NC}"
}


#--------------------------------------------------------
# read command line params
while getopts c:sde flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        s) _SHOW_SECRET_NAMES=true;;
        d) _DUMP_SECRET_VALUES=true;;
        e) _EXPORT_SECRET_VALUES=true;;
        \?) # Invalid option
            echo "Invalid option: "${flag}
            usage
            exit 1;;        
    esac
done
if [[ -z "${_CFG}" ]]; then
  echo "Configuration file name is empty"
  usage
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: ${_CFG}"
  usage
  exit 1
fi

source "${_CFG}" 2>/dev/null 1>/dev/null 

onExit () {

  if [[ ! -z "${_BAW_TMP_FOLDER}" ]]; then
    log_info "${_CLR_GREEN}Removing temporary folder: '${_CLR_YELLOW}${_INST_TMP_FOLDER}/${_BAW_TMP_FOLDER}${_CLR_NC}'"    
    echo rm -fR "${_INST_TMP_FOLDER}/${_BAW_TMP_FOLDER}" 2 >/dev/null
  fi 

}

#------------------------

listBAWsAuthoring () {
  log_info "${_CLR_GREEN}List of BAW authoring names found in CR '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}'"
  log_msg

# bastudio_configuration
#   custom_secret_name

  if [[ "${_SHOW_SECRET_NAMES}" = "true" ]]; then

    _BASTUDIO_CFG_CUST_SECRET_NAME=$(echo ${_CP4BA_CR} | jq '.spec.bastudio_configuration.custom_secret_name' | sed 's/"//g')
    __WRKFLW_AUTHOR_CFG_LIBERTY_XML_SECRET_NAME=$(echo ${_CP4BA_CR} | jq '.spec.workflow_authoring_configuration.custom_xml_secret_name' | sed 's/"//g')
    __WRKFLW_AUTHOR_CFG_LOMBARDI_XML_SECRET_NAME=$(echo ${_CP4BA_CR} | jq '.spec.workflow_authoring_configuration.lombardi_custom_xml_secret_name' | sed 's/"//g')

    log_msg "${_CLR_GREEN}--BAStudio custom secret name '${_CLR_YELLOW}${_BASTUDIO_CFG_CUST_SECRET_NAME}${_CLR_GREEN}'"
    log_msg "${_CLR_GREEN}--Liberty secret name '${_CLR_YELLOW}${__WRKFLW_AUTHOR_CFG_LIBERTY_XML_SECRET_NAME}${_CLR_GREEN}'"
    log_msg "${_CLR_GREEN}--Lombardi secret name '${_CLR_YELLOW}${__WRKFLW_AUTHOR_CFG_LOMBARDI_XML_SECRET_NAME}${_CLR_GREEN}'"

    if [[ "${_DUMP_SECRET_VALUES}" = "true" ]]; then
      _BAS_CUSTOM_XML_CONTENT=""
      _LIBERTY_XML_CONTENT=""
      _LOMBARDI_XML_CONTENT=""

      if [[ ! -z "${_BASTUDIO_CFG_CUST_SECRET_NAME}" && "${_BASTUDIO_CFG_CUST_SECRET_NAME}" != "null" ]]; then
        _BAS_CUSTOM_XML_CONTENT=$(oc get secret -n ${CP4BA_INST_NAMESPACE} ${_BASTUDIO_CFG_CUST_SECRET_NAME} -o jsonpath='{.data.sensitiveCustomConfig}' | base64 -d)
      fi

      if [[ ! -z "${__WRKFLW_AUTHOR_CFG_LIBERTY_XML_SECRET_NAME}" && "${__WRKFLW_AUTHOR_CFG_LIBERTY_XML_SECRET_NAME}" != "null" ]]; then
        _LIBERTY_XML_CONTENT=$(oc get secret -n ${CP4BA_INST_NAMESPACE} ${__WRKFLW_AUTHOR_CFG_LIBERTY_XML_SECRET_NAME} -o jsonpath='{.data.sensitiveCustomConfig}' | base64 -d)
      fi

      if [[ ! -z "${__WRKFLW_AUTHOR_CFG_LOMBARDI_XML_SECRET_NAME}" && "${__WRKFLW_AUTHOR_CFG_LOMBARDI_XML_SECRET_NAME}" != "null" ]]; then
        _LOMBARDI_XML_CONTENT=$(oc get secret -n ${CP4BA_INST_NAMESPACE} ${__WRKFLW_AUTHOR_CFG_LOMBARDI_XML_SECRET_NAME} -o jsonpath='{.data.sensitiveCustomConfig}' | base64 -d)
      fi

      log_msg "${_CLR_GREEN}--BAStudio xml content:\n${_CLR_YELLOW}${_BAS_CUSTOM_XML_CONTENT}${_CLR_GREEN}"
      log_msg "${_CLR_GREEN}--Liberty xml content:\n${_CLR_YELLOW}${_LIBERTY_XML_CONTENT}${_CLR_GREEN}"
      log_msg "${_CLR_GREEN}--Lombardi xml content:\n${_CLR_YELLOW}${_LOMBARDI_XML_CONTENT}${_CLR_GREEN}"

    fi

    _BAW_NAME="bastudio"
    if [[ "${_EXPORT_SECRET_VALUES}" = "true" ]]; then
      if [[ ! -z "${_BASTUDIO_CFG_CUST_SECRET_NAME}" && "${_BASTUDIO_CFG_CUST_SECRET_NAME}" != "null" ]]; then
        _OUT_FILE_SECRET_BASTUDIO="../export/secret-value-${CP4BA_INST_NAMESPACE}-${CP4BA_INST_CR_NAME}-${_BAW_NAME}-${_BASTUDIO_CFG_CUST_SECRET_NAME}.xml"
        echo "${_BAS_CUSTOM_XML_CONTENT}" > "${_OUT_FILE_SECRET_BASTUDIO}"
        log_msg "${_CLR_GREEN}--BAStudio xml content saved in '${_CLR_YELLOW}${_OUT_FILE_SECRET_LIBERTY}${_CLR_GREEN}'"
      else
        log_msg "${_CLR_GREEN}--BAStudio secret not defined."
      fi

      if [[ ! -z "${__WRKFLW_AUTHOR_CFG_LIBERTY_XML_SECRET_NAME}" && "${__WRKFLW_AUTHOR_CFG_LIBERTY_XML_SECRET_NAME}" != "null" ]]; then
        _OUT_FILE_SECRET_LIBERTY="../export/secret-value-${CP4BA_INST_NAMESPACE}-${CP4BA_INST_CR_NAME}-${_BAW_NAME}-${__WRKFLW_AUTHOR_CFG_LIBERTY_XML_SECRET_NAME}.xml"
        echo "${_LIBERTY_XML_CONTENT}" > "${_OUT_FILE_SECRET_LIBERTY}"
        log_msg "${_CLR_GREEN}--Liberty xml content saved in '${_CLR_YELLOW}${_OUT_FILE_SECRET_LIBERTY}${_CLR_GREEN}'"
      else
        log_msg "${_CLR_GREEN}--Liberty secret not defined."
      fi

      if [[ ! -z "${__WRKFLW_AUTHOR_CFG_LOMBARDI_XML_SECRET_NAME}" && "${__WRKFLW_AUTHOR_CFG_LOMBARDI_XML_SECRET_NAME}" != "null" ]]; then
        _OUT_FILE_SECRET_LOMBARDI="../export/secret-value-${CP4BA_INST_NAMESPACE}-${CP4BA_INST_CR_NAME}-${_BAW_NAME}-${__WRKFLW_AUTHOR_CFG_LOMBARDI_XML_SECRET_NAME}.xml"
        echo "${_LOMBARDI_XML_CONTENT}" > "${_OUT_FILE_SECRET_LOMBARDI}"
        log_msg "${_CLR_GREEN}--Lombardi xml content saved in '${_CLR_YELLOW}${_OUT_FILE_SECRET_LOMBARDI}${_CLR_GREEN}'"
      else
        log_msg "${_CLR_GREEN}--Lombardi secret not defined."
      fi

    fi      

  fi
  log_msg
}
listBAWsRuntimes () {
  log_info "${_CLR_GREEN}List of BAW runtime names found in CR '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}'"
  log_msg
  _LIST_BAWS=$(echo ${_CP4BA_CR} | jq '.spec.baw_configuration[].name' | sed 's/"//g')

  for _BAW_NAME in ${_LIST_BAWS}
  do
    log_msg "${_CLR_GREEN}BAW name '${_CLR_YELLOW}${_BAW_NAME}${_CLR_GREEN}'"
    if [[ "${_SHOW_SECRET_NAMES}" = "true" ]]; then
      _LIBERTY_SECRET_NAME=$(echo ${_CP4BA_CR} | jq '.spec.baw_configuration[] | select(.name=="'${_BAW_NAME}'") | ."'${_LIBERTY_SECRET_ATTR_NAME}'"' | sed 's/"//g')
      _LOMBARDI_SECRET_NAME=$(echo ${_CP4BA_CR} | jq '.spec.baw_configuration[] | select(.name=="'${_BAW_NAME}'") | ."'${_LOMBARDI_SECRET_ATTR_NAME}'"' | sed 's/"//g')

      log_msg "${_CLR_GREEN}--Liberty secret name '${_CLR_YELLOW}${_LIBERTY_SECRET_NAME}${_CLR_GREEN}'"
      log_msg "${_CLR_GREEN}--Lombardi secret name '${_CLR_YELLOW}${_LOMBARDI_SECRET_NAME}${_CLR_GREEN}'"

    fi

    if [[ "${_DUMP_SECRET_VALUES}" = "true" ]]; then
      _LIBERTY_XML_CONTENT=""
      _LOMBARDI_XML_CONTENT=""

      if [[ ! -z "${_LIBERTY_SECRET_NAME}" && "${_LIBERTY_SECRET_NAME}" != "null" ]]; then
        _LIBERTY_XML_CONTENT=$(oc get secret -n ${CP4BA_INST_NAMESPACE} ${_LIBERTY_SECRET_NAME} -o jsonpath='{.data.sensitiveCustomConfig}' | base64 -d)
      fi

      if [[ ! -z "${_LOMBARDI_SECRET_NAME}" && "${_LOMBARDI_SECRET_NAME}" != "null" ]]; then
        _LOMBARDI_XML_CONTENT=$(oc get secret -n ${CP4BA_INST_NAMESPACE} ${_LOMBARDI_SECRET_NAME} -o jsonpath='{.data.sensitiveCustomConfig}' | base64 -d)
      fi

      log_msg "${_CLR_GREEN}--Liberty xml content:\n${_CLR_YELLOW}${_LIBERTY_XML_CONTENT}${_CLR_GREEN}"
      log_msg "${_CLR_GREEN}--Lombardi xml content:\n${_CLR_YELLOW}${_LOMBARDI_XML_CONTENT}${_CLR_GREEN}"

    fi

    if [[ "${_EXPORT_SECRET_VALUES}" = "true" ]]; then
      if [[ ! -z "${_LIBERTY_SECRET_NAME}" && "${_LIBERTY_SECRET_NAME}" != "null" ]]; then
        _OUT_FILE_SECRET_LIBERTY="../export/secret-value-${CP4BA_INST_NAMESPACE}-${CP4BA_INST_CR_NAME}-${_BAW_NAME}-${_LIBERTY_SECRET_NAME}.xml"
        echo "${_LIBERTY_XML_CONTENT}" > "${_OUT_FILE_SECRET_LIBERTY}"
        log_msg "${_CLR_GREEN}--Liberty xml content saved in '${_CLR_YELLOW}${_OUT_FILE_SECRET_LIBERTY}${_CLR_GREEN}'"
      else
        log_msg "${_CLR_GREEN}--Liberty secret not defined."
      fi

      if [[ ! -z "${_LOMBARDI_SECRET_NAME}" && "${_LOMBARDI_SECRET_NAME}" != "null" ]]; then
        _OUT_FILE_SECRET_LOMBARDI="../export/secret-value-${CP4BA_INST_NAMESPACE}-${CP4BA_INST_CR_NAME}-${_BAW_NAME}-${_LOMBARDI_SECRET_NAME}.xml"
        echo "${_LOMBARDI_XML_CONTENT}" > "${_OUT_FILE_SECRET_LOMBARDI}"
        log_msg "${_CLR_GREEN}--Lombardi xml content saved in '${_CLR_YELLOW}${_OUT_FILE_SECRET_LOMBARDI}${_CLR_GREEN}'"
      else
        log_msg "${_CLR_GREEN}--Lombardi secret not defined."
      fi

    fi      

  done
  log_msg

}

listBAWs () {
  _CP4BA_CR=$(oc get icp4acluster -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_CR_NAME} -o json)
  if [[ ! -z "${_CP4BA_CR}" && "${_CP4BA_CR}" != "null" ]]; then

    if [[ "${CP4BA_INST_TYPE}" = "starter" ]]; then
      listBAWsAuthoring
    else
      if [[ ${CP4BA_INST_OPT_COMPONENTS} == *"baw_authoring"* ]] || [[ ${CP4BA_INST_OPT_COMPONENTS} == *"wfps_authoring"* ]]; then
        listBAWsAuthoring
      else
        # BAW runtime
        listBAWsRuntimes
      fi
    fi

  fi
}

#------------------------
log_msg ""
log_msg "${_CLR_GREEN}======================================================================"
log_info "List of BAW servers in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"

trap 'onExit' EXIT

setTemporaryFolder

listBAWs
