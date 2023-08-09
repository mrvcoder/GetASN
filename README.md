## Tools/Commands need to be installed in your machine
**Install these tools before running script !**
| tool | README |
| ------ | ------ |
| cut-cdn | [https://github.com/ImAyrix/cut-cdn] |
| dnsx | [https://github.com/projectdiscovery/dnsx] |

## what does this script do?
this script will give you these infoes :
- **ASN**: asn number of domain
- **IP**:  IPs of domain (supports ipv4 and ipv6)
- **is_cdn**: is domain/IP behind cdn or not (true or false) 
- **CIDR**: All prefex of ip (cidr)

**Please note that Script Data Source is [bgpview](https://bgpview.io/) !**

## what input types can you pass ?
- single/list of IPs
- single/list of Domains
- single/list of ASNs

And at the end you will get these outputs :
- The ORGINAL output :  `getasn_output.json`
- The output which ASNs are equal and is_cdn is false: `getasn_output_SameASN_NotCDN.json`
- The output which is_cdn is false: `getasn_output_NotCDN.json`
- Also you can create custom output name with `-o` option :)

## usage
```
usage: ./getasn.sh [options] 

options: 
        -r                  set resolvers file address [ default: ./resolvers.txt ]
        -s   -silent        silent output
        -o                  set output (only .json is ok)
        -domainlist         set domain list txt file (only .txt is ok)
        -domain             check single domain
        -iplist             set ip list txt file (only .txt is ok)
        -ip                 check single ip
        -asn                check single asn
        -asnlist            set asn list txt file (only .txt is ok)
```


## How to use this script as alias in bash !
Add this code to your `~/.bashrc`
```
alias getasn="{{getasn.sh full path}}"
```
1. replace `{{getasn.sh full path}}` with path of where is getasn.sh script is
save it and the run this code :
```
source ~/.bashrc
```

Now you can call getasn script anywhere in bash by only calling `getasn` !
And Only need to pass `[options]` 


## How to use with [notify](https://github.com/projectdiscovery/notify)
```
./getasn.sh -s -domainlist ListOfDomains.txt | notify -mf "done" -id discord
```
Good luck :)
