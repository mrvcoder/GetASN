#!/bin/bash

# Define the options that the script accepts
options=":l"
# Parse the options passed to the script
while getopts "$options" opt; do
  case $opt in
    l ) live_mode=1 ;;
    \? ) echo "Invalid option: -$OPTARG" 1>&2
         exit 1
         ;;
  esac
done

if [ "$live_mode" == "1" ]; then

  # usage : getasn ListofUrls.txt
  if [ -z "$2" ]; then
    echo "Error: No input provided."
    echo "usage: ./getasn.sh [options] ListOfUrls.txt "
    echo "options:
    -l => get all live ips of asns that find with this tool"
    exit 1
  fi


  # Store the file path in a variable
  input_file=$2

  # Check if the file exists
  if [ ! -f "$input_file" ]; then
    echo "Error: File not found."
    exit 1
  fi

else

 # usage : getasn ListofUrls.txt
  if [ -z "$1" ]; then
    echo "Error: No input provided."
    echo "usage: ./getasn.sh [options] ListOfUrls.txt "
    echo "options:
    -l => get all live ips of asns that find with this tool"
    exit 1
  fi


  # Store the file path in a variable
  input_file=$1

  # Check if the file exists
  if [ ! -f "$input_file" ]; then
    echo "Error: File not found."
    exit 1
  fi

fi

# Define the output file for the JSON object
output_file="output.json"

# Remove the output file if it already exists
if [ -f "$output_file" ]; then
  rm "$output_file"
fi

# Initialize the JSON object
json='{"urls":[]}'

# Loop through the URLs in the file
while read -r url; do
  # Get the IP address of the URL
  ip=$(nslookup "$url" | awk '/^Address: / { print $2 }')

  # Get the ASN information for the IP address
  asn=$(whois  -h whois.cymru.com "-v $ip" | awk '{print $1}' | tail -1 | sed 's/AS//g')

  # Append the information to the output file
  # Add the URL, IP, and ASN to the JSON object
  json=$(echo $json | jq --arg url "$url" --arg ip "$ip" --arg asn "$asn" '.urls += [{"url":$url,"ip":$ip,"asn":$asn}]')
done < "$input_file"
# Write the JSON object to the output file
echo $json | jq . > "$output_file"
echo "========================="
cat $output_file
echo "========================="
echo "Twitter: https://twitter.com/VC0D3R | Github : https://github.com/mrvcoder "
echo "Done! The output has been saved in $output_file :)"

# Check if live mode was enabled
if [ "$live_mode" == "1" ]; then
  # Loop through the ASNs in the file
  # Get the unique ASN values from the JSON file
  asns=$(cat output.json | jq '.urls[].asn' -r | sort -u)
  # Loop through each ASN value
  for asn in $asns; do
    # Run the desired command for each ASN
    result=$(whois -h whois.radb.net -- "-i origin AS$asn" | grep -Eo "([0-9.]+){4}/[0-9]+" | uniq | mapcidr -silent | httpx)
    echo "created file $asn.live.ips.txt"
    echo $result > $asn.live.ips.txt
  done
  echo "========================="
  echo "Done!" 
  echo "========================="
  echo "Please support :D"
  echo "Twitter: https://twitter.com/VC0D3R | Github : https://github.com/mrvcoder"
  echo "========================="

fi
