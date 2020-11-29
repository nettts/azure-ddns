#!/bin/bash
# Script to update a record in Azure DNS to match the current public IP address


# Tenant ID
tenantId="YOUR TENANT ID"
# Azure AD App ID
appId="YOUR APP ID"
# Azure AD App Secret
appSecret="YOUR APP SECRET"
# Azure resource group name where your DNS zone is configured
rgName="YOUR RESOURCE group"
# DNS zone name
zoneName="YOUR DNS ZONE TO UPDATE"
# Existing A record-set name in your DNS zone
recordsetName="YOUR RECORD TO UPDATE"
# Prefix that will be searched to verify whether you are on the right network

# FQDN
fqdn=$recordsetName.$zoneName

# Verify 'dig' is there
digPath=$(which dig)
if [[ -z $digPath ]]
then
    echo "dig does not seem to be installed, but it is required for this script"
    exit 1
fi

# Verify 'ip' is there
ipPath=$(which ip)
if [[ -z $ipPath ]]
then
    echo "ip does not seem to be installed, but it is required for this script"
    exit 1
fi

# Get public IP from akamai
myPublicIpv4=$(curl http://whatismyip.akamai.com/)
myPublicIpv6=$(curl http://ipv6.whatismyip.akamai.com/)
echo "The current IPv4 IP is $myPublicIpv4"
echo "The current IPv6 IP is $myPublicIpv6"

# Get existing public IP from DNS
myDnsIpv4=$(dig +short @8.8.8.8 $fqdn A)
myDnsIpv6=$(dig +short @8.8.8.8 $fqdn AAAA)

if [ $myPublicIpv4 == $myDnsIpv4 ]
then
    echo "DNS IPv4 up to date, nothing to be done"
else
    echo "Current public IP address $myPublicIpv4 different from DNS IP address $myDnsIpv4, proceeding to update DNS"
    # Login to Azure
    az login --service-principal --tenant $tenantId --username $appId --password $appSecret >/dev/null 2>&1
    # Configure default resource group to rgName
    az configure --defaults group=$rgName >/dev/null 2>&1
    # Remove old record from record-set
    az network dns record-set a remove-record -n $recordsetName -z $zoneName --ipv4-address $myDnsIpv4 >/dev/null 2>&1
    # Add new record to the record-set
    az network dns record-set a add-record -n $recordsetName -z $zoneName --ipv4-address $myPublicIpv4 --ttl 60 >/dev/null 2>&1
    sleep 120
    newDnsIpv4=$(dig +short @8.8.8.8 $fqdn A)
    if [ $myPublicIpv4 == $newDnsIpv4 ]
    then
        echo "DNS A record correctly updated and verified"
    else
        echo "DNS A record updated, the verification was not successful yet, verify with the commnad 'nslookup $fqdn' in a few minutes/hours"
    fi
    # Bye!
    az logout
fi

if [ $myPublicIpv6 == $myDnsIpv6 ]
then
    echo "DNS IPv6 up to date, nothing to be done"
else
    echo "Current public IPv6 address $myPublicIpv6 is different from DNS IP address $myDnsIpv6. Updating DNS"
    # Login to Azure
    az login --service-principal --tenant $tenantId --username $appId --password $appSecret >/dev/null 2>&1
    # Configure default resource group to rgName
    az configure --defaults group=$rgName >/dev/null 2>&1
    # Remove old record from record-set
    az network dns record-set aaaa remove-record -n $recordsetName -z $zoneName --ipv6-address $myDnsIpv6 >/dev/null 2>&1
    # Add new record to the record-set
    az network dns record-set aaaa add-record -n $recordsetName -z $zoneName --ipv6-address $myPublicIpv6 --ttl 60 >/dev/null 2>&1
    sleep 120
    newDnsIpv6=$(dig +short @8.8.8.8 $fqdn AAAA)
    if [ $myPublicIpv6 == $newDnsIpv6 ]
    then
        echo "DNS AAAA correctly updated and verified"
    else
        echo "DNS AAAA updated, the verification was not successful yet, verify with the commnad 'nslookup $fqdn' in a few minutes/hours"
   fi
   # Bye!
   az logout
fi
