#!/bin/bash

[ -d vault ] || mkdir vault
. ./terraform.tfvars

sed -e 's/<<-EOT/$(cat <<-EOT /' -e 's/^EOT/EOT\n)/' ./terraform.tfvars > ./o.$$ 

for i in IMAGE SYSLOG REGISTRY MACHINE2 MACHINE2_DESCRIPTION MACHINE2_HKD_B24 HSMDOMAIN2 MACHINE1 MACHINE1_DESCRIPTION MACHINE1_HKD_B24 HSMDOMAIN1 SECRET_B24 MKVP HPCR_CERT DATA
do
  sed -i "s/^$i/export $i/" ./o.$$
done

. ./o.$$

sed -e "s#VAULTID#${VAULTID}#" -e "s#NOTARYPUBKEY#${NOTARYPUBKEY}#" -e "s#HMZ_SERVER#${HMZ_SERVER}#" -e "s#IMAGEVAULT#${REGISTRY_URL}/${IMAGEVAULT}#" -e "s#IMAGEKMS#${REGISTRY_URL}/${IMAGEKMS}#"  -e "s#IMAGEGREP11#${REGISTRY_URL}/${IMAGEGREP11}#" -e "s#IMAGENGINX#${REGISTRY_URL}/${IMAGENGINX}#"   templates/play.yaml.template > vault/play.yaml

rm -f ./o.$$

ENV=`pwd`/vault_env.yml
envsubst < templates/vault_env.yml.tpl > $ENV
sed -i '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/ s/^/      /' $ENV
sed -i '/-----BEGIN PRIVATE KEY-----/,/-----END PRIVATE KEY-----/ s/^/      /' $ENV


echo "system = onprem" > vault/ibm.cfg
echo "endpoint = localhost:9876" >> vault/ibm.cfg

####################################################################################o#
################ GREP11 cert generation

######################################################################################
################ GREP11 cert generation
pushd templates/grep11 > /dev/null
./gen.sh 
popd > /dev/null

sed -e "s/HSMDOMAIN/$HSMDOMAIN1/" -e "s/EP11SERVERPORT/10876/" templates/grep11server.tpl > templates/grep11/grep11srv/grep11server1.yaml
sed -e "s/HSMDOMAIN/$HSMDOMAIN2/" -e "s/EP11SERVERPORT/11876/" templates/grep11server.tpl > templates/grep11/grep11srv/grep11server2.yaml
cp -r templates/grep11/grep11srv vault/
cp -r templates/grep11/grep11nginx vault/
cp -r templates/grep11/cfg vault/c16cfg

mkdir vault/vaultcert
mv templates/grep11/grep11server.pem vault/grep11srv
mv templates/grep11/grep11server-key.pem vault/grep11srv
mv templates/grep11/grep11client-key.pem vault/vaultcert/client-key.pem
mv templates/grep11/grep11client.pem vault/vaultcert/client.pem
cp templates/grep11/grep11ca.pem vault/vaultcert/ca.pem
mv templates/grep11/grep11ca.pem vault/grep11srv
######################################################################################
######################################################################################

export COMPOSE=`tar -cz -C vault/ . | base64 -w0`
WORKLOAD=`pwd`/vault_workload.yml
envsubst < templates/vault.yml.tpl > $WORKLOAD

CONTRACT_KEY=.ibm-hyper-protect-container-runtime-encrypt.crt
envsubst < hpcr_contractkey.tpl > $CONTRACT_KEY

PASSWORD=`openssl rand -base64 32`
ENCRYPTED_PASSWORD="$(echo -n "$PASSWORD" | base64 -d | openssl pkeyutl -encrypt -pubin -inkey <(openssl x509 -in $CONTRACT_KEY -pubkey -noout) |  base64 -w0)"
ENCRYPTED_WORKLOAD="$(echo -n "$PASSWORD" | base64 -d | openssl enc -aes-256-cbc -pbkdf2 -pass stdin -in "$WORKLOAD" | base64 -w0)"
echo "workload: hyper-protect-basic.${ENCRYPTED_PASSWORD}.${ENCRYPTED_WORKLOAD}" > user-data



PASSWORD=`openssl rand -base64 32`
ENCRYPTED_PASSWORD="$(echo -n "$PASSWORD" | base64 -d | openssl pkeyutl -encrypt -pubin -inkey <(openssl x509 -in $CONTRACT_KEY -pubkey -noout) |  base64 -w0)"
ENCRYPTED_ENV="$(echo -n "$PASSWORD" | base64 -d | openssl enc -aes-256-cbc -pbkdf2 -pass stdin -in "$ENV" | base64 -w0)"
echo "env: hyper-protect-basic.${ENCRYPTED_PASSWORD}.${ENCRYPTED_ENV}" >> user-data


echo "local-hostname: vault" > meta-data
echo "local-machineid: "$(echo "vault" | md5sum  | cut -f1 -d " ") >> meta-data

cat >> vendor-data <<EOF
#cloud-config
users:
- default
EOF

xorriso -as mkisofs -o vaultcontract/cloud-init -V cidata -J -r user-data meta-data vendor-data

rm -fr vault
rm user-data meta-data vendor-data
rm $CONTRACT_KEY
