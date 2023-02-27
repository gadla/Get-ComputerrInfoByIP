# *Get-ComputerInfoByIP*
The *Get-ComputerInfoByIP* PowerShell script retrieves computer information from Active Directory using one or more IP addresses. 
It can handle piped input and returns only valid IP addresses. 
The script doesn't use WMI or CIM cmdlets and can retrieve information even if the computer is offline. 
The script uses the DNS server to retrieve the computer name from the IP address and then retrieves the computer information from Active Directory. 
If a reverse lookup zone exists in Active Directory, it will not be used. 
The script loads the DNS records from the DNS server and creates a hashtable with the IP address as the key and the computer name as the value.

## *Here are some examples of the script in action:*

### Example 1: Get computer information from a single IP address
```powershell
Get-ComputerInfoFromIpAddress -IPAddress 10.0.0.73

Name            : CW2003
DNSHostName     : cw2003.contoso.local
OperatingSystem : Windows Server 2003
PasswordLastSet : 2/25/2023
LastLogonDate   : 2/25/2023
```
### Example 2: Get computer information from a single IP address
```powershell

'10.0.0.83', '10.0.0.85' | Get-ComputerInfoFromIpAddress

Name            : CDC2
DNSHostName     : CDC2.contoso.local
OperatingSystem : Windows Server 2022 Standard
PasswordLastSet : 2/21/2023
LastLogonDate   : 2/21/2023

Name            : WIN10
DNSHostName     : win10.contoso.local
OperatingSystem : Windows 10 Enterprise LTSC
PasswordLastSet : 1/26/2023
LastLogonDate   : 2/19/2023
```

**Functions**

The Get-ComputerInfoByIP script uses the following functions:

---
**Get-DNSHashTable**

This function retrieves the DNS records from the DNS server and creates a hashtable with the IP address as the key and the computer name as the value. The function accepts the following parameters:

- DNSZoneName (string): The name of the DNS zone to retrieve records from. If not specified, the current AD domain's DNS root is used.
- DNSServer (string): The name of the DNS server to retrieve records from. If not specified, a domain controller in the closest site is used.


**Get-ComputerInfoFromIpAddress**

This function receives an IP address of the computer and retrieves the computer information from Active Directory. The function can handle multiple IP addresses and piped input and returns only valid IP addresses.

The function returns a PowerShell custom object with the following properties:

- Name (string): The name of the computer in Active Directory.
- DNSHostName (string): The DNS hostname of the computer.
- OperatingSystem (string): The operating system of the computer.
- PasswordLastSet (datetime): The date and time the password was last set.
- LastLogonDate (datetime): The date and time the computer last logged on to the domain.

