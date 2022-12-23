#!/usr/bin/env bash

########################################################################################################################
# DISCLAIMER:
# This script was used during the migration from the legacy Vault instance to the new one, launched inside Kubernetes.
# Was coded by Mehdi Ahmadi to make our life easier
# Ref: https://support.hashicorp.com/hc/en-us/articles/4411124879891-Migrating-KV-Secrets
# Script uses several CLI tools: jq, curl and vault
########################################################################################################################

# Vault 1 address & KV path
V1_ADDR='https://vault.example.com';
V1_TOKEN='s.xxxEXAMPLExxx';
V1_KV='secret/';

# Vault 2 address & KV path
V2_ADDR='https://vault.new.example.com';
V2_TOKEN='s.xxxEXAMPLExxx';
V2_KV='kubernetes/';

########################################################################################################################
export VAULT_TOKEN=${V1_TOKEN} && export VAULT_ADDR=${V1_ADDR} ;
# ^^ for convenience with Vault CLI and V2 values for API / curl

# check KV version 1 or 2 for source & destination so as to append 'data/' to path.
V2_KV_VER=$(VAULT_ADDR=${V2_ADDR} VAULT_TOKEN=${V2_TOKEN} \
  vault secrets list -format=json | jq -r ".[\"${V2_KV}\"]|.options.version") ;
if [[ ${V2_KV_VER} == "2" ]] ; then V2_KV+="data/" ; fi ;

function kv_recurse()
{
  local V1_KV_LIST_SUB=() ;
  V1_KV_LIST_SUB=($(vault kv list -format=json ${V1_KV}/$1 | jq -r '.[]')) ;
  for sY in ${V1_KV_LIST_SUB[*]} ; do
    if [[ ${sY} == *'/' ]] ; then kv_recurse $1${sY} ;
    else
      # read data
      KV_DATA=$(vault kv get -format=json ${V1_KV}$1${sY} | jq '.data') ;

      # strip or add 'data' object subject to kv1 or kv2
      if [[ ${V2_KV_VER} == "2" && "$(echo ${KV_DATA} | jq '.data')" == "null" ]] ; then
        KV_DATA="{\"data\": ${KV_DATA}}" ;
      fi ;
      if [[ ${V2_KV_VER} == "1" && ! "$(echo ${KV_DATA} | jq '.data')" == "null" ]] ; then
        KV_DATA=$(echo ${KV_DATA} | jq '.data') ;
      fi ;

      # re-write to new Vault / KV engine
      sRESP=$(curl -k -L -X POST -H "X-Vault-Token: ${V2_TOKEN}" -d "${KV_DATA}" \
        -o /dev/null -s -w "%{http_code}\n" ${V2_ADDR}/v1/${V2_KV}$1${sY}) ;
      if ! [[ ${sRESP} == "200" || ${sRESP} == "204" ]]; then
        printf "ERROR: copying: ${V1_KV}$1${sY} to ${V2_ADDR}/v1/${V2_KV}$1${sY}\n" ;
      fi ;
    fi ;
  done ;
}

# first list all keys on root of KV path & recurse through them.
V1_KV_LIST=($(vault kv list -format=json ${V1_KV} | jq -r '.[]')) ;
for sX in ${V1_KV_LIST[*]} ; do
  if [[ ${sX} == *'/' ]] ; then kv_recurse $sX ;
  else
    # read data
    KV_DATA=$(vault kv get -format=json ${V1_KV}${sX} | jq '.data') ;

    # strip or add 'data' object subject to kv1 or kv2
    if [[ ${V2_KV_VER} == "2" && "$(echo ${KV_DATA} | jq '.data')" == "null" ]] ; then
      KV_DATA="{\"data\": ${KV_DATA}}" ;
    fi;
    if [[ ${V2_KV_VER} == "1" && ! "$(echo ${KV_DATA} | jq '.data')" == "null" ]] ; then
      KV_DATA=$(echo ${KV_DATA} | jq '.data') ;
    fi;

    # re-write to new Vault / KV engine
    sRESP=$(curl -k -L -X POST -H "X-Vault-Token: ${V2_TOKEN}" -d "${KV_DATA}" -o \
      /dev/null -s -w "%{http_code}\n" ${V2_ADDR}/v1/${V2_KV}${sX}) ;
    if ! [[ ${sRESP} == "200" || ${sRESP} == "204" ]] ; then
      printf "ERROR: copying: ${V1_KV}${sX} to ${V2_ADDR}/v1/${V2_KV}${sX}\n";
    fi;
  fi;
done;
