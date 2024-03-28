#!/bin/bash

grep "ziti-controller REST API" *data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort > all.ctrl-apis.to.date.txt
grep "ziti-ctrl - control plane" *data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort > all.ctrl-plane.to.date.txt
grep "ziti-edge - data plane" *data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort > all.edge-routers.to.date.txt
grep "zit.link .link listener" *data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort > all.link-listeners.to.date.txt
grep "zrok ui matched" *data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort > all.zrok-ui.to.date.txt

#!/bin/bash

# Function to summarize IP appearances in a tab-separated CSV file
summarize_ip() {
    local filename="$1"

    # Extract $something from the filename
    local something=$(echo "$filename" | awk -F'[.$]' '{print $2}')

    # Check if file exists
    if [ ! -f "$filename" ]; then
        echo "Error: File '$filename' not found."
        return 1
    fi

    # Sort the CSV by IP address (assuming IP is the second column)
    local sorted_data=$(sort -t$'\t' -k2 "$filename")

    # Use awk to find the first and last appearance of each IP address
    local summary=$(echo "$sorted_data" | awk -F'\t' -v something="$something" '{
        ip = $2
        if (!ip_first[ip]) {
            ip_first[ip] = $1
        }
        ip_last[ip] = $1
    } END {
        for (ip in ip_first) {
            print something, ip, ip_first[ip], ip_last[ip]
        }
    }')

    # Output the summary
    echo "$summary"
}

# Example usage: summarize_ip "all.$something.to.date.txt"



summarize_ip all.ctrl-apis.to.date.txt > summarized.ctrl-apis.txt
summarize_ip all.ctrl-plane.to.date.txt > summarized.ctrl-plane.txt
summarize_ip all.edge-routers.to.date.txt > summarized.edge-routers.txt
summarize_ip all.link-listeners.to.date.txt > summarized.link-listeners.txt
summarize_ip all.zrok-ui.to.date.txt > summarized.zrok-ui.txt

split_and_sort_by_date() {
    local input_file="$1"
    local output_dir="output"
    local base_name="$(basename "$input_file" .txt)"

    # Create the output directory if it doesn't exist
    mkdir -p "$output_dir"

    echo "processing $input_file"
    while IFS=$'\t' read -r date rest_of_line || [[ -n "$date" ]]; do
        output_file="$output_dir/${date}-${base_name}.txt"
        echo -e "$date\t$rest_of_line" >> "$output_file"
        sort -o "$output_file" "$output_file"
    done < "$input_file"
}

split_and_sort_by_date "all.ctrl-apis.to.date.txt"
split_and_sort_by_date "all.ctrl-plane.to.date.txt"
split_and_sort_by_date "all.edge-routers.to.date.txt"
split_and_sort_by_date "all.link-listeners.to.date.txt"
split_and_sort_by_date "all.zrok-ui.to.date.txt"
