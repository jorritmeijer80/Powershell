# Powershell
Useful powershell script

This powershell script is explained in this blog: https://www.medium.com/


## The powershell script
Before you can run the powershell script, there are a few things you need to do:


1. Login to Azure, using powershell (login-azAccount)
2. Find the subscription that you want to deploy into (get-azSubscription)
3. Select that subscription (select-azsubscription -subscription "SUBSCRIPTIONNAME")
4. Make sure you have the following created a VNET and Subnet in your subscription, that is capable of deploying the AGW into. For subnet sizing, using a /26 subnet is recommended as minium.
5. If you have a working VNET and subnets deployed into a resourcegroup of your choosing, fill the following parameters with the appropriate information:
 - Virtual Network ResourceGroup name ($VnetRGName)
 - Virtual Network Name ($VnetName)
 - SubnetName ($SubnetName)
6. The rest of the variables is really up to you. Because there might be things involved like naming convention, timeout settings etc. I will not recommend anything here. My script is based upon a single wildcard listener with a single backend and some default http settings, but feel free to edit these to your liking.
7. Special attention goes out to the WAF & SSL/TLS settings. This script will enable WAF for you and it will create a WAF policy in the same resourcegroup as the Application Gateway will be deployed in. This WAF policy is then tied to the AGW. For SSL/TLS settings I'm enabling the latest pre-configured (best-practice) policysetting.
