function Get-DNSHashTable {
    <#
        .SYNOPSIS
        Retrieves a hash table of DNS A records in a specified DNS zone.

        .DESCRIPTION
        The function retrieves all A records in the specified DNS zone and returns a hash table with the IP addresses as keys and computer names as values.
        The function excludes A records for the ForestDnsZones and DomainDnsZones partitions.
        The function can be used to retrieve all A records in the current AD domain's DNS root, or in a specified DNS zone.
        The function accepts a single parameter for the DNS zone name (which defaults to the current AD domain's DNS root if not specified).
        the function also accepts a single parameter for the DNS server to query (which defaults to the closest domain controller if not specified).

        .PARAMETER DNSZoneName
        The name of the DNS zone to retrieve records from. If not specified, the current AD domain's DNS root is used.

        .PARAMETER DNSServer
        The name of the DNS server to retrieve records from. If not specified, a domain controller in the closest site is used.

        .EXAMPLE
         Get-DNSHashTable -DNSZoneName "example.com"

         Retrieves a hash table of all A records in the "example.com" DNS zone.

        .EXAMPLE
         Get-DNSHashTable -DNSZoneName "example.com" -DNSServer "dns.example.com"
        
         Retrieves a hash table of all A records in the "example.com" DNS zone from the DSN server "dns.example.com".

        .EXAMPLE
         Get-DNSHashTable
         Retrieves a hash table of all A records in the DomainName DNS zone from the closest domain controller.

        .OUTPUTS
        The function returns a hash table with the IP addresses as keys and computer names as values.


        .NOTES
        Author: Gadi Lev-Ari
        Last Updated: 25/02/2023
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidatePattern("^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$")]
        [string]$DNSZoneName = (Get-ADDomain).DNSRoot,
        [string]$DNSServer = [string](Get-ADDomainController -Discover -NextClosestSite).hostname
    )

    $records = Get-DnsServerResourceRecord -ZoneName $DNSZoneName -ComputerName $DNSServer -RRType A | Where-Object { $_.HostName -ne "@" }
    $records = $records | Where-Object {($_.HostName -ne 'ForestDnsZones') -and ($_.HostName -ne 'DomainDnsZones')}
    
    $hash = @{}
    
    foreach ($record in $records) {
        $name = $record.HostName
        $ip = $record.RecordData.Ipv4Address.IPAddressToString

        if ($hash.ContainsKey($ip)) {
            $hash[$ip] += ",$name"
        } else {
            $hash[$ip] = $name
        }
    }
    
    Write-Output $hash
}

function Get-ComputerInfoFromIpAddress {
    <#
        .SYNOPSIS
         This function retrieves computer information from Active Directory using an IP address.
        
        .DESCRIPTION
         This function receives an IP address of the computer and retrieves the computer information from Active Directory.
         The function can receive multiple IP addresses, can be piped from another command, and will only return valid IP addresses.
        
        .PARAMETER IPAddress
         The IP address of the computer which we would like to query. Can receive multiple IP addresses and be piped from another command.
        
        .EXAMPLE
         Get-ComputerInfoFromIpAddress -IPAddress '10.0.0.83'
         Returns a PowerShell custom object with the name of the computer, the DNS host name and the operatingsystem

         Name            : CDC2
         DNSHostName     : CDC2.contoso.local
         OperatingSystem : Windows Server 2022 Standard
         PasswordLastSet : 2/21/2023
         LastLogonDate   : 2/21/2023
        
        .EXAMPLE
         '10.0.0.83', '10.0.0.85' | Get-ComputerInfoFromIpAddress
         Returns a PowerShell custom object for each IP address, excluding invalid IP addresses.

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

        .OUTPUTS
         The function returns a PowerShell custom object with the following properties:
         - Name (string): The name of the computer in Active Directory.
         - DNSHostName (string): The DNS hostname of the computer.
         - OperatingSystem (string): The operating system of the computer.
         - PasswordLastSet (datetime): The date and time the password was last set.
         - LastLogonDate (datetime): The date and time the computer last logged on to the domain.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, 
            Position = 0, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
                if (-not [System.Net.IPAddress]::TryParse($_, [ref]$null)) {
                    throw "Invalid IP address: $_"
                }
                $true
            })]
        [string[]]$IPAddress
    )

    #Requires -Modules ActiveDirectory
    
    Begin {
        $DNSHashTable = Get-DNSHashTable
    }
    process {
        # Ensure the Active Directory PowerShell module is loaded
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory
        }

        # Load A  records into an array in memory
        $DNSHashTable = Get-DNSHashTable

        foreach ($ip in $IPAddress) {
            $ComputerName = $dnsHashTable[$ip]
            if (-not $ComputerName) {
                Write-Warning "Could not resolve $ip"
                continue
            }
            if($ComputerName.contains(',')) {
                Write-Verbose "The IP provided has more that one record: $ComputerName"
                $ComputerName = $ComputerName.split(',')
            }
            foreach($entry in $computerName) {
                try {
                    $computer = Get-ADComputer -Identity $entry -Properties OperatingSystem, pwdlastset, lastlogondate -ErrorAction SilentlyContinue
                } catch {
                    $computer = $null
                }
                if ($computer) {
                    $result = [PSCustomObject]@{
                        Name            = $computer.Name
                        DNSHostName     = $computer.DNSHostName
                        OperatingSystem = $computer.OperatingSystem
                        PasswordLastSet = ([datetime]::FromFileTimeUtc($computer.pwdlastset)).ToShortDateString()
                        LastLogonDate   = ($computer.lastlogondate).ToShortDateString()
                        }
                    Write-Output $result
                } else {
                    Write-Warning "Could not find computer with the name of $entry in Active Directory"
                }
            }
        }
    }
}

<# Example usage
    Get-ComputerInfoFromIpAddress -IPAddress '10.0.0.83'

    '10.0.0.83', '10.0.0.85' | Get-ComputerInfoFromIpAddress
    
    Get-Content -Path .\Computers.txt | Get-ComputerInfoFromIpAddress

    **Using the Import-Csv command to import a CSV file with a column named "IPAddress".**
    Import-Csv -Path  .\Computers.csv | Get-ComputerInfoFromIpAddress 
#>