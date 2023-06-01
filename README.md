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
