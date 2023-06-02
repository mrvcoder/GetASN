## Tools/Commands need to be installed in your machine
| tool | README |
| ------ | ------ |
| cut-cdn | [https://github.com/ImAyrix/cut-cdn] |
| dnsx | [https://github.com/projectdiscovery/dnsx] |

## what does this script do?
this script will give you these infoes :
- **ASN**: asn number of domain
- **IP**: IPs of domain (supports ipv4 and ipv6)
- **is_cdn**: is domain behind cdn or not (true or false) 
- **CIDR**: prefex of ip (cidr)

And at the end you will get these outputs :
- The ORGINAL output :  `getasn_output.json`
- The output which ASNs are equal and is_cdn is false: `getasn_output_SameASN_NotCDN.json`
- The output which is_cdn is false: `getasn_output_NotCDN.json`

## usage
```
usage: ./getasn.sh [options] ListOfDomains.txt

options: 
 -d Set txt resolvers file address 
```
**It is Important to use options before ListOfDomains file !**

## How to use this script as alias in bash !
Add this code to your `~/.bashrc`
```
getasn() {
bash {{getasn.sh path}} -d {{GetASN folder path}}/resolvers.txt "$1"
}
```
1. replace `{{getasn.sh path}}` with path of where is getasn.sh script is
2. replace `{{GetASN folder path}}` with path of where is GetASN folder 
save it and the run this code :
```
source ~/.bashrc
```

Now you can call getasn script anywhere in bash !
And Only need to pass ListOfDomains file. If you need to change resolvers just go to project folder and edit `resolvers.txt` file


## How to use with [notify](https://github.com/projectdiscovery/notify)
```
./getasn.sh -s ListOfDomains.txt | notify -mf "done" -id discord
```
Good luck :)
