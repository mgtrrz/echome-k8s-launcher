#!/bin/bash
timestamp=$(date +%s)

echo "Waiting for hosts to come up.."
sleep 30

echo "Running ecHome Kubernetes deployment"

cd /ansible/playbooks/kubespray
cp -rfp inventory/sample inventory/cluster
rm -f inventory/cluster/inventory.ini inventory/cluster/group_vars/k8s-cluster/k8s-cluster.yml
cp -fp /ansible/playbooks/inventory.ini inventory/cluster/inventory.ini
cp -fp /ansible/playbooks/k8s-cluster.yml inventory/cluster/group_vars/k8s-cluster/k8s-cluster.yml

echo "Grabbing key from Vault.."
vault status
vault kv get -field data -field private_key ${VAULT_SVC_KEY_PATH} | ./sshkey.pem
chmod 400 ./sshkey.pem

echo "Running ansible playbook.."
ansible-playbook -i inventory/cluster/inventory.ini  --become cluster.yml --private-key ./sshkey.pem

echo "Copying admin file to Vault"
cat inventory/artifacts/admin.conf  | vault kv put ${VAULT_ADMIN_PATH} admin.conf=-