#!/bin/bash
mkdir /secret
chmod 600 /secret
htpasswd -c -B -b /secret/users.htpasswd ocpadmin P@ssw0rd
htpasswd -B -b /secret/users.htpasswd developer P@ssw0rd
oc create secret generic htpass-secret --from-file=htpasswd=/secret/users.htpasswd -n openshift-config 
oc apply -f htpasswd_provider.yaml
