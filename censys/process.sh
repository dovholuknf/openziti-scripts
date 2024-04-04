#!/bin/bash
SCRIPT_DIR="$(realpath $(dirname "$0"))"
DATA_DIR=$SCRIPT_DIR/data
OUTPUT_DIR=$SCRIPT_DIR/output

grep "ziti-controller REST API" $DATA_DIR/*data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort | sed 's#'${DATA_DIR}'/##g' > $SCRIPT_DIR/all.ctrl-apis.to.date.txt
grep "ALPN	ziti-ctrl" $DATA_DIR/*data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort | sed 's#'${DATA_DIR}'/##g' > $SCRIPT_DIR/all.ctrl-plane.to.date.txt
grep "ALPN	ziti-edge" $DATA_DIR/*data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort | sed 's#'${DATA_DIR}'/##g' > $SCRIPT_DIR/all.edge-routers.to.date.txt
grep "ALPN	ziti-link" $DATA_DIR/*data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort | sed 's#'${DATA_DIR}'/##g' > $SCRIPT_DIR/all.link-listeners.to.date.txt
grep "zrok ui matched" $DATA_DIR/*data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort | sed 's#'${DATA_DIR}'/##g' > $SCRIPT_DIR/all.zrok-ui.to.date.txt
grep "ziti-admin-console" $DATA_DIR/*data.results.txt | sed 's/.censys-data.results.txt:/\t/g' | sort | sed 's#'${DATA_DIR}'/##g' > $SCRIPT_DIR/all.ziti-admin-console.to.date.txt


# Function to summarize IP appearances in a tab-separated CSV file
summarize_ip() {
    local filename="$1"

    # Extract $something from the filename
    local something=$(echo "$filename" | awk -F'[.$]' '{print $2}')

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


summarize_ip all.ctrl-apis.to.date.txt > summarized.ctrl-apis.txt
summarize_ip all.ctrl-plane.to.date.txt > summarized.ctrl-plane.txt
summarize_ip all.edge-routers.to.date.txt > summarized.edge-routers.txt
summarize_ip all.link-listeners.to.date.txt > summarized.link-listeners.txt
summarize_ip all.zrok-ui.to.date.txt > summarized.zrok-ui.txt
summarize_ip all.ziti-admin-console.to.date.txt > summarized.ziti-admin-console.txt

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

make_video() {
  local what="$1"
  ffmpeg -y -f image2 -r 2 -pattern_type glob -i "${OUTPUT_DIR}/*${what}*-captioned.png" -c:v libx264 -pix_fmt yuv420p ${what}-over-time.mp4
}

echo "cleaning previous split and sorted output"
rm $OUTPUT_DIR/*-all.*to.date*.txt

split_and_sort_by_date "all.ctrl-apis.to.date.txt"
split_and_sort_by_date "all.ctrl-plane.to.date.txt"
split_and_sort_by_date "all.edge-routers.to.date.txt"
split_and_sort_by_date "all.link-listeners.to.date.txt"
split_and_sort_by_date "all.zrok-ui.to.date.txt"
split_and_sort_by_date "all.ziti-admin-console.to.date.txt"

# ffmpeg -f image2 -r 25 -pattern_type glob -i '*ctrl-apis*png' -c:v libx264 -pix_fmt yuv420p output.mp4
# ffmpeg -y -f image2 -r 2 -pattern_type glob -i '*ctrl-apis*png' -c:v libx264 -pix_fmt yuv420p output2.mp4

python3 capture.py

make_video "ctrl-apis"
make_video "ctrl-plane"
make_video "edge-routers"
make_video "link-listeners"
make_video "zrok-ui"
make_video "ziti-admin-console"


make_webm() {
  local what="$1"
  ffmpeg -y -f image2 -r 2 -pattern_type glob -i "${OUTPUT_DIR}/*${what}*-captioned.png" -c:v libvpx-vp9 -pix_fmt yuv420p -vf "fps=10,scale=1920:-1:flags=lanczos" ${what}-over-time.webm
}


make_webm "ctrl-apis"
make_webm "ctrl-plane"
make_webm "edge-routers"
make_webm "link-listeners"
make_webm "zrok-ui"
make_webm "ziti-admin-console"


