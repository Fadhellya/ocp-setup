#!/bin/bash

# Proxy opsional (biarkan kosong jika tidak ada proxy)
proxy=""

# Output ke TXT
output_file="ocp_proxy_preinstall_check.txt"

# Daftar domain + port
declare -a domains_ports=(
 # --- Red Hat Core Registries ---
 "registry.redhat.io 443"
 "registry.access.redhat.com 443"
 "access.redhat.com 443"
 "registry.connect.redhat.com 443"

 # --- Quay ---
 "quay.io 443"
 "cdn.quay.io 443"
 "cdn01.quay.io 443"
 "cdn02.quay.io 443"
 "cdn03.quay.io 443"
 "cdn04.quay.io 443"
 "cdn05.quay.io 443"
 "cdn06.quay.io 443"

 # --- Red Hat & OpenShift Services ---
 "api.openshift.com 443"
 "mirror.openshift.com 443"
 "rhcos.mirror.openshift.com 443"
 "console.redhat.com 443"
 "sso.redhat.com 443"
 "cert-api.access.redhat.com 443"
 "api.access.redhat.com 443"
 "infogw.api.openshift.com 443"

 # --- Cluster Endpoint (ganti sesuai cluster) ---
 "apps.<cluster-name>.<basedomain> 443"

 # --- Image Release & Signatures ---
 "storage.googleapis.com 443"
 "storage.googleapis.com/openshift-release 443"

 # --- AWS S3 Backends (Quay / Red Hat) ---
 "quayio-production-s3.s3.amazonaws.com 443"
 "oso-rhc4tp-docker-registry.s3-us-west-2.amazonaws.com 443"
 "s3-us-west-2.amazonaws.com 443"
 "s3-us-east-1.amazonaws.com 443"
 "amazonaws.com 443"

 # --- CDN Providers ---
 "akamaiedge.net 443"
 "akamaitechnologies.com 443"
 "cloudflare.net 443"
 "cloudfront.net 443"

 # --- Docker (optional but common) ---
 "docker.io 443"
 "registry-1.docker.io 443"
 "hub.docker.com 443"
 "index.docker.io 443"
 "auth.docker.io 443"
 "login.docker.com 443"

 # --- Source Code Repositories ---
 "github.com 443"
 "raw.githubusercontent.com 443"
 "gitlab.com 443"

 # --- Language / Framework Ecosystem ---
 "repo.maven.apache.org 443"
 "apache.org 443"
 "npmjs.com 443"
 "rubygems.org 443"
 "cpan.org 443"
 "sonatype.org 443"
 "jboss.org 443"
 "jenkins.io 443"
 "jenkins-ci.org 443"
 "spring.io 443"
 "eclipse.org 443"
 "fabric8.io 443"
 "codehaus.org 443"
 "bintray.com 443"
 "openshift.io 443"
 "openshift.org 443"
)

hostname_local=$(hostname)
echo "CHECK_FROM_HOST: $hostname_local" > "$output_file"
echo "---------------------------------------------------------------" >> "$output_file"

echo "Testing connectivity from host: $hostname_local"

# Test semua domain
for entry in "${domains_ports[@]}"; do
    IFS=' ' read -r domain port <<< "$entry"

    echo ""
    echo "  - Checking $domain:$port ..."

    # Apply proxy (jika ada)
    if [[ -n "$proxy" ]]; then
        export http_proxy=$proxy https_proxy=$proxy
    else
        unset http_proxy https_proxy
    fi

    # CURL verbose check
    curl_output=$(curl -v --connect-timeout 5 "https://$domain:$port" 2>&1)

    # Result matching
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

    # Format TXT rapi (kolom domain kiri rata)
    printf "%-60s %s\n" "$domain" "$result" >> "$output_file"

done

echo ""
echo "====================================================="
echo " Proxy Pre-Install Whitelist Test Completed"
echo " Output saved to: $output_file"
echo "====================================================="
