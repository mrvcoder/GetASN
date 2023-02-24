## Tools/Commands need to be installed in your machine
| tool | README |
| ------ | ------ |
| mapcidr | [https://github.com/projectdiscovery/mapcidr] |
| httpx | [https://github.com/projectdiscovery/httpx]|

## Usage

first of all to use this please edit bash file with any text-editor you like and set your "YOUR_API_KEY" of https://ipdata.co and then you are good to go :)
```
usage: ./getasn.sh [options] ListOfDomains.txt 
options:
  -l => get all live ips of asns that find with this tool
example
./getasn.sh -l ListOfDomains.txt
./getasn.sh  ListOfDomains.txt
```
