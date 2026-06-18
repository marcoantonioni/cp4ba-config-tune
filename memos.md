# Tuning/Config Memos

## WFPS

Configmap: <wfps-name>-liberty-dynamic-config (es: wfps-demo-1-liberty-dynamic-config)

Content sample
```
100Audit.xml
<properties>
  <server>
    <audit-config>
      <audit-enabled merge="replace">false</audit-enabled>
      <audit-version merge="replace"></audit-version>
      <audit-file-location merge="replace"></audit-file-location>
      <audit-file-name merge="replace"></audit-file-name>
      <audit-rollover-size merge="replace">0</audit-rollover-size>
      <max-historical-files merge="replace">0</max-historical-files>
    </audit-config>
  </server>
</properties>

100Portal.xml
<properties>
<server>
  <portal merge="mergeChildren">
    <authorization-enabled-for-org-info>true</authorization-enabled-for-org-info>
  </portal>
</server>
</properties>

100SCIM.xml
<properties>
  <common>
    <security>
      <scim-options merge="replace">
        <scim-user-auth-alias-name>SCIM-client-auth-alias-IAM</scim-user-auth-alias-name>
        <scim-server-host-name>platform-identity-management.cp4ba-wfps-production.svc</scim-server-host-name>
        <scim-server-port>4500</scim-server-port>
        <scim-auth-token-endpoint>https://platform-identity-provider.cp4ba-wfps-production.svc:4300/v1/auth/token</scim-auth-token-endpoint>
        <scim-server-base-url>/identity/api/v1/scim/</scim-server-base-url>
        <service-account>
            <user-name>dbp1w8fwbjfmnpir58o1dey85vq17cwl</user-name>
            <full-name>workflow process server administrator Service Account</full-name>
        </service-account>
        <service-account>
            <user-name>func-LXTTl</user-name>
            <full-name>workflow process server functional user Service Account</full-name>
        </service-account>
        <scim-client-ssl-config></scim-client-ssl-config>
        <disable-cn-check>true</disable-cn-check>
        <user-search-attribute>principalName</user-search-attribute>
        <user-name-identifier>userName</user-name-identifier>
        <user-uniquename-identifier>id</user-uniquename-identifier>
        <user-displayname-query-attr>displayName</user-displayname-query-attr>
        <user-displayname-result-attr>displayName</user-displayname-result-attr>
        <group-search-attribute>principalName</group-search-attribute>
        <group-name-identifier>name</group-name-identifier>
        <group-uniquename-identifier>id</group-uniquename-identifier>
        <group-displayname-result-attr>displayName</group-displayname-result-attr>
        <group-displayname-query-attr>displayName</group-displayname-query-attr>
      </scim-options>
    </security>
  </common>
</properties>

100UMS.xml
<properties>
  <common merge="mergeChildren">
    <security>
        <zen-auth-options>
            <zen-endpoint-url>https://internal-nginx-svc.cp4ba-wfps-production.svc:12443/v1</zen-endpoint-url>
            <zen-idprovider-endpoint-url>https://platform-identity-provider.cp4ba-wfps-production.svc:4300/v1</zen-idprovider-endpoint-url>
            <zen-ssl-config></zen-ssl-config>
            <zen-connection-timeout>360000</zen-connection-timeout>
            <zen-receive-timeout>360000</zen-receive-timeout>
            <zen-connection-pool-size>20</zen-connection-pool-size>
            <disable-cn-check>false</disable-cn-check>
        </zen-auth-options>
    </security>
  </common>
</properties>

101AllowedOrigin.xml
<properties>
	<server>
		<rest merge="mergeChildren">
				<allowed-origins merge="replace">https://cpd-cp4ba-wfps-production.apps.itz-ldvw14.infra01-lb.wdc04.techzone.ibm.com</allowed-origins>
		</rest>
	</server>
</properties>

101Envtype.xml
<properties>
  <server>
    <server-name merge="replace">wfps-demo-1</server-name>
    <server-description merge="replace">This is Workflow Process Services container server wfps-demo-1</server-description>
    <environment-type merge="replace">Production</environment-type>
  </server>
</properties>

baijvm.options
-DuseBAIBridgeEvents=true

datasource.xml
<server>
  <library id="postgresqlJDBCLib">
        <fileset dir="/shared/resources/jdbc/postgresql" includes="*"/>
  </library>
  <dataSource commitOrRollbackOnCleanup="commit" id="jdbc/TeamWorksDB" isolationLevel="TRANSACTION_READ_COMMITTED" jndiName="jdbc/TeamWorksDB" type="javax.sql.XADataSource">
        <connectionManager maxPoolSize="200" minPoolSize="50"/>
        <jdbcDriver javax.sql.XADataSource="org.postgresql.xa.PGXADataSource" libraryRef="postgresqlJDBCLib" />
        <properties.postgresql
          URL="jdbc:postgresql://my-postgres-1-for-cp4ba-rw.cp4ba-wfps-production.svc.cluster.local:5432/wfpsdb1"
          user="${db_user}" password="${db_password}" currentSchema="wfpsdb" />
  </dataSource>

  <transaction recoverOnStartup="true" waitForRecovery="false" heuristicRetryInterval="10" transactionLogDBTableSuffix="${tran_log_suffix}" recoveryGroup="recover-group-wfps-demo-1" recoveryIdentity="_RI${tran_log_suffix}">
    <dataSource transactional="false">
      <jdbcDriver libraryRef="postgresqlJDBCLib"/>
      <properties.postgresql URL="jdbc:postgresql://my-postgres-1-for-cp4ba-rw.cp4ba-wfps-production.svc.cluster.local:5432/wfpsdb1" user="${db_user}" password="${db_password}" currentSchema="wfpsdb" />
    </dataSource>
  </transaction>
</server>

def-application.xml
<server>
  
  <jmsQueueConnectionFactory jndiName="jms/defEventQueueCF" id="defEventQueueCF" connectionManagerRef="defConMgr" containerAuthDataRef="JMSAuthAlias">
    <properties.wasJms remoteServerAddress="${jms_server_host}:${jms_server_ssl_port}:BootstrapSecureMessaging"/>
  </jmsQueueConnectionFactory>
  <connectionManager id="defConMgr" maxPoolSize="50" connectionTimeout="180s" minPoolSize="1" reapTime="180s" />
  
  <enterpriseApplication id="defconfig" location="${wlp.install.dir}/ibmProcessServer/applications/def-liberty-config.ear" name="defconfig">
    <classloader commonLibraryRef="TeamworksLib"/>
  </enterpriseApplication>
  
  <library id="DEFConfigLib1">
      <fileset dir="${wlp.install.dir}/ibmProcessServer/lib/plugins" includes="com.ibm.bpm.def.config.jar" />
  </library>
  <jmsQueue jndiName="jms/defeventqueue" id="DefEventDestination">
      <properties.wasJms queueName="DefEventDestination" deliveryMode="Application" readAhead="AsConnection" />
  </jmsQueue>
  <jmsActivationSpec id="jms/defEventQueueAs" authDataRef="JMSAuthAlias">
      <properties.wasJms destinationRef="DefEventDestination" maxBatchSize="10" maxConcurrency="10" remoteServerAddress="${jms_server_host}:${jms_server_ssl_port}:BootstrapSecureMessaging"/>
  </jmsActivationSpec>
  <webApplication id="BPMEventEmitter" location="${wlp.install.dir}/ibmProcessServer/applications/BPMEventEmitter.war" name="BPMEventEmitter">
      <ejb-jar-bnd>
          <message-driven name="BPMEventEmitterMDB">
              <jca-adapter activation-spec-binding-name="jms/defEventQueueAs" destination-binding-name="jms/defeventqueue" />
          </message-driven>
      </ejb-jar-bnd>
      <classloader commonLibraryRef="DEFConfigLib1"/>
  </webApplication>
</server>

empty-shell-script.xml
#!/bin/bash
jvm.options
-Djdk.nativeDigest=false
-Dio.openliberty.saaj.disableDuplicateNS=true
liberty-basic-auth.xml

<server>
    <trustAssociation id="basicAuthTrustAssociation" invokeForUnprotectedURI="false" failOverToAppAuthType="false">
        <interceptors id="basicAuthTAI" enabled="true" className="com.ibm.dba.ums.wlp.tai.BasicAuthenticationTAI" invokeBeforeSSO="true" invokeAfterSSO="false" libraryRef="basicAuthTAI">
            <properties
            
              zenValidateAuthEndpointUrl="https://internal-nginx-svc.cp4ba-wfps-production.svc:12443/v1/preauth/validateAuth"
              tokenEndpointUrl="https://platform-identity-provider.cp4ba-wfps-production.svc:4300/v1/auth/identitytoken"
            
              clientDisableCnCheck="ture"/>
              cacheSize="100"
            />
        </interceptors>
    </trustAssociation>
    <library id="basicAuthTAI">
        <fileset dir="${wlp.install.dir}/ibmProcessServer/lib/BPM/Lombardi/lib" includes="com.ibm.dba.ums.wlp.tai.jar"/>
    </library>
</server>

liberty-custom.xml

liberty-empty.xml
<server></server>

liberty-jaas.xml
<server>
  <library id="umsJaasLoginLib">
      <fileset dir="${wlp.install.dir}/ibmProcessServer/lib/BPM/Lombardi/lib" includes="com.ibm.dba.ums.jaaslogin.jar"/>
  </library>
  <jaasLoginModule id="umsJaasLogin" className="com.ibm.dba.ums.security.authentication.jaas.modules.UMSLoginModule" controlFlag="REQUIRED" libraryRef="umsJaasLoginLib">
    <options
    
      zenValidateAuthEndpointUrl="https://internal-nginx-svc.cp4ba-wfps-production.svc:12443/v1/preauth/validateAuth"
      tokenEndpointUrl="https://platform-identity-provider.cp4ba-wfps-production.svc:4300/v1/auth/identitytoken"
    
      disableCnCheck="true"/>
  </jaasLoginModule>
  <jaasLoginContextEntry id="umsJaasContext" name="umsJaasContext" loginModuleRef="umsJaasLogin, hashtable"/>
</server>

liberty-logging.xml
<server>
  <logging consoleFormat="json"
    consoleLogLevel="INFO"
    consoleSource="message,trace,accessLog,ffdc,audit"
    traceFormat="ENHANCED"
    traceSpecification="*=info"
    messageFormat="simple"
	  maxFiles="10"
    maxFileSize="50"/>
</server>

liberty-virtual-hosts.xml
<server>
  <virtualHost id="default_host">
    <hostAlias>${external_hostname}:${external_https_port}</hostAlias>
    <hostAlias>${external_hostname}:443</hostAlias>
    <hostAlias>${external_hostname}</hostAlias>
    <hostAlias>localhost:9443</hostAlias>
    <hostAlias>127.0.0.1:9443</hostAlias>
    <hostAlias>localhost:443</hostAlias>
    <hostAlias>127.0.0.1:443</hostAlias>
    <hostAlias>wfps-demo-1-wfps-service:9443</hostAlias>
    <hostAlias>wfps-demo-1-wfps-service.cp4ba-wfps-production:9443</hostAlias>
    <hostAlias>wfps-demo-1-wfps-service.cp4ba-wfps-production.svc:9443</hostAlias>
    <hostAlias>wfps-demo-1-wfps-service.cp4ba-wfps-production.svc.cluster.local:9443</hostAlias>
  </virtualHost>
</server>

liberty-zen-jwt-client.xml
<server>
  <featureManager>
    <feature>openidConnectClient-1.0</feature>
  </featureManager>
  
  <openidConnectClient id="zenJWT"
    inboundPropagation="required"
    jwkEndpointUrl="https://internal-nginx-svc.cp4ba-wfps-production.svc:12443/auth/jwks"
    signatureAlgorithm="RS256"
    issuerIdentifier="KNOXSSO"
    uniqueUserIdentifier="username"
    groupIdentifier="permissions"
    audiences="DSX"
    tokenReuse="true"
    realmName="jwtrealm">

    <authFilter>
      <requestHeader id="allowBasicAuth" matchType="notContain" name="Authorization" value="Basic" />
    </authFilter>
  </openidConnectClient>
</server>

liberty-zz-customization.xml
<server>
  <include optional="true" location="/opt/ibm/wlp/usr/shared/resources/sensitive-custom/sensitiveCustom.xml" />
  <include optional="true" location="/opt/ibm/wlp/usr/shared/resources/config/custom.xml" />
</server>

lombardi-empty.xml
<properties></properties>

workflow-custom.xml
```
