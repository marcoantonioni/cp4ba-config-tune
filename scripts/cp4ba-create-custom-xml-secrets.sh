#!/bin/bash

#set -euo pipefail

_me=$(basename "$0")

_CFG=""
_PATCH_CR="false"
_SRV_NAME=""
_SRVTYPE=""
WFPS_CR_NAME=""
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
while getopts c:s:t:w:p flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        p) _PATCH_CR="true";;    
        s) _SRV_NAME=${OPTARG};;
        t) _SRVTYPE=${OPTARG};;
        w) WFPS_CR_NAME=${OPTARG};;
    esac
done

usage () {
  echo "usage: $_me
    -c path-of-config-file
    -p (optional)patch-cr
    -t (requested if -p)server-type[baw|wfps]
    -s (requested if -p and -t baw)baw-server-name
    -w (requested if -p and -t wfps)wfps-cr-name"
}

if [[ -z "${_CFG}" ]]; then
  usage
  exit 1
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

if [[ "${_PATCH_CR}" = "true" ]]; then
  if [[ -z "${_SRVTYPE}" ]]; then
    log_error "Empty server type"
    usage
    exit 1
  fi
  if [[ "${_SRVTYPE}" = "baw" && -z "${_SRV_NAME}" ]]; then
    log_error "Empty server name for BAW"
    usage
    exit 1
  fi
  if [[ "${_SRVTYPE}" = "wfps" && -z "${WFPS_CR_NAME}" ]]; then
    log_error "Empty CR name for WFPS"
    usage
    exit 1
  fi
fi

resourceExist () {
# namespace name: $1
# resource type: $2
# resource name: $3
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 | wc -l) -lt 1 ]; then
      return 0
  fi
  return 1
}

namespaceExist () {
# ns name: $1
  if [ $(oc get ns $1 2>/dev/null | grep $1 2>/dev/null | wc -l 2>/dev/null ) -lt 1 ];
  then
      return 0
  fi
  return 1
}

searchBAWIndex () {
  _KEY_NAME="$1"
  _KEY_FOUND=-1
  i=1
  _MAX_BAW=10
  while [[ $i -le $_MAX_BAW ]]
  do
    __BAW_INST="CP4BA_INST_BAW_${i}"
    __BAW_NAME="CP4BA_INST_BAW_${i}_NAME"

    _INST="${!__BAW_INST}"
    _NAME="${!__BAW_NAME}"

    if [[ "${_INST}" = "true" ]] && [[ "${_NAME}" = "${_KEY_NAME}" ]]; then
      _KEY_FOUND=$i
      break
    fi
    ((i=i+1))
  done
  return $_KEY_FOUND
}

searchWFPSIndex () {
  _KEY_NAME="$1"
  _KEY_FOUND=-1
  i=1
  _MAX_WFPS=10
  while [[ $i -le $_MAX_WFPS ]]
  do
    __BAW_NAME="CP4BA_INST_CUSTOM_XML_WFPS_CR_NAME_${i}"
    _NAME="${!__BAW_NAME}"

    if [[ "${_NAME}" = "${_KEY_NAME}" ]]; then
      _KEY_FOUND=$i
      break
    fi
    ((i=i+1))
  done
  return $_KEY_FOUND
}

