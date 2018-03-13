#!/bin/bash

# -----------------------------------------------------------------
# This script sets environment variables that are used by Google
# Cloud Platform (GCP) dynamic inventory and Ansible.
#
#    !!!!!!  It should be SOURCED  !!!!!
#         $>source ./gcp-init.sh     
#      or $>. ./gcp-init.sh
# -----------------------------------------------------------------

# This file hold a list of available projects from which the 
# selection list is populated.
PROJECTS_FILE=gcp-projects.txt

# Remove all variables known to this script
function unset_all_variables {
  unset GCE_PROJECT
  unset GCE_PEM_FILE_PATH
  unset GCE_EMAIL
  #unset ANSIBLE_HOSTS
  unset ANSIBLE_HOST_KEY_CHECKING
  #unset ANSIBLE_NOCOWS
  unset GCP_REGION
  unset GCP_ZONE
  unset INVENTORY_IP_TYPE
  unset CW_GCP_REGION
  unset CW_GCP_DEFAULT_ZONE
  unset CW_GCE_SERVICE_PROJECT
  unset CW_GCE_SHAREDVPC_NETWORK
  unset CW_GCE_SHAREDVPC_HOST_PROJECT

  unset PROJECT
}

# Present a list of projects or selection.
# Returns:
#     255 & $PROJECT="" : when the user presses Esc
#       0 & $PROJECT="" : when the user presses Cancel
#       0 & $PROJECT="<value>" : when OK is pressed.  If no project was select <value> = ""
function choose_project {

  LIST=
  while read -r line ; do
    if [[ ! $line =~ ^# ]] ; then
      if [ -z $LIST ] ; then
        LIST="${line}"
      else
        LIST="${LIST} ${line}"
      fi
    fi
  done < $PROJECTS_FILE

  local RESULT=$(dialog --stdout --radiolist 'SELECT A PROJECT\n[Space=mark] [Enter=done] [Esc=cancel]' 0 44 10 $LIST)
  clear

  local EXIT_CODE="$?"

  PROJECT=$RESULT
  return $EXIT_CODE
}

# ===================================
# ------------  main    -------------
# ===================================

# See https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
  echo "This script must be sourced!  Aborting ..."
  exit 1
fi

if [ ! -e "$PROJECTS_FILE" ] ; then
  echo "Aborting as the projects list file '$PROJECTS_FILE' does not exist!"
  return 1
fi

unset_all_variables

# Prompt for a project if not given one of the command-line
if [ -z "$1" ] ; then
  if ! choose_project || [ -z $PROJECT ] ; then
    echo "*** No project chosen; clearing environment variables and exiting ***"
    return
  else
    echo "*** Selected project: $PROJECT.  Now setting GCP environment variables ... ***"
  fi
else
  PROJECT="$1"
fi

export GCE_PROJECT="$PROJECT"

export GCE_PEM_FILE_PATH=~/.gce/$GCE_PROJECT\.json
export GCE_EMAIL=$(grep client_email $GCE_PEM_FILE_PATH | sed -e 's/  "client_email": "//g' -e 's/",//g')
gcloud config set project $GCE_PROJECT

# Use this if ansible_hosts is in a non-standard location
#export ANSIBLE_HOSTS=ansible_hosts

export ANSIBLE_HOST_KEY_CHECKING=False

# Hide the cows
#export ANSIBLE_NOCOWS=1

# Default regionn & zone
export GCP_REGION="europe-west2"
export GCP_ZONE="${GCP_REGION}-a"

# Tell Ansbile to user internal rather than external GCE IP addresses
export INVENTORY_IP_TYPE="internal"
#export INVENTORY_IP_TYPE="external"

# These variables are used by the Ansible Playbooks to set variables
# via lookup('env', 'ENV_VAR')
export CW_GCP_REGION="$GCP_REGION"
export CW_GCP_DEFAULT_ZONE="$GCP_ZONE"
export CW_GCE_SERVICE_PROJECT="$GCE_PROJECT"
export CW_GCE_SHAREDVPC_NETWORK="cwvpc"
export CW_GCE_SHAREDVPC_HOST_PROJECT="cowatch-177510"
