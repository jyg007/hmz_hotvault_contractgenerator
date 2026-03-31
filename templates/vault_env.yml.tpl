type: env
host-attestation: 
  HKD-$MACHINE1:
    description:  $MACHINE1_DESCRIPTION
    host-key-doc: $MACHINE1_HKD_B24
  HKD-$MACHINE2:
    description:  $MACHINE2_DESCRIPTION
    host-key-doc: $MACHINE2_HKD_B24
crypto-pt: 
  lock: false
  index-1:
    type: secret
    domain-id: "$HSMDOMAIN1"
    secret: $SECRET_B24
    mkvp: $MKVP  
auths:
  "$REGISTRY_URL":
    password: "$REGISTRY_PASSWORD"
    username: "$REGISTRY_USERNAME"
cacerts:
- certificate: "$REGISTRY_CA"
logging:
  syslog:
    hostname: "$SYSLOG_IP"
    port: $SYSLOG_PORT
    server: | 
$SYSLOG_SERVER_CERT
    cert: | 
$SYSLOG_CLIENT_CERT
    key: |
$SYSLOG_CLIENT_KEY
