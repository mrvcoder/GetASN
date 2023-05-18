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

  # usage : getasn ListofDomains.txt
  if [ -z "$2" ]; then
    echo "Error: No input provided."
    echo "usage: ./getasn.sh [options] ListofDomains.txt "
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
    echo "usage: ./getasn.sh [options] ListofDomains.txt "
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
output_file="getasn_output.json"
output_file_same_asn="getasn_output_SameASN_NotCDN.json"
output_file_not_cdn="getasn_output_NotCDN.json"

# Remove the output file if it already exists
if [ -f "$output_file" ]; then
  rm "$output_file"
fi

if [ -f "$output_file_same_asn" ]; then
  rm "$output_file_same_asn"
fi

if [ -f "$output_file_not_cdn" ]; then
  rm "$output_file_not_cdn"
fi

# Initialize the JSON object
json='{"urls":[]}'
api_keys=("YOUR_API_KEY" "second api key")

if [ ${api_keys[0]} == "YOUR_API_KEY" ]; then
    echo "Please set your api key for https://ipdata.co"
    exit 1
fi

# Loop through the URLs in the file
api_reqs=0
index=0
while read -r domain; do
  # Get the IP address of the URL
  ips=$(dig A $domain @8.8.8.8 +short | grep -E '^[0-9]+.+')
  echo $ips , $domain
  for ip in $ips
  do
      if [ $api_reqs -gt 1499 ]
      then
        index=$(($index+1))
      fi

      if [ -n ${api_keys[index]} ]
      then
        # Use the ipdata.co API to look up information about the IP address
        api_response=$(curl -s "https://api.ipdata.co/${ip}?api-key=${api_keys[index]}")
        api_reqs=$(($api_reqs+1))

        # Check if the IP address is associated with a CDN
        is_cdn=$(echo $api_response | jq -r '.asn.type')

        if [ "$is_cdn" == "cdn" ]; then
            is_cdn=true
        elif [ "$is_cdn" == "null" ]; then
            is_cdn="NULL! (maybe api.ipdata.co has some errors)"
        else
            is_cdn=false
        fi

        # Get the ASN information for the IP address
        asn=$(whois  -h whois.cymru.com "-v $ip" | awk '{print $1}' | tail -1 | sed 's/AS//g')

        # Append the information to the output file
        # Add the URL, IP, and ASN to the JSON object
        json=$(echo $json | jq --arg url "$domain" --arg ip "$ip" --arg asn "$asn" --arg is_cdn "$is_cdn" '.urls += [{"url":$url,"ip":$ip,"asn":$asn,"is_cdn",$is_cdn}]')
      fi
  done
  
done < "$input_file"



# Write the JSON object to the output file
echo $json | jq . > $output_file
echo $json | jq '{ "urls": [.urls[] | select(.is_cdn == "false")]}' > $output_file_not_cdn 
echo $json | jq '.urls | group_by(.asn) | map(select(length > 1) | map(select(.is_cdn == "false"))) | flatten' > $output_file_same_asn
echo "========================="
cat $output_file | jq .
echo "========================="
echo "Twitter: https://twitter.com/VC0D3R | Github : https://github.com/mrvcoder "
echo -e "Done! The ORGINAL output has been saved in $output_file \nAND the output which ASNs are equal and is_cdn is false saved at $output_file_same_asn \nAND the output which is_cdn is false is saved at $output_file_not_cdn :)"

# Check if live mode was enabled (soon will be updated !)
if [ "$live_mode" == "1" ]; then
  # Loop through the ASNs in the file
  # Get the unique ASN values from the JSON file
  asns=$(cat output.json | jq '.urls[] | select(.is_cdn == "false") | .asn' | sort -u)
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
