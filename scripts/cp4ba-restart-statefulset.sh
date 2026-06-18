#!/bin/bash

#set -euo pipefail

_me=$(basename "$0")

_CFG=""
_TNS=""
_SRVNAME=""
_SRVTYPE=""
_WAIT="false"
_FORCE_DELETE="false"
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
while getopts c:n:s:t:wf flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        n) _TNS=${OPTARG};;
        s) _SRVNAME=${OPTARG};;
        t) _SRVTYPE=${OPTARG};;
        w) _WAIT="true";;
        f) _FORCE_DELETE="true";;
    esac
done

usage () {
  echo "usage: $_me -c path-of-config-file -s server-name -t server-type[baw|wfps] -n (optional)namespace -w (optional)wait-restart -f (optional)force-delete"
}

if [[ -z "${_CFG}" || -z "${_SRVNAME}" || -z "${_SRVTYPE}" ]]; then
  usage
  exit 1
fi

source "${_CFG}" 2>/dev/null

if [[ -z "${_TNS}" ]]; then
  _TNS="${CP4BA_INST_NAMESPACE}"
  if [[ -z "${_TNS}" ]]; then
    log_error "Namespace not found in properties file nor set in command line"
    usage
    exit 1
  fi
fi

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

resourceExist () {
# namespace name: $1
# resource type: $2
# resource name: $3
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 | wc -l) -lt 1 ]; then
      return 0
  fi
  return 1
}

# CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-runtime-baw-bai.properties
# ./baw-restart-statefulset.sh -c $CONFIG_FILE

# oc get statefulsets -n "$_NS" ${CP4BA_INST_CR_NAME}-${CP4BA_INST_BAW_1_NAME}-baw-server

restartForce () {
  _NS="$1"
  _SFS_NAME="$2"
  _ORIG_REPLICAS="$3"

  log_info "Statefulset '${_SFS_NAME}' replicas '$_ORIG_REPLICAS', deleting pods in forced mode"
  oc get pods -n "$_NS" | grep ${CP4BA_INST_CR_NAME}-${CP4BA_INST_BAW_1_NAME}-baw-server | awk '{print $1}' | xargs oc delete pod --force -n "$_NS" 2>/dev/null 1>/dev/null

  if [[ "${_WAIT}" = "true" ]]; then
    sleep 10
    _active_pods=0
    _counter=0
    while [ $_active_pods -lt $_ORIG_REPLICAS ]; do
      _active_pods=$(oc get pods -n ${_NS} | grep ${_SFS_NAME} | grep Running | wc -l)
      echo -e -n "Waiting for new pods to reach Running status [$_active_pods/$_ORIG_REPLICAS]\033[0K\r"
      sleep 5
      _counter=$((_counter + 1))
      if [[ $_counter -gt 300 ]]; then
        log_msg ""
        log_warning "Wait timeout reached, not all pods are running for statefulset '${_CLR_YELLOW}${_SFS_NAME}${_CLR_GREEN}'"
        oc get pods -n ${_NS} | grep ${_SFS_NAME}
        break
      fi
    done
    log_msg ""
    log_info "Now '${_active_pods}' new pods are running for statefulset '${_CLR_YELLOW}${_SFS_NAME}${_CLR_GREEN}'"
  else
    log_info "Running in no wait mode"
    oc get pods -n ${_NS} | grep ${_SFS_NAME}
  fi

}

deletePodAndWaitRunningReady () {
  _NS="$1"
  _POD_NAME="$2"

  log_info "Gracefully restart pod '${_CLR_YELLOW}${_POD_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${_NS}${_CLR_GREEN}'"

  oc delete pod -n "$_NS" "${_POD_NAME}" 2>/dev/null 1>/dev/null
  sleep 3
  _active_pods=0
  _counter=0
  _CONDITION_MET=0
  while [ $_CONDITION_MET -lt 1 ]; do
    _CONDITION_MET=$(oc wait --for=condition=Ready -n $_NS pod/${_POD_NAME} --timeout=300s | grep "condition met" | wc -l)
    sleep 5
    _counter=$((_counter + 1))
    if [[ $_counter -gt 300 ]]; then
      log_warning "Wait timeout reached, pod '${_CLR_YELLOW}${_POD_NAME}${_CLR_GREEN}' not ready for statefulset '${_CLR_YELLOW}${_SFS_NAME}${_CLR_GREEN}'"
      oc get pod -n ${_NS} "${_POD_NAME}"
      break
    fi
  done
}

restartGraceful () {
  _NS="$1"
  _SFS_NAME="$2"
  _ORIG_REPLICAS="$3"

  log_info "Statefulset '${_CLR_YELLOW}${_SFS_NAME}${_CLR_GREEN}' replicas '${_CLR_YELLOW}$_ORIG_REPLICAS${_CLR_GREEN}', deleting pods in graceful mode"

  LIST_OF_PODS=$(oc get pods -n "$_NS" | grep ${_SFS_NAME} | awk '{print $1}')
  echo "$LIST_OF_PODS" | while IFS= read -r pod_name ; do deletePodAndWaitRunningReady "${_NS}" "${pod_name}"; done
}

restartStatefulset () {
  _NS="$1"
  _SFS_NAME="$2"

  resourceExist ${_NS} "statefulset" ${_SFS_NAME}
  if [ $? -eq 1 ]; then

    _ORIG_REPLICAS=$(oc get statefulset -n ${_NS} ${_SFS_NAME} -o jsonpath='{.spec.replicas}')

    if [[ "${_FORCE_DELETE}" = "true" ]]; then
      restartForce "${_NS}" "${_SFS_NAME}" "${_ORIG_REPLICAS}"
    else
      restartGraceful "${_NS}" "${_SFS_NAME}" "${_ORIG_REPLICAS}"
    fi
  else
    log_error "Unknown statefulset '${_SFS_NAME}' in namespace '${_NS}'"
    exit 1
  fi

}


log_msg "==============================================================${_CLR_NC}"

if [[ "${_SRVTYPE}" = "baw" ]]; then
  if [[ ${CP4BA_INST_OPT_COMPONENTS} == *"baw_authoring"* ]] || [[ ${CP4BA_INST_OPT_COMPONENTS} == *"wfps_authoring"* ]]; then
    _SRVNAME="bastudio"
    _SRV_SUFFIX="deployment"
  else
    _SRV_SUFFIX="baw-server"
  fi

  _SFS_NAME="${CP4BA_INST_CR_NAME}-${_SRVNAME}-${_SRV_SUFFIX}"
  log_info "${_CLR_GREEN}Restarting pods for BAW statefulset '${_CLR_YELLOW}${_SFS_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${_TNS}${_CLR_GREEN}'${_CLR_NC}"
  restartStatefulset "${_TNS}" "${_SFS_NAME}" "${_SRVTYPE}"
else
  if [[ "${_SRVTYPE}" = "wfps" ]]; then
    _SRV_SUFFIX="wfps-runtime-server"
    _SFS_NAME="${_SRVNAME}-${_SRV_SUFFIX}"
    log_info "${_CLR_GREEN}Restarting pods for WFPS statefulset '${_CLR_YELLOW}${_SFS_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${_TNS}${_CLR_GREEN}'${_CLR_NC}"
    restartStatefulset "${_TNS}" "${_SFS_NAME}" "${_SRVTYPE}"
  else
    log_error "Unknown server type '${_SRVTYPE}', must be one of [baw | wfps]"
    exit 1
  fi
fi
exit 0

