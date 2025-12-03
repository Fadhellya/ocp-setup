#!/bin/bash

# Proxy untuk curl (ubah sesuai environment)
proxy="http://10.210.9.250:8080"

# Output CSV
output_file="ocp_proxy_preinstall_check.csv"

# Whitelist Domain + Port (sesuai daftar yang kamu beri)
declare -a domains_ports=(
 "registry.redhat.io 443"
 "access.redhat.com 443"
 "registry.access.redhat.com 443"
 "quay.io 443"
 "cdn.quay.io 443"
 "cdn01.quay.io 443"
 "cdn02.quay.io 443"
 "cdn03.quay.io 443"
 "cdn04.quay.io 443"
 "cdn05.quay.io 443"
 "cdn06.quay.io 443"
 "sso.redhat.com 443"
 "cert-api.access.redhat.com 443"
 "api.access.redhat.com 443"
 "infogw.api.openshift.com 443"
 "console.redhat.com 443"
 "mirror.openshift.com 443"
 "storage.googleapis.com/openshift-release 443"
 "*.apps.ove.corp.mandirisekuritas.co.id 443"
 "api.openshift.com 443"
 "rhcos.mirror.openshift.com 443"
 "quayio-production-s3.s3.amazonaws.com 443"
 "registry.connect.redhat.com 443"
 "rhc4tp-prod-z8cxf-image-registry-us-east-1-evenkyleffocxqvofrk.s3.dualstack.us-east-1.amazonaws.com 443"
 "oso-rhc4tp-docker-registry.s3-us-west-2.amazonaws.com 443"
 "subscription.rhn.redhat.com 443"
 "subscription.rhsm.redhat.com 443"
 "cdn.redhat.com 443"
 "*.akamaiedge.net 443"
 "*.akamaitechnologies.com 443"
 "api.segment.io 443"
 "cdn.segment.com 443"
 "notify.bugsnag.com 443"
 "sessions.bugsnag.com 443"
 "auth.docker.io 443"
 "cdn.auth0.com 443"
 "login.docker.com 443"
 "auth.docker.com 443"
 "desktop.docker.com 443"
 "hub.docker.com 443"
 "registry-1.docker.io 443"
 "production.cloudflare.docker.com 443"
 "docker-images-prod.6aa30f8b08e16409b46e0173d6de2f56.r2.cloudflarestorage.com 443"
 "docker-pinata-support.s3.amazonaws.com 443"
 "api.dso.docker.com 443"
 "github.com 443"
 "gitlab.com 443"
 "api.docker.com 443"
)

echo "Generating CSV header..."

# Generate CSV Headers
echo -n "NODE" > "$output_file"
for entry in "${domains_ports[@]}"; do
    IFS=' ' read -r domain port <<< "$entry"
    echo -n ",${domain}" >> "$output_file"
done
echo "" >> "$output_file"

echo "Starting connectivity tests..."

# Loop setiap node di cluster OpenShift
for node in $(oc get nodes --no-headers | awk '{print $1}'); do
    echo "Testing from node: $node"
    row="$node"

    for entry in "${domains_ports[@]}"; do
        IFS=' ' read -r domain port <<< "$entry"

        echo "  - Checking $domain:$port ..."

        # Jalankan curl via SSH
        curl_output=$(ssh core@"$node" \
            "export http_proxy=$proxy; export https_proxy=$proxy; \
             curl -IL --connect-timeout 5 https://$domain 2>&1")

        # Klasifikasi hasil
        if echo "$curl_output" | grep -q "HTTP/1.1 200"; then
            result="Success"
        elif echo "$curl_output" | grep -qi "Forbidden\|Access Denied"; then
            result="Forbidden"
        elif echo "$curl_output" | grep -qi "Could not resolve"; then
            result="DNS_Fail"
        elif echo "$curl_output" | grep -qi "Connection timed out"; then
            result="Timeout"
        else
            result="Failed"
        fi

        row+=",$result"
    done

    echo "$row" >> "$output_file"
done

echo ""
echo "==================================================="
echo " Proxy Pre-Install Test Completed"
echo " Output saved to: $output_file"
echo "==================================================="
