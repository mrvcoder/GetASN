## future featurs (Todos)
- [x] Get all ipv6 of domain 👀
- [x] before running scan , calculate api keys limit  👀

## Tools/Commands need to be installed in your machine
| tool | README |
| ------ | ------ |
| mapcidr | [https://github.com/projectdiscovery/mapcidr] |
| httpx | [https://github.com/projectdiscovery/httpx]|

## what does this script do?
this script will give you these infoes :
- **ASN**: asn number of domain
- **IP**: ipv4s of domain (get from dig)
- **is_cdn**: is domain behind cdn or not (true or false) 

And at the end you will get these outputs :
- The ORGINAL output :  `getasn_output.json`
- The output which ASNs are equal and is_cdn is false: `getasn_output_SameASN_NotCDN.json`
- The output which is_cdn is false: `getasn_output_NotCDN.json`

## Usage
first of all to use this please edit bash file with any text-editor you like and set your "YOUR_API_KEY" of https://ipdata.co and then you are good to go :)

**‼ Also you can set multiple api keys if you have more than 1500 domains to scan :)**
```
usage: ./getasn.sh [options] ListOfDomains.txt 
options:
  -l => get all live ips of asns that find with this tool
example
./getasn.sh -l ListOfDomains.txt
./getasn.sh  ListOfDomains.txt
```
