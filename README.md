# **Get-ComputerrInfoByIP**
This Script retrieves computer information from Active Directory using an IP address.
The Script uses the following functions:
* Get-DNSHashTable 
* Get-ComputerInfoFromIpAddress

## *Get-DNSHashTable*
This function retrieves the DNS records from the DNS server and creates a hashtable with the IP address as the key and the computer name as the value.
The function accepts the following parameters:

* DNSZoneName (string) The name of the DNS zone to retrieve records from. If not specified, the current AD domain's DNS root is used.
* DNSServer (string) The name of the DNS server to retrieve records from. If not specified, a domain controller in the closest site is used.

## *Get-ComputerInfoFromIpAddress*
This function receives an IP address of the computer and retrieves the computer information from Active Directory.
The function can receive multiple IP addresses, can be piped from another command, and will only return valid IP addresses.


The function returns a PowerShell custom object with the following properties:
* Name (string): The name of the computer in Active Directory.
* DNSHostName (string): The DNS hostname of the computer.
* OperatingSystem (string): The operating system of the computer.
* PasswordLastSet (datetime): The date and time the password wlast set.
* LastLogonDate (datetime): The date and time the computer lalogged on to the domain.

