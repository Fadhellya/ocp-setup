#!/bin/bash

# Define the list of domains and ports
declare -a domains_ports=(
 "https://quay.io 443"
 "https://cdn.quay.io 443"
 "https://cdn01.quay.io 443"
 "https://cdn02.quay.io 443"
 "https://cdn03.quay.io 443"
 "https://cdn04.quay.io 443"
 "https://cdn05.quay.io 443"
 "https://cdn06.quay.io 443"
 "https://registry.redhat.io 443"
 "https://sso.redhat.com 443"
 "https://openshift.org 443"
 "https://mirror.openshift.com 443"
 "https://storage.googleapis.com/openshift-release 443"
 "https://quay-registry.s3.amazonaws.com 443"
 "https://api.openshift.com 443"
 "https://art-rhcos-ci.s3.amazonaws.com 443"
 "https://cloud.redhat.com/openshift 443"
 "https://registry.access.redhat.com 443"
 "https://cert-api.access.redhat.com 443"
 "https://api.access.redhat.com 443"
 "https://infogw.api.openshift.com 443"
 "https://cloud.redhat.com/api/ingress 443"
)

# Output CSV file
output_file="telnet_ocp_all_new.csv"

# Add CSV headers
proxy="http://10.210.9.250:8080"
echo -n "NAME" > "$output_file"
for entry in "${domains_ports[@]}"; do
    # Extract the domain name from each entry
    IFS=' ' read -r domain port <<< "$entry"
    echo -n ",${domain}" >> "$output_file"
done
echo "" >> "$output_file"

# Loop over the nodes and collect results
for node in $(oc get nodes --no-headers | awk '{print $1}'); do
    echo "Connecting to $node..."
    row="$node"  # Initialize the row with the node name

    # Loop through the defined domain and port pairs
    for entry in "${domains_ports[@]}"; do
        # Split entry into domain and port
        IFS=' ' read -r domain port <<< "$entry"

        echo "Checking connection to $domain on port $port from $node..."

        # SSH into the node and run curl to check the connection
        curl_output=$(ssh core@"$node" "export http_proxy=$proxy; export https_proxy=$proxy; curl -IL --connect-timeout 5 $domain:$port 2>&1")

        # Determine if the connection was successful
        if echo "$curl_output" | grep -q "HTTP/1.1 200"; then
            result="Success"
        else
            result="Forbidden"
        fi

        # Append the result to the row
        row+=",${result}"
    done

    # Append the row to the output file
    echo "$row" >> "$output_file"
done

echo "Connection checks completed. Results saved to $output_file."
