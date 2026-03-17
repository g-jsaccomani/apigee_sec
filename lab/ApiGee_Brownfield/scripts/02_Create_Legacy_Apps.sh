#!/bin/bash
set -e
cd "$(dirname "$0")/.."
APPS=("LegacyAuthApp" "LegacyPaymentApp" "LegacyInventoryApp" "LegacyCustomerApp")
BASEPATHS=("/legacy/auth" "/legacy/payment" "/legacy/inventory" "/legacy/customer")

mkdir -p scripts/apps
cd scripts/apps

for i in "${!APPS[@]}"; do
  APP_NAME=${APPS[$i]}
  BASEPATH=${BASEPATHS[$i]}
  
  mkdir -p $APP_NAME/apiproxy/proxies
  mkdir -p $APP_NAME/apiproxy/targets
  
  # Proxy config
  cat << XML > $APP_NAME/apiproxy/$APP_NAME.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<APIProxy revision="1" name="$APP_NAME">
    <Basepaths>$BASEPATH</Basepaths>
    <ConfigurationVersion majorVersion="4" minorVersion="0"/>
    <CreatedAt>1625097600000</CreatedAt>
    <Description>Vulnerable Legacy App for Brownfield ($APP_NAME)</Description>
    <DisplayName>$APP_NAME</DisplayName>
    <LastModifiedAt>1625097600000</LastModifiedAt>
    <Policies/>
    <ProxyEndpoints>
        <ProxyEndpoint>default</ProxyEndpoint>
    </ProxyEndpoints>
    <Resources/>
    <Spec></Spec>
    <TargetServers/>
    <TargetEndpoints>
        <TargetEndpoint>default</TargetEndpoint>
    </TargetEndpoints>
</APIProxy>
XML

  # Proxy Endpoint
  cat << XML > $APP_NAME/apiproxy/proxies/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ProxyEndpoint name="default">
    <Description/>
    <FaultRules/>
    <PreFlow name="PreFlow">
        <Request/>
        <Response/>
    </PreFlow>
    <PostFlow name="PostFlow">
        <Request/>
        <Response/>
    </PostFlow>
    <Flows/>
    <HTTPProxyConnection>
        <BasePath>$BASEPATH</BasePath>
        <Properties/>
        <VirtualHost>default</VirtualHost>
    </HTTPProxyConnection>
    <RouteRule name="default">
        <TargetEndpoint>default</TargetEndpoint>
    </RouteRule>
</ProxyEndpoint>
XML

  # Target Endpoint
  cat << XML > $APP_NAME/apiproxy/targets/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<TargetEndpoint name="default">
    <Description/>
    <FaultRules/>
    <PreFlow name="PreFlow">
        <Request/>
        <Response/>
    </PreFlow>
    <PostFlow name="PostFlow">
        <Request/>
        <Response/>
    </PostFlow>
    <Flows/>
    <HTTPTargetConnection>
        <Properties/>
        <URL>https://httpbin.org</URL>
    </HTTPTargetConnection>
</TargetEndpoint>
XML

  # Zip it
  cd $APP_NAME
  zip -r ${APP_NAME}.zip apiproxy > /dev/null
  cd ..
done
echo "4 new apps created and zipped!"
