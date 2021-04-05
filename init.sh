#!/bin/bash
timestamp=$(date +%s)

echo "Waiting for hosts to come up.."
sleep 30

echo "Running ecHome Kubernetes deployment"

cd /ansible/playbooks/kubespray
cp -rfp inventory/sample inventory/cluster
rm -f inventory/cluster/inventory.ini inventory/cluster/group_vars/k8s-cluster/k8s-cluster.yml
# cp -fp /ansible/playbooks/inventory.ini inventory/cluster/inventory.ini
# cp -fp /ansible/playbooks/k8s-cluster.yml inventory/cluster/group_vars/k8s-cluster/k8s-cluster.yml

cp -fp /mnt/inventory.ini inventory/cluster/inventory.ini
cp -fp /mnt/k8s-cluster.yaml inventory/cluster/group_vars/k8s-cluster/k8s-cluster.yml

echo "Grabbing key from Vault.."
/ansible/playbooks/kubespray/vault status
/ansible/playbooks/kubespray/vault kv get -field data -field private_key ${VAULT_SVC_KEY_PATH} > ./sshkey.pem
chmod 400 ./sshkey.pem

echo "Grabbing echome service account.."
echome_key=$(/ansible/playbooks/kubespray/vault kv get -field=key ${ECHOME_SVC_CREDS})
echome_secret=$(/ansible/playbooks/kubespray/vault kv get -field=secret ${ECHOME_SVC_CREDS})

echo "Running ansible playbook.."
ansible-playbook -i inventory/cluster/inventory.ini  --become cluster.yml --private-key ./sshkey.pem

echo "Copying admin file to Vault"
cat inventory/cluster/artifacts/admin.conf | /ansible/playbooks/kubespray/vault kv put ${VAULT_ADMIN_PATH} admin.conf=-

echo "Notifying home base of complete status"
token=$(curl ${ECHOME_SERVER}${ECHOME_AUTH_LOGIN_API} -X POST --user ${echome_key}:${echome_secret} | grep 'access_token' | awk -F\" '{print $4}')

curl -X POST -H "Authorization: Bearer ${token}" "${ECHOME_SERVER}${ECHOME_MSG_API}?Destination=kube&Type=StatusUpdate&ClusterID=${CLUSTER_ID}&Status=READY"