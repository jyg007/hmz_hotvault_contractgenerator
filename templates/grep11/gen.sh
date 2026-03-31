#!/bin/bash
#
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2024
#
# The source code for this program is not published or otherwise
# divested of its trade secrets, irrespective of what has been
# deposited with the U.S. Copyright Office
#

# CA
openssl genrsa  -out grep11ca-key.pem 4096 2>/dev/null
openssl req  -config ca.cnf -key grep11ca-key.pem -new -out grep11ca-req.csr 
openssl x509  -signkey grep11ca-key.pem -in grep11ca-req.csr -req -days 7300 -extfile ca.cnf -extensions v3_ca  -out grep11ca.pem 2>/dev/null


# Server
openssl genrsa  -out grep11server-key.pem 4096 2>/dev/null
openssl req   -config server.cnf -key grep11server-key.pem -new -out grep11server-req.csr
openssl x509  -in grep11server-req.csr -req -days 7300 -CA grep11ca.pem -CAkey grep11ca-key.pem -CAcreateserial -extfile server.cnf -extensions grep11server -out grep11server.pem 2>/dev/null


# Client
openssl req  -config client.cnf -newkey rsa:4096 -nodes -keyout grep11client-key.pem -new -out grep11client.csr 2>/dev/null
openssl x509  -req -in grep11client.csr -days 7300 -CA grep11ca.pem -CAkey grep11ca-key.pem -CAcreateserial -out grep11client.pem 2>/dev/null


