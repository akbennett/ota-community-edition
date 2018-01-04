#!/usr/bin/env bash

set -uex

export SERVERNAME=${SERVERNAME:-ota.ce}
export DEVICE_ID=${1}
readonly KUBE_IP=$(minikube ip)
export DEVICE_UUID=$(uuidgen)
readonly REGISTRY_HOST=$(kubectl get ingress -o jsonpath --template='{.items[?(@.metadata.name=="device-registry")].spec.rules[0].host}')
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../${SERVERNAME}/devices/${DEVICE_ID}
mkdir -p ${DIR}

openssl ecparam -genkey -name prime256v1 | openssl ec -out ${DIR}/${DEVICE_ID}.key
openssl req -new -config client.cnf -key ${DIR}/${DEVICE_ID}.key -out ${DIR}/${DEVICE_ID}.csr
openssl x509 -req -days 365 -extfile client.ext -in ${DIR}/${DEVICE_ID}.csr -CAkey ${DIR}/ca.key -CA ${DIR}/ca.crt -CAcreateserial -out ${DIR}/${DEVICE_ID}.crt
cat ${DIR}/${DEVICE_ID}.crt ${DIR}/${DEVICE_ID}.crt > ${DIR}/${DEVICE_ID}.chain.pem

openssl x509 -in ${DIR}/${DEVICE_ID}.crt -text -noout

http PUT http://${KUBE_IP}/api/v1/devices "Host:${REGISTRY_HOST}" deviceUuid="${DEVICE_UUID}" deviceId=${DEVICE_ID} deviceName=${DEVICE_ID} deviceType=Other credentials=@${DIR}/${DEVICE_ID}.crt
