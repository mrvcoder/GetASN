#!/bin/bash

# Define the options that the script accepts
options=":hds:"
silent="0"
dns="./resolvers.txt"
# Parse the options passed to the script
while getopts "$options" opt; do
  case $opt in
    h ) 
         echo "usage: ./getasn.sh [options] ListOfDomains.txt"
         echo " -d Set txt resolvers file address "
        echo "-s silent output" 
        exit 1
         ;;
    s ) silent="1"
        ;;
    d ) dns="$OPTARG"
        ;;
    \? ) echo "Invalid option: -$OPTARG" 1>&2
         exit 1
         ;;
  esac
done
shift $(( OPTIND - 1 ))

 # usage : getasn ListOfDomains.txt
  if [ -z "$1" ]; then
    echo "Error: No input provided."
    echo "usage: ./getasn.sh [options] ListOfDomains.txt "
    exit 1
  fi


  # Store the file path in a variable
  input_file=$1

  # Check if the file exists
  if [ ! -f "$input_file" ]; then
    echo "Error: File not found."
    exit 1
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
json='{"domains":[]}'
# update cut-cdn providers
cut-cdn -ua

# Loop through the URLs in the file
api_reqs=0
index=0
while read -r domain; do
  # Get the IP address of the URL
  ips=$(echo $domain | dnsx -a -aaaa -resp-only -silent -r $dns -retry 3 -t 150)
  for ip in $ips
  do
        # Check if the IP address is associated with a CDN
        is_cdn=$(echo $ip | cut-cdn -silent -t 3 | wc -l)
        cidr=$(curl -s https://api.bgpview.io/ip/$ip | jq -r ".data.prefixes[] | .prefix" -r | sort -u)
        asn=$(curl -s https://api.bgpview.io/ip/$ip | jq -r ".data.prefixes[] | .asn.asn" -r | sort -u)
        name=$(curl -s https://api.bgpview.io/asn/$asn | jq -r ".data .name" | sort -u)
        if [ $is_cdn == "0" ]
        then
             is_cdn=true
        else
             is_cdn=false
        fi

      

        # Append the information to the output file
        # Add the data to the JSON object
        json=$(echo $json | jq --arg domain "$domain" --arg ip "$ip" --arg asn "$asn" --arg is_cdn "$is_cdn" --arg cidr "$cidr" --arg name "$name" '.domains += [{"domain":$domain,"ip":$ip,"asn":$asn,"is_cdn":$is_cdn,"cidr":$cidr,"name":$name}]')
  done
  
done < "$input_file"



# Write the JSON object to the output file
echo $json | jq . > $output_file
echo $json | jq '{ ".domains": [.domains[] | select(.is_cdn == "false")]}' > $output_file_not_cdn 
echo $json | jq '.domains | group_by(.asn) | map(select(length > 1) | map(select(.is_cdn == "false"))) | flatten' > $output_file_same_asn
if [ "$silent" == "1" ]; then
        echo "========================="
        cat $output_file | jq .
        echo "========================="
        echo "Twitter: https://twitter.com/VC0D3R | Github : https://github.com/mrvcoder "
        echo -e "Done! \nOutPuts: $output_file - $output_file_same_asn - $output_file_not_cdn :)"
else
        echo "Done !"
fi
