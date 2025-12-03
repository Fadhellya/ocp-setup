#!/bin/bash

# Proxy opsional (biarkan kosong jika tidak ada proxy)
proxy=""

# Output CSV
output_file="ocp_proxy_preinstall_check.csv"

# Daftar domain + port
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

# CSV Header
echo -n "CHECK_FROM_HOST" > "$output_file"
for entry in "${domains_ports[@]}"; do
    IFS=' ' read -r domain port <<< "$entry"
    echo -n ",${domain}" >> "$output_file"
done
echo "" >> "$output_file"

hostname_local=$(hostname)
echo "Starting connectivity tests from host: $hostname_local"

row="$hostname_local"

# Test semua domain
for entry in "${domains_ports[@]}"; do
    IFS=' ' read -r domain port <<< "$entry"

    echo ""
    echo "  - Checking $domain:$port ..."

    # Apply proxy (hanya jika diisi)
    if [[ -n "$proxy" ]]; then
        export http_proxy=$proxy https_proxy=$proxy
    else
        unset http_proxy https_proxy
    fi

    # ======= CURL -v (VERBOSE) CHECK ========
    curl_output=$(curl -v --connect-timeout 5 "https://$domain:$port" 2>&1)

    # ======= Match result ========
    if echo "$curl_output" | grep -q "SSL connection using"; then
        result="Success"
    elif echo "$curl_output" | grep -qi "Forbidden\|403"; then
        result="Forbidden"
    elif echo "$curl_output" | grep -qi "Could not resolve host"; then
        result="DNS_Fail"
    elif echo "$curl_output" | grep -qi "Connection timed out"; then
        result="Timeout"
    elif echo "$curl_output" | grep -qi "Failed to connect"; then
        result="Failed"
    else
        result="Failed"
    fi

    row+=",$result"
done

echo "$row" >> "$output_file"

echo ""
echo "====================================================="
echo " Proxy Pre-Install Whitelist Test Completed"
echo " Output saved to: $output_file"
echo "====================================================="
