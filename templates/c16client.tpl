#trace, debug, info, warn, err, error, critical, off
loglevel: '$C16LOGLEVEL'
servers:
  - hostname: 192.168.7.4
    port: 9001
    mTLS: true
    server_cert_file: "/etc/c16/$C16CATRUSTCHAIN"
    client_key_file: "/etc/c16/$C16CLIENTKEY"
    client_cert_file: "/etc/c16/$C16CLIENT"
