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
opt_asn=""
opt_asnFileList=""
# Parse the options passed to the script
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h )
        shift 
        echo "usage: ./getasn.sh [options]"
        echo "-r                  set resolvers file address [ default: ./resolvers.txt ]"
        echo "-s   -silent        silent output" 
        echo "-o                  set output (only .json is ok)" 
        echo "-domainlist         set domain list txt file (only .txt is ok)" 
        echo "-domain             check single domain" 
        echo "-iplist             set ip list txt file (only .txt is ok)" 
        echo "-ip                 check single ip" 
        echo "-asn                check single asn" 
        echo "-asnlist            set asn list txt file (only .txt is ok)" 
        exit 1
         ;;
    -s ) 
        shift
        silent="1"
        ;;
    -silent ) 
        shift
        silent="1"
        ;;
    -r ) 
        shift
        dns="$1"
        ;;
    -domain ) 
        shift
        opt_domain="$1"
        ;;
    -o ) 
        shift
        opt_output="$1"
        ;;
    -domainlist ) 
        shift
        opt_domainFileList="$1"
        ;;
    -iplist ) 
        shift
        opt_ipFileList="$1"
        ;;
    -ip ) 
        shift
        opt_ip="$1"
        ;;
    -asn )  
          shift 
          opt_asn="$1"
        ;;
    -asnlist ) 
        shift
      opt_asnFileList="$1"
        ;;
    \? ) echo "Invalid option: -$1" 1>&2
         exit 1
         ;;
  esac
  shift
done

if [ "$opt_domainFileList" == "" ] && [ "$opt_ipFileList" == "" ] && [ "$opt_ip" == "" ] && [ "$opt_domain" == "" ] && [ "$opt_asn" == "" ] && [ "$opt_asnFileList" == "" ]; then
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

if [ ! -f "$opt_asnFileList" ] && [ "$opt_asnFileList" != "" ] ; then
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
isasn=false 
# update cut-cdn providers
cut-cdn -ua -silent


# domain
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
                      resdata=$(curl -s https://api.bgpview.io/ip/$ip)

                     
                      cidr=$(echo $resdata | jq -r ".data.prefixes[] | .prefix" -r | sort -u)
                      asn=$(echo $resdata  | jq -r ".data.prefixes[] | .asn.asn" -r | sort -u)
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

                    resdata=$(curl -s https://api.bgpview.io/ip/$ip)

                    cidr=$(echo $resdata | jq -r ".data.prefixes[] | .prefix" -r | sort -u)
                    asn=$(echo $resdata | jq -r ".data.prefixes[] | .asn.asn" -r | sort -u)
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


# ip
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
                  resdata=$(curl -s https://api.bgpview.io/ip/$ip)

                  
                  cidr=$(echo $resdata | jq -r ".data.prefixes[] | .prefix" -r | sort -u)
                  asn=$(echo $resdata  | jq -r ".data.prefixes[] | .asn.asn" -r | sort -u)
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

              resdata=$(curl -s https://api.bgpview.io/ip/$opt_ip)
              cidr=$(echo $resdata | jq -r ".data.prefixes[] | .prefix" -r | sort -u)
              asn=$(echo $resdata | jq -r ".data.prefixes[] | .asn.asn" -r | sort -u)
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


# asn
if [ "$opt_asnFileList" != "" ] || [ "$opt_asn" != "" ] ; then
  isasn=true
  json="{\"asns\":{"
    if [ "$opt_asn" == "" ]; then
      while read -r asn; do
          # Check if the IP address is associated with a CDN
          ok=false
          while [ "$ok" != "true" ]
          do
              preflight=$(curl -v -s https://api.bgpview.io/asn/$asn/prefixes  2>&1)
              httpResp=$(echo $preflight | grep -o -P '(HTTP/2 )[0-9]+')
              if [ "$httpResp" = "HTTP/2 200" ]; then
                  sleep 10s
                  resdata=$(curl -s https://api.bgpview.io/asn/$asn/prefixes)
                  data_v4=$(echo $resdata | jq -r '.data.ipv4_prefixes[] | { prefix, name, description } | @json + ","' | sed '${s/,$//}' )
                  data_v6=$(echo $resdata  | jq -r '.data.ipv6_prefixes[] | { prefix, name, description } | @json + ","' | sed '${s/,$//}' )

                  ok=true
                  json=$(echo $json"\"$asn\":{\"ipv4_prefixes\":[$data_v4],\"ipv6_prefixes\":[$data_v6]},")
              else
                sleep 1m
              fi
          done
      done < "$opt_asnFileList"
    elif [ "$opt_asnFileList" == "" ]; then
      # Check if the IP address is associated with a CDN
      is_cdn=$(echo $opt_asn | cut-cdn -silent | wc -l)
      ok=false
      while [ "$ok" != "true" ]
      do
          preflight=$(curl -v -s https://api.bgpview.io/asn/$opt_asn/prefixes  2>&1)
          httpResp=$(echo $preflight | grep -o -P '(HTTP/2 )[0-9]+')
          if [ "$httpResp" = "HTTP/2 200" ]; then
                  resdata=$(curl -s https://api.bgpview.io/asn/$opt_asn/prefixes)
                  data_v4=$(echo $resdata | jq -r '.data.ipv4_prefixes[] | { prefix, name, description } | @json + ","' | sed '${s/,$//}' )
                  data_v6=$(echo $resdata  | jq -r '.data.ipv6_prefixes[] | { prefix, name, description } | @json + ","' | sed '${s/,$//}' )

                  ok=true
                  json=$(echo "{\"$opt_asn\":{\"ipv4_prefixes\":[$data_v4],\"ipv6_prefixes\":[$data_v6]}}")
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

    echo $json | jq . > $output_file
    echo '{ "domains": ['"$( echo $json | jq '.domains[] | select(.is_cdn == "false")' )"'] }' | jq '.' > $output_file_not_cdn  
    echo '{ "domains": '"$(echo $json | jq '.domains | group_by(.asn) | map(select(length > 1) | map(select(.is_cdn == "false"))) | flatten')"' }' | jq '.' > $output_file_same_asn
  fi

  if [ "$isip" == "true" ];then
    echo $json | jq . > $output_file
    echo '{ "ips": ['"$( echo $json | jq '.ips[] | select(.is_cdn == "false")' )"'] }' | jq '.' > $output_file_not_cdn 
    echo '{ "ips": '"$(echo $json | jq '.ips | group_by(.asn) | map(select(length > 1) | map(select(.is_cdn == "false"))) | flatten')"' }' | jq '.' > $output_file_same_asn
  fi

  if [ "$isasn" == "true" ];then
    json=$(echo $json | sed '${s/,$//}' )
    echo "$json }}" | jq . > $output_file
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
          if [ "$isasn" == "false" ];then
            echo -e "Done! \nOutPuts: $output_file - $output_file_same_asn - $output_file_not_cdn :)"
          fi
        else
          cat $opt_output | jq .
        fi
else
        echo "Done !"
fi
