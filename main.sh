#!/bin/bash

# This script performs a domain availability check using the NameAPI API and outputs the 
# results to a CSV file called output.csv. The list of names to be checked is defined in 
# the names array, and the list of top-level domains (TLDs) to use for checking is 
# defined in the domains array.

names=("ayana" "shakti" "astra" "yantra" "vidyut" "jagat" "mantra" "jnana" "nirmaan" "sankhya" "drishti" "prakruti" "netra" "mrida" "chakra" ) # Domain names : List of sanskrit names generated from chatgpt 
domains='["tech","ai","xyz","io","dev","host","app","org","net","com"]' # List of TLDs for robotics and technology

# Semaphore implementation for locking mechanism
semaphore=0
mutex=0
max_concurrency=5

acquire_lock() {
  while [ $mutex -eq 1 ]; do
    sleep 0.1
  done
  mutex=1
}

release_lock() {
  mutex=0
}

check_availability() {
  local name=$1

  response=$(curl -s "https://name.qlaffont.com/api/domains?name=$name&domains=$domains" \
    --globoff --compressed -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' \
    -H 'Accept-Language: en-US,en;q=0.5' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' \
    -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: cross-site' \
    -H 'If-None-Match: W/"hcnxyqy19a101"' \
    -H 'TE: trailers')

  # Extract the required information from the JSON response using jq and create a CSV
  local csv=$(echo "$response" | jq -r '.data[] | [.domainName, .isTaken, .registrar] | @csv')

  # Acquire the lock before writing to the file
  acquire_lock

  # Output the CSV to the file
  echo "$csv" >>output.csv

  # Release the lock after writing to the file
  release_lock
}

# Output CSV header to a file
echo "domainname,isTaken,registrar" >output.csv

# Iterate over the list of names and run checks in parallel with limited concurrency
for name in "${names[@]}"; do
  (
    # Acquire the semaphore
    while [ $semaphore -ge $max_concurrency ]; do
      sleep 0.1
    done
    semaphore=$((semaphore + 1))

    # Perform the availability check
    check_availability "$name"

    # Release the semaphore
    semaphore=$((semaphore - 1))
  ) &
done

# Wait for all background processes to finish
wait
