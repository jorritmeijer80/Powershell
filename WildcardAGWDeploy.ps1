## VARIABLES ##

$customerDomain = 'contoso.com'

# VNET and Subnet Variables (What Vnet/subnet will the AGW be deployed into)
$VnetRGName = 'CONTOSO-RG-NETWORK'
$VnetName = 'CONTOSO-VNET'
$SubnetName = 'CONTOSO-SUBNET-AGW01'

# Public IP Adress Settings
$AGWPIPName = 'CONTOSO-AGW01-PIP'
$location = 'westeurope'
$sku = 'Standard'
$IpAllocationMethod = 'Static'

# (Frontend) IPConfig names
$AGWIpconfigName = 'CONTOSO-AGW01-IPCONFIG'
$AGWFEIpconfigName = 'CONTOSO-AGW01-FRONTEND-IPCONFIG'

# BackendPool Settings
# Name and IP address
$BackendPoolName = 'CONTOSO-ACC-BACKENDPOOL'
$BackendIpAddress = '172.16.0.4'
# HTTP
$BEHTTPsettingsName = 'Contoso-Acc-HttpSettings'
$BEHTTPsettingsPort = '80'
$BEHTTPsettingsProtocol = 'Http'
# HTTPS
$BEHTTPSsettingsName = 'Contoso-Acc-HttpsSettings'
$BEHTTPSsettingsPort = '443'
$BEHTTPSsettingsProtocol = 'Https'
# GENERIC
$BECookieBasedAffinity = 'Disabled'
$BErequestTimeout = '300'

# Listener settings
# HTTP
$httpListenerName = 'wildcard.contoso.com-HTTP-PUBLIC'
$httpListenerProtocol = 'Http'
$httpListenerPort = '80'
$HostNames = '*.contoso.com'
# HTTPS
$httpsListenerName = 'wildcard.contoso.com-HTTPS-PUBLIC'
$httpsListenerProtocol = 'Https'
$httpsListenerPort = '443'
$HostNames = '*.contoso.com'

# Routing Rule settings
# HTTP
$httpRRRuleName = 'wildcard.contoso.com-HTTP-ROUTINGRULE-PUBLIC'
$httpRRRuleType = 'Basic'
# HTTPS
$httpsRRRuleName = 'wildcard.contoso.com-HTTPS-ROUTINGRULE-PUBLIC'
$httpsRRRuleType = 'Basic'

# Application Gateway SKU settings
$AGWSkuName = 'WAF_v2'
$AGWSkuTier = 'WAF_v2'
$AGWSkuCapacity = '2'

# Application Gateway Name & ResourceGroup
$AGWName = 'CONTOSO-AGW01'
$AGWRGName = 'CONTOSO-RG-AGW01'

# Certificate Settings:
$CertName = $customerDomain + '-' + 'Wildcard'
$PfxLocation = 'C:\PFX\PFXLOCATION.PFX'
$PfxPassword = 'PASSWORD'

# Firewall Settings:
$WafPolicyName = 'MyAgwPreventionPolicy'

# TLS Policy Settings:
$SslPolicyName = 'AppGwSslPolicy20170401S'

## // VARIABLES ##

## DO NOT EDIT THE SCRIPT ITSELF, ONLY THE VARIABLES ABOVE ##

### START DEPLOYMENT OF APPLICATION GATEWAY ###

# FIND VNET AND SUBNET
$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName $VnetRGName `
  -Name $VnetName

$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName

# CREATE THE PUBLIC IP
$pip = New-AzPublicIpAddress `
  -ResourceGroupName $AGWRGName `
  -Location $location `
  -Name $AGWPIPName `
  -Sku $sku `
  -AllocationMethod $IpAllocationMethod

# CREATE IPCONFIGURATIONS AND FRONTEND PORTS

$gipconfig = New-AzApplicationGatewayIPConfiguration `
  -Name $AGWIpconfigName `
  -Subnet $subnet

$fipconfig = New-AzApplicationGatewayFrontendIPConfig `
  -Name $AGWFEIpconfigName `
  -PublicIPAddress $pip

$frontendportHTTP = New-AzApplicationGatewayFrontendPort `
  -Name appGatewayFrontendPort-HTTP-PUBLIC `
  -Port 80

$frontendportHTTPS = New-AzApplicationGatewayFrontendPort `
  -Name appGatewayFrontendPort-HTTPS-PUBLIC `
  -Port 443

## CREATE THE BACKEND POOLS

$BackendAddressPool = New-AzApplicationGatewayBackendAddressPool `
  -Name $BackendPoolName `
  -BackendIpAddresses $BackendIpAddress

$poolSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name $BEHTTPsettingsName `
  -Port $BEHTTPsettingsPort `
  -Protocol $BEHTTPsettingsProtocol `
  -CookieBasedAffinity $BECookieBasedAffinity `
  -RequestTimeout $BErequestTimeout

## CREATE THE LISTENERS AND RULES

$httplistener = New-AzApplicationGatewayHttpListener `
  -Name $httpListenerName `
  -Protocol $httpListenerProtocol `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $frontendportHTTP `
  -HostNames $HostNames

$RRRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name $httpRRRuleName `
  -RuleType $httpRRRuleType `
  -HttpListener $httplistener `
  -BackendAddressPool $BackendAddressPool `
  -BackendHttpSettings $poolSettings

## CREATE FIREWALL POLICY SETTINGS & POLICY

$policySetting = New-AzApplicationGatewayFirewallPolicySetting -Mode Prevention -State Enabled -MaxRequestBodySizeInKb 100 -MaxFileUploadInMb 256
$wafPolicy = New-AzApplicationGatewayFirewallPolicy -Name $WafPolicyName -ResourceGroup $AGWRGName -Location $location -PolicySetting $PolicySetting

## CONFIGURE TLS POLICY
$Sslpolicy = New-AzApplicationGatewaySslPolicy -PolicyType Predefined -PolicyName $SslPolicyName

## CREATE THE APPLICATION GATEWAY

$sku = New-AzApplicationGatewaySku `
  -Name $AGWSkuName `
  -Tier $AGWSkuTier `
  -Capacity $AGWSkuCapacity

$appgw = New-AzApplicationGateway `
  -Name $AGWName `
  -ResourceGroupName $AGWRGName `
  -Location $location `
  -BackendAddressPools $BackendAddressPool `
  -BackendHttpSettingsCollection $poolSettings `
  -FrontendIpConfigurations $fipconfig `
  -GatewayIpConfigurations $gipconfig `
  -FrontendPorts $frontendportHTTP `
  -HttpListeners $httpListener `
  -RequestRoutingRules $RRRule `
  -Sku $sku `
  -FirewallPolicy $wafPolicy `
  -SslPolicy $Sslpolicy `
  -EnableHttp2

# UPDATE EXISTING CONFIG FOR HTTPS

# Store the Gateway into a Variable
$AppGW = Get-AzApplicationGateway -Name $AGWName -ResourceGroupName $AGWRGName

# Add the SSL certificate to the Application Gateway and store it into a variable
$passwd = ConvertTo-SecureString $PfxPassword -AsPlainText -Force
Add-AzApplicationGatewaySslCertificate -ApplicationGateway $AppGw -Name $CertName -CertificateFile $PfxLocation -Password $passwd
$AGFECert = Get-AzApplicationGatewaySslCertificate -ApplicationGateway $AppGW -Name $CertName

# Add a FrontEnd listener port on 443 and store it into a variable
Add-AzApplicationGatewayFrontendPort -ApplicationGateway $AppGw -Name $httpsListenerName -Port $httpsListenerPort
$AGFEPort = Get-AzApplicationGatewayFrontendPort -ApplicationGateway $AppGw -Name $httpsListenerName

# Save all of this into an IPconfig Object
$AGFEIPConfig = Get-AzApplicationGatewayFrontendIPConfig -ApplicationGateway $AppGw -Name $AGWFEIpconfigName

# Add a FrontEnd listener on SSL and store it into a variable
Add-AzApplicationGatewayHttpListener -ApplicationGateway $AppGW -Name $httpsListenerName -Protocol $httpsListenerProtocol -FrontendIPConfiguration $AGFEIPConfig -FrontendPort $AGFEPort -HostNames $HostNames -RequireServerNameIndication true -SslCertificate $AGFECert
$AGListener = Get-AzApplicationGatewayHttpListener -ApplicationGateway $AppGW -Name $httpsListenerName

# Get the Backend Pool
$AGBEP = Get-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGW -Name $BackendPoolName

# Configure Backend HTTP Settings and store it into a variable
Add-AzApplicationGatewayBackendHttpSettings -ApplicationGateway $AppGW -Name $BEHTTPSsettingsName -Port $BEHTTPSsettingsPort -Protocol $BEHTTPSsettingsProtocol -CookieBasedAffinity Disabled
$AGHTTPS = Get-AzApplicationGatewayBackendHttpSettings -ApplicationGateway $AppGW -Name $BEHTTPSsettingsName

# Tie it all togheter to create a Routing Rule
Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGW -Name $httpsRRRuleName -RuleType $httpsRRRuleType -BackendHttpSettings $AGHTTPS -HttpListener $AGListener -BackendAddressPool $AGBEP

# Update the Application Gateway with all these new settings
Set-AzApplicationGateway -ApplicationGateway $AppGw