_createCustomXMLSecret () {
  _SEC_NAME="$1"
  _SEC_TEMPLATE="$2"
  _SEC_FULLPATH="$3"
  _SEC_AREA="$4"
  
  _SECRET_FILE_NAME="${_INST_TMP_FOLDER}/secret-baw-runtime-$USER-$RANDOM.xml"

  log_info "${_CLR_GREEN}Using '${_CLR_YELLOW}${_SEC_AREA}${_CLR_GREEN}' xml template '${_CLR_YELLOW}${_SEC_TEMPLATE}${_CLR_GREEN}' for secret '${_CLR_YELLOW}${_SEC_NAME}${_CLR_GREEN}'"
  envsubst < ${_FULL_PATH} > ${_SECRET_FILE_NAME}
  if [[ $? -ne 0 ]]; then
    log_warning "[✗] Warning, custom ${_SEC_AREA} xml file '${_SECRET_FILE_NAME}' not generated.${_CLR_NC}"
  fi

  log_debug "Secret '${_CLR_YELLOW}${_SEC_NAME}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SEC_NAME} 2> /dev/null 1> /dev/null
  oc create secret generic -n ${CP4BA_INST_NAMESPACE} ${_SEC_NAME} --from-file=sensitiveCustomConfig=${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret '${_CLR_YELLOW}${_SEC_NAME}${_CLR_RED}' NOT created !!!${_CLR_NC}"
  fi

  rm ${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null

}

createLibertyXMLSecrets () {

  #---------------------------------------------
  # custom DB for applications (variables may be used in template files)
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

    if [[ ${CP4BA_INST_OPT_COMPONENTS} == *"baw_authoring"* ]] || [[ ${CP4BA_INST_OPT_COMPONENTS} == *"wfps_authoring"* ]]; then
      _createCustomXMLSecret "${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME}" "${CP4BA_INST_LIBERTY_CUSTOM_XML_TEMPLATE_NAME}" "${_FULL_PATH}" "Liberty"
    else
      _LIB_SEC_NAME=""
      _LIB_TEMPL_NAME=""
      __LIB_SEC_NAME=""
      __LIB_TEMPL_NAME=""

      _KEY_FOUND=-1
      if [[ "${_SRVTYPE}" = "baw" ]]; then
        searchBAWIndex "${_SRV_NAME}"
        _KEY_FOUND=$?
        if [[ $_KEY_FOUND -eq -1 ]]; then
          log_error "BAW server name '${_SRV_NAME}' not found for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"
          exit 1
        fi
        __LIB_SEC_NAME="CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME_BAW_${_KEY_FOUND}"
        __LIB_TEMPL_NAME="CP4BA_INST_LIBERTY_CUSTOM_XML_TEMPLATE_NAME_BAW_${_KEY_FOUND}"
      else
        searchWFPSIndex "${WFPS_CR_NAME}"
        _KEY_FOUND=$?
        if [[ $_KEY_FOUND -eq -1 ]]; then
          log_error "WFPS server name '${WFPS_CR_NAME}' not found for WfPSRuntime '${_CLR_YELLOW}${WFPS_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"
          exit 1
        fi
        __LIB_SEC_NAME="CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME_WFPS_${_KEY_FOUND}"
        __LIB_TEMPL_NAME="CP4BA_INST_LIBERTY_CUSTOM_XML_TEMPLATE_NAME_WFPS_${_KEY_FOUND}"
      fi

      _LIB_SEC_NAME="${!__LIB_SEC_NAME}"
      _LIB_TEMPL_NAME="${!__LIB_TEMPL_NAME}"
      
      if [[ -z "${_LIB_SEC_NAME}" || -z "${_LIB_TEMPL_NAME}" ]]; then
        if [[ "${_SRVTYPE}" = "baw"  ]]; then
          _svt="${_SRV_NAME}"
        else
          _svt="${WFPS_CR_NAME}"
        fi
        log_error "Secret values not defined for server [${_SRVTYPE}/$_svt] secret name[${_LIB_SEC_NAME}] template name[${_LIB_TEMPL_NAME}]"
        exit 1
      fi

      _createCustomXMLSecret "${_LIB_SEC_NAME}" "${_LIB_TEMPL_NAME}" "${_FULL_PATH}" "Liberty"
    fi 
  else
    log_error "File not found '${_FULL_PATH}'"
    export CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME="null"
  fi 


}

createLombardiXMLSecrets () {

  _FULL_PATH="${_SCRIPT_DIR}/../${CP4BA_INST_CUSTOM_XML_FOLDER_NAME}/${CP4BA_INST_LOMBARDI_CUSTOM_XML_TEMPLATE_NAME}"
  if [[ -f "${_FULL_PATH}" ]]; then

    #---------------------------------------------
    # dynamic values, use following vars in your template
    export _AGENT_FQDN_BASE=$(oc cluster-info | sed 's/.*https:\/\/api.//g' | sed 's/:.*//g' | head -n1)
    export _AGENT_FQDN_FULL="https://${CP4BA_INST_CPD_CONSOLE_PREFIX}.${_AGENT_FQDN_BASE}"

    if [[ ${CP4BA_INST_OPT_COMPONENTS} == *"baw_authoring"* ]] || [[ ${CP4BA_INST_OPT_COMPONENTS} == *"wfps_authoring"* ]]; then
      _createCustomXMLSecret "${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME}" "${CP4BA_INST_LOMBARDI_CUSTOM_XML_TEMPLATE_NAME}" "${_FULL_PATH}" "Lombardi"
    else
      _LOM_SEC_NAME=""
      _LOM_TEMPL_NAME=""
      __LOM_SEC_NAME=""
      __LOM_TEMPL_NAME=""

      _KEY_FOUND=-1
      if [[ "${_SRVTYPE}" = "baw" ]]; then
        searchBAWIndex "${_SRV_NAME}"
        _KEY_FOUND=$?
        if [[ $_KEY_FOUND -eq -1 ]]; then
          log_error "BAW server name '${_SRV_NAME}' not found for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"
          exit 1
        fi

        __LOM_SEC_NAME="CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME_BAW_${_KEY_FOUND}"
        __LOM_TEMPL_NAME="CP4BA_INST_LOMBARDI_CUSTOM_XML_TEMPLATE_NAME_BAW_${_KEY_FOUND}"

      else
        searchWFPSIndex "${WFPS_CR_NAME}"
        _KEY_FOUND=$?
        if [[ $_KEY_FOUND -eq -1 ]]; then
          log_error "WFPS server name '${WFPS_CR_NAME}' not found for WfPSRuntime '${_CLR_YELLOW}${WFPS_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"
          exit 1
        fi
        __LOM_SEC_NAME="CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME_WFPS_${_KEY_FOUND}"
        __LOM_TEMPL_NAME="CP4BA_INST_LOMBARDI_CUSTOM_XML_TEMPLATE_NAME_WFPS_${_KEY_FOUND}"
      fi
      _LOM_SEC_NAME="${!__LOM_SEC_NAME}"
      _LOM_TEMPL_NAME="${!__LOM_TEMPL_NAME}"

      if [[ -z "${_LIB_SEC_NAME}" || -z "${_LIB_TEMPL_NAME}" ]]; then
        log_error "Secret values not defined at offset [$_KEY_FOUND] for server type [${_SRVTYPE}] secret name[${_LIB_SEC_NAME}] template name[${_LIB_TEMPL_NAME}]"
        exit 1
      fi

      _createCustomXMLSecret "${_LOM_SEC_NAME}" "${_LOM_TEMPL_NAME}" "${_FULL_PATH}" "Lombardi"

    fi 

  else
    log_error "File not found '${_FULL_PATH}'"
    export CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME="null"
  fi
}

createWxSecret () {

  if [[ "${CP4BA_INST_GENAI_ENABLED}" = "true" ]]; then

    if [[ ! -z "${CP4BA_INST_GENAI_WX_AUTH_SECRET}" && ! -z "${CP4BA_INST_GENAI_WX_USERID}" && ! -z "${CP4BA_INST_GENAI_WX_APIKEY}" ]]; then

      oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_GENAI_WX_AUTH_SECRET} 2>/dev/null 1>/dev/null

      _WX_GENAI_TMP="${_INST_TMP_FOLDER}/cp4ba-wx-genai-$USER-$RANDOM"

      echo '<server>' > ${_WX_GENAI_TMP}
      echo '  <authData id="watsonx.ai_auth_alias" user="'${CP4BA_INST_GENAI_WX_USERID}'" password="'${CP4BA_INST_GENAI_WX_APIKEY}'"/>' >> ${_WX_GENAI_TMP}
      echo '</server>' >> ${_WX_GENAI_TMP}

      log_debug "Secret '${_CLR_YELLOW}${CP4BA_INST_GENAI_WX_AUTH_SECRET}${_CLR_NC}'"
      oc create secret generic -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_GENAI_WX_AUTH_SECRET} --from-file=sensitiveCustom.xml=${_WX_GENAI_TMP} 2>/dev/null 1>/dev/null

      rm ${_WX_GENAI_TMP} 2>/dev/null 1>/dev/null
    else
      log_error "Cannot create watsonx secret, check GenAI parameters in config file '${_CFG}'"
    fi
  fi
}


