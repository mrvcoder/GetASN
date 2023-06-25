#!/bin/bash 

# Define the options that the script accepts
options=":shr:a:x:o:l:d:"
silent="0"
dns="./resolvers.txt"
opt_domain=""
opt_output=""
opt_domainFileList=""
opt_ip=""
opt_ipFileList=""

# Parse the options passed to the script
while getopts "$options" opt; do
  case $opt in
    h ) 
        echo "usage: ./getasn.sh [options] ListOfDomains.txt"
        echo "-r set resolvers file address [ default: ./resolvers.txt ]"
        echo "-s silent output" 
        echo "-o set output (only .json is ok)" 
        echo "-l set domain list txt file (only .txt is ok)" 
        echo "-x set ip list txt file (only .txt is ok)" 
        echo "-a check single ip" 
        echo "-d check single domain" 
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
    x ) opt_ipFileList="$OPTARG"
        ;;
    a ) opt_ip="$OPTARG"
        ;;
    \? ) echo "Invalid option: -$OPTARG" 1>&2
         exit 1
         ;;
  esac
done
shift $(( OPTIND - 1 ))


if [ "$opt_domainFileList" == "" ] && [ "$opt_ipFileList" == "" ] && [ "$opt_ip" == "" ] && [ "$opt_domain" == "" ]; then
  echo "Error: No input provided."
  echo "usage: ./getasn.sh [options] "
  echo "run with -h for help menu :)"
  exit 1
fi

if [ ! -f "$opt_domainFileList" ] && [ "$opt_domainFileList" != "" ] ; then
  echo "Error: File not found."
  exit 1
fi

if [ ! -f "$opt_ipFileList" ] && [ "$opt_ipFileList" != "" ] ; then
  echo "Error: File not found."
  exit 1
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

isip=false
isdomain=false
# update cut-cdn providers
# cut-cdn -ua -silent

if [ "$opt_domainFileList" != "" ] || [ "$opt_domain" != "" ] ; then
    json='{"domains":[]}'
    isdomain=true
    if [ "$opt_domain" == "" ]; then
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
                      sleep 10s
                     
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
                  
                  else
                    sleep 1m
                fi
              done
        done
          sleep 5s
      done < "$opt_domainFileList"
    elif [ "$opt_domainFileList" == "" ]; then
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
fi

if [ "$opt_ipFileList" != "" ] || [ "$opt_ip" != "" ] ; then
  json='{"ips":[]}'
  isip=true

    if [ "$opt_ip" == "" ]; then
      while read -r ip; do
          # Check if the IP address is associated with a CDN
          is_cdn=$(echo $ip | cut-cdn -silent -t 3 | wc -l)
          ok=false
          while [ "$ok" != "true" ]
          do
              preflight=$(curl -v -s https://api.bgpview.io/ip/$ip  2>&1)
              httpResp=$(echo $preflight | grep -o -P '(HTTP/2 )[0-9]+')
              if [ "$httpResp" = "HTTP/2 200" ]; then
                  sleep 10s
                  
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
                  json=$(echo $json | jq --arg ip "$ip" --arg asn "$asn" --arg is_cdn "$is_cdn" --arg cidr "$cidr" --arg name "$name" '.ips += [{"ip":$ip,"asn":$asn,"is_cdn":$is_cdn,"cidr":$cidr,"name":$name}]')
              
              else
                sleep 1m
            fi
          done
      done < "$opt_ipFileList"
    elif [ "$opt_ipFileList" == "" ]; then
      # Check if the IP address is associated with a CDN
      is_cdn=$(echo $opt_ip | cut-cdn -silent | wc -l)
      ok=false
      while [ "$ok" != "true" ]
      do
          preflight=$(curl -v -s https://api.bgpview.io/ip/$opt_ip  2>&1)
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
              json=$(echo $json | jq --arg ip "$opt_ip"  --arg asn "$asn" --arg is_cdn "$is_cdn" --arg cidr "$cidr" --arg name "$name" '.ips += [{"ip":"'"$opt_ip"'","asn":$asn,"is_cdn":$is_cdn,"cidr":$cidr,"name":$name}]')

          else
            sleep 30s
          fi
      done 
    fi
fi



if [ "$opt_output" == "" ]; then
  output_file="getasn_output.json"
  output_file_same_asn="getasn_output_SameASN_NotCDN.json"
  output_file_not_cdn="getasn_output_NotCDN.json"


  if [ "$isdomain" == "true" ];then
              echo "domain"

    echo $json | jq . > $output_file
    echo '{ "domains": ['"$( echo $json | jq '.domains[] | select(.is_cdn == "false")' )"'] }' | jq '.' > $output_file_not_cdn  
    echo '{ "domains": '"$(echo $json | jq '.domains | group_by(.asn) | map(select(length > 1) | map(select(.is_cdn == "false"))) | flatten')"' }' | jq '.' > $output_file_same_asn
  fi

  if [ "$isip" == "true" ];then
    echo $json | jq . > $output_file
    echo '{ "ips": ['"$( echo $json | jq '.ips[] | select(.is_cdn == "false")' )"'] }' | jq '.' > $output_file_not_cdn 
    echo '{ "ips": '"$(echo $json | jq '.ips | group_by(.asn) | map(select(length > 1) | map(select(.is_cdn == "false"))) | flatten')"' }' | jq '.' > $output_file_same_asn
  fi

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
