SMBOPERATORDIR=/home/sprabhu/dev/ocs/samba-operator
KUBECTL_CMD=${KUBECTL_CMD:-kubectl}
JQ_CMD=${JQ_CMD:-jq}

TMPFILE=/tmp/$$.tmp

echo Ad-server: install
cd $SMBOPERATORDIR
./tests/test-deploy-ad-server.sh
cd ..

read AD_POD_NAME AD_POD_IP < <(${KUBECTL_CMD}  get pod -o json \
	| ${JQ_CMD} -c -M '.items[] | .metadata.name + " " + .status.podIP' \
	| grep samba-ad-server \
	| tr -d "\"")
if ! [ $? -eq 0 ]
then
		echo "Error getting ad server pod IP"
		exit 1
fi

echo "AD pod IP: ${AD_POD_NAME} ${AD_POD_IP}"


# Add dc1.domain1.sink.test.localhost to the hosts section of coredns to avoid problems caused by localhost domain search
cat > "${TMPFILE}" <<EOF
data:
  Corefile: |
EOF
${KUBECTL_CMD} get cm -n kube-system coredns -o jsonpath='{ .data.Corefile }'| grep -v dc1.domain1.sink.test.localhost|sed 's/hosts {/hosts {\n       xx.xx.xx.xx dc1.domain1.sink.test.localhost/'|sed "s/xx.xx.xx.xx/${AD_POD_IP}/" |sed 's/^/    /g' >> ${TMPFILE}
${KUBECTL_CMD} patch cm -n kube-system coredns -p "$(cat "${TMPFILE}")"

# Create configMap with ca.crt
${KUBECTL_CMD} cp ${AD_POD_NAME}:/var/lib/samba/private/tls/ca.pem /tmp/ad-ca.pem
${KUBECTL_CMD} create configmap windowsad-ca-cert --from-file=/tmp/ad-ca.pem
${KUBECTL_CMD} -n rook-ceph create configmap windowsad-ca-cert --from-file=/tmp/ad-ca.pem

${KUBECTL_CMD} create -f ~/bin-kube/yaml/sambaad-ext.yaml

#${KUBECTL_CMD} exec -it ${AD_POD_NAME} -- samba-tool user add ldap-nfs --random-password
#${KUBECTL_CMD} exec -it ${AD_POD_NAME} -- samba-tool spn add host/rook-ceph-krb5-nfs ldap-nfs
#${KUBECTL_CMD} exec -it ${AD_POD_NAME} -- samba-tool domain exportkeytab /tmp/krb5.keytab --principal=host/rook-ceph-ldap-nfs
#${KUBECTL_CMD} cp ${AD_POD_NAME}:/tmp/krb5.keytab /tmp/krb5.keytab
#${KUBECTL_CMD} -n rook-ceph create secret generic keytab-host-domain1-sink-test --from-file=/tmp/krb5.keytab