createCustomXMLSecrets () {

  namespaceExist "${CP4BA_INST_NAMESPACE}"
  if [[ $? -eq 0 ]]; then
    log_error "Namespace '${CP4BA_INST_NAMESPACE}' doesn't exists."
    exit 1
  fi

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

  if [[ -z "${_SRV_NAME}" ]]; then
    log_info "${_CLR_GREEN}Configuring authoring server for custom xml secrets"
  else
    log_info "${_CLR_GREEN}Configuring server '${_CLR_YELLOW}${_NAME}${_CLR_GREEN}' for custom xml secrets"
  fi
  
  log_info "${_CLR_GREEN}Using folder '${_CLR_YELLOW}${CP4BA_INST_CUSTOM_XML_FOLDER_NAME}${_CLR_GREEN}'"

  if [[ ! -z "${CP4BA_INST_LIBERTY_CUSTOM_XML_TEMPLATE_NAME}" ]]; then
    createLibertyXMLSecrets
  fi
  
  if [[ ! -z "${CP4BA_INST_LOMBARDI_CUSTOM_XML_TEMPLATE_NAME}" ]]; then
    createLombardiXMLSecrets
  fi
}

patchCRBAW () {
  searchBAWIndex "${_SRV_NAME}"
  _KEY_FOUND=$?

  if [[ $_KEY_FOUND -eq -1 ]]; then
    log_error "BAW server name '${_SRV_NAME}' not found for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"
    exit 1
  fi

  if [[ ${CP4BA_INST_OPT_COMPONENTS} == *"baw_authoring"* ]] || [[ ${CP4BA_INST_OPT_COMPONENTS} == *"wfps_authoring"* ]]; then
    log_info "${_CLR_GREEN}Patching authoring ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"

    oc patch ICP4ACluster ${CP4BA_INST_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type=json -p '[{ "op": "replace", "path": "/spec/workflow_authoring_configuration/custom_xml_secret_name", "value": '${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME}' }]' 2>/dev/null 1>/dev/null

    oc patch ICP4ACluster ${CP4BA_INST_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type=json -p '[{ "op": "replace", "path": "/spec/workflow_authoring_configuration/lombardi_custom_xml_secret_name", "value": '${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME}' }]' 2>/dev/null 1>/dev/null

  else

    log_info "${_CLR_GREEN}Patching runtime server '${_CLR_YELLOW}${_SRV_NAME}${_CLR_GREEN}' for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"

    if [[ ! -z "${_SRV_NAME}" ]]; then
      INDEX=$(oc get ICP4ACluster ${CP4BA_INST_CR_NAME} -n ${CP4BA_INST_NAMESPACE} -o json | \
        jq '.spec.baw_configuration | to_entries[] | select(.value.name == "'${_SRV_NAME}'") | .key')

      if [[ ! -z "${INDEX}" ]]; then
        oc patch ICP4ACluster ${CP4BA_INST_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type='json' -p "[
          {
            \"op\": \"replace\",
            \"path\": \"/spec/baw_configuration/${INDEX}/custom_xml_secret_name\",
            \"value\": \"${_LIB_SEC_NAME}\"
          }
        ]" 2>/dev/null 1>/dev/null
        oc patch ICP4ACluster ${CP4BA_INST_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type='json' -p "[
          {
            \"op\": \"replace\",
            \"path\": \"/spec/baw_configuration/${INDEX}/lombardi_custom_xml_secret_name\",
            \"value\": \"${_LOM_SEC_NAME}\"
          }
        ]" 2>/dev/null 1>/dev/null
      else
        log_error "Server name '${_SRV_NAME}' not found."
      fi
    fi

  fi

}

patchCRWFPS () {
  if [[ ${CP4BA_INST_OPT_COMPONENTS} == *"baw_authoring"* ]] || [[ ${CP4BA_INST_OPT_COMPONENTS} == *"wfps_authoring"* ]]; then
    log_info "${_CLR_GREEN}Patching authoring ICP4ACluster (WFPS flavor) '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"

    resourceExist "${CP4BA_INST_NAMESPACE}" "ICP4ACluster" "${CP4BA_INST_CR_NAME}"
    if [ $? -eq 1 ]; then
      oc patch ICP4ACluster ${CP4BA_INST_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type=json -p '[{ "op": "replace", "path": "/spec/bastudio_configuration/custom_secret_name", "value": '${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME}' }]' 2>/dev/null 1>/dev/null
    else
      log_error "ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' does not exists !"
      exit 1
    fi
  else
    log_info "${_CLR_GREEN}Patching runtime WfPSRuntime '${_CLR_YELLOW}${WFPS_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'"

    resourceExist "${CP4BA_INST_NAMESPACE}" "WfPSRuntime" "${WFPS_CR_NAME}"
    if [ $? -eq 1 ]; then

      _CUSTOMIZE_PRESENT=$(oc get WfPSRuntime ${WFPS_CR_NAME} -n ${CP4BA_INST_NAMESPACE} -o jsonpath='{.spec.node.customize}')
      if [[ -z "${_CUSTOMIZE_PRESENT}" ]]; then
        # add 'customize' object
        oc patch WfPSRuntime ${WFPS_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type=json -p '[{ "op": "replace", "path": "/spec/node/customize", "value": '{}' }]' 2>/dev/null 1>/dev/null
      fi

      oc patch WfPSRuntime ${WFPS_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type=json -p '[{ "op": "replace", "path": "/spec/node/customize/libertyXMLSecret", "value": '${CP4BA_INST_LIBERTY_CUSTOM_XML_SECRET_NAME}' }]' 2>/dev/null 1>/dev/null

      oc patch WfPSRuntime ${WFPS_CR_NAME} -n ${CP4BA_INST_NAMESPACE} --type=json -p '[{ "op": "replace", "path": "/spec/node/customize/lombardiXMLSecret", "value": '${CP4BA_INST_LOMBARDI_CUSTOM_XML_SECRET_NAME}' }]' 2>/dev/null 1>/dev/null
    else
      log_error "WfPSRuntime '${_CLR_YELLOW}${WFPS_CR_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' does not exists !"
      exit 1
    fi

  fi
}

log_msg "=============================================================="
log_info "${_CLR_GREEN}Creating custom xml secrets in '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"

setTemporaryFolder

createCustomXMLSecrets
if [[ "${_PATCH_CR}" = "true" ]]; then
  if [[ "${_SRVTYPE}" = "baw" ]]; then
    patchCRBAW
  else
    if [[ "${_SRVTYPE}" = "wfps" ]]; then
      patchCRWFPS
    else
      log_error "Unknown server type '${_SRVTYPE}', must be one of [baw | wfps]"
      exit 1
    fi
  fi
fi
exit 0
