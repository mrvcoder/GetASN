#!/bin/bash 

# Define the options that the script accepts
options=":shr:o:l:d:"
silent="0"
dns="./resolvers.txt"
opt_domain=""
opt_output=""
opt_domainFileList=""

# Parse the options passed to the script
while getopts "$options" opt; do
  case $opt in
    h ) 
        echo "usage: ./getasn.sh [options] ListOfDomains.txt"
        echo "-r set resolvers file address [ default: ./resolvers.txt ]"
        echo "-s silent output" 
        echo "-o set output (only .json is ok)" 
        echo "-l set domain list txt file (only .txt is ok)" 
        exit 1
         ;;
    s ) silent="1"
        ;;
    r ) dns="$OPTARG"
        ;;
    d ) opt_domain="$OPTARG"
        ;;
    o ) opt_output="$OPTARG"
        ;;
    l ) opt_domainFileList="$OPTARG"
        ;;
    \? ) echo "Invalid option: -$OPTARG" 1>&2
         exit 1
         ;;
  esac
done
shift $(( OPTIND - 1 ))

if [ "$opt_domainFileList" == "" ]; then
   # usage : getasn ListOfDomains.txt
  if [ "$opt_domainFileList" == "" ]; then
    echo "Error: No input provided."
    echo "usage: ./getasn.sh [options] "
    echo "run with -h for help menu :)"
    exit 1
  fi
  # Check if the file exists
  if [ ! -f "$opt_domainFileList" ]; then
    echo "Error: File not found."
    exit 1
  fi
fi






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
# cut-cdn -ua -silent

if [ "$opt_domain" = "" ]; then
      while read -r domain; do
        # Get the IP address of the URL
        ips=$(echo $domain | dnsx -a -aaaa -resp-only -silent -r $dns -retry 3 -t 150)
        for ip in $ips
        do
              # Check if the IP address is associated with a CDN
              is_cdn=$(echo $ip | cut-cdn -silent -t 3 | wc -l)
              ok=false
              while [ "$ok" != "true" ]
              do
                  preflight=$(curl -v -s https://api.bgpview.io/ip/$ip  2>&1)
                  httpResp=$(echo $preflight | grep -o -P '(HTTP/2 )[0-9]+')
                  if [ "$httpResp" = "HTTP/2 200" ]; then
                      # sleep 20
                     
                      cidr=$(echo $preflight | sed 's/.*#0 to host api.bgpview.io left intact //' | jq -r ".data.prefixes[] | .prefix" -r | sort -u)
                      asn=$(echo $preflight | sed 's/.*#0 to host api.bgpview.io left intact //'  | jq -r ".data.prefixes[] | .asn.asn" -r | sort -u)
                      name=$(curl -s https://api.bgpview.io/asn/$asn | jq -r ".data .name" | sort -u)
                      ok=true

                      if [ $is_cdn == "0" ]
                      then
                            is_cdn=true
                      else
                            is_cdn=false
                      fi



                      # Append the information to the output file
                      # Add the data to the JSON object
                      json=$(echo $json | jq --arg domain "$domain" --arg ip "$ip" --arg asn "$asn" --arg is_cdn "$is_cdn" --arg cidr "$cidr" --arg name "$name" '.domains += [{"domain":$domain,"ip":$ip,"asn":$asn,"is_cdn":$is_cdn,"cidr":$cidr,"name":$name}]')
                  
                  # else
                  #   sleep 1s
                fi
              done
        done
          # sleep 5
      done < "$opt_domainFileList"
else
   # Check if the IP address is associated with a CDN
    ips=$(echo $opt_domain | dnsx -a -aaaa -resp-only -silent -r $dns -retry 3 -t 150)
    for ip in $ips
    do
        is_cdn=$(echo $ip | cut-cdn -silent | wc -l)
        ok=false
        while [ "$ok" != "true" ]
        do
            preflight=$(curl -v -s https://api.bgpview.io/ip/$ip  2>&1)
            httpResp=$(echo $preflight | grep -o -P '(HTTP/2 )[0-9]+')
            if [ "$httpResp" = "HTTP/2 200" ]; then
                sleep 20
                cidr=$(echo $preflight | sed 's/.*#0 to host api.bgpview.io left intact //' | jq -r ".data.prefixes[] | .prefix" -r | sort -u)
                asn=$(echo $preflight | sed 's/.*#0 to host api.bgpview.io left intact //' | jq -r ".data.prefixes[] | .asn.asn" -r | sort -u)
                name=$(curl -s https://api.bgpview.io/asn/$asn | jq -r ".data .name" | sort -u)
                ok=true

                if [ $is_cdn == "0" ]
                then
                      is_cdn=true
                else
                      is_cdn=false
                fi

                # Append the information to the output file
                # Add the data to the JSON object
                json=$(echo $json | jq --arg domain "$opt_domain" --arg ip "$ip"  --arg asn "$asn" --arg is_cdn "$is_cdn" --arg cidr "$cidr" --arg name "$name" '.domains += [{"domain":"'"$opt_domain"'","ip":$ip,"asn":$asn,"is_cdn":$is_cdn,"cidr":$cidr,"name":$name}]')
            else
              sleep 30s
            fi
        done 
    done
fi



if [ "$opt_output" == "" ]; then
output_file="getasn_output.json"
output_file_same_asn="getasn_output_SameASN_NotCDN.json"
output_file_not_cdn="getasn_output_NotCDN.json"

echo $json | jq . > $output_file
echo $json | jq '{ ".domains": [.domains[] | select(.is_cdn == "false")]}' > $output_file_not_cdn 
echo $json | jq '.domains | group_by(.asn) | map(select(length > 1) | map(select(.is_cdn == "false"))) | flatten' > $output_file_same_asn
else
echo $json | jq . > $opt_output
fi



if [ "$silent" == "0" ]; then
        if [ "$opt_output" == "" ]; then
          echo "========================="
          cat $output_file | jq .
          echo "========================="
          echo "Twitter: https://twitter.com/VC0D3R | Github : https://github.com/mrvcoder "
          echo -e "Done! \nOutPuts: $output_file - $output_file_same_asn - $output_file_not_cdn :)"
        else
          cat $opt_output | jq .
        fi
else
        echo "Done !"
fi
