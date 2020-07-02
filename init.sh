#!/bin/bash
timestamp=$(date +%s)

echo "Running ecHome Kubernetes deployment"

pwd

# Create the ssh key and save it locally
echo "Creating SSH key.."
keyname="kubedeploy-${timestamp}"
echome sshkeys create --file ./${keyname}.pem ${keyname}
chmod 400 ./${keyname}.pem

# Launch the VMs with the new SSH keys
i=1
echo "Creating VMs.."
for ip in $(echo $IP_ADDRESSES); do
    echo "Creating VM ${i}"
    echome vm create --image-id ${IMAGE_ID} \
        --instance-size ${INSTANCE_SIZE} \
        --network-type ${NETWORK_TYPE} \
        --private-ip ${ip}/24 \
        --gateway-ip ${GATEWAY_IP} \
        --key-name ${keyname} \
        --disk-size ${DISK_SIZE} \
        --tags "{\"Name\": \"kubernetes-${i}\"}"
    i=$((i+1))
done

echo "Waiting for hosts to come up.."
sleep 30

cd /ansible/playbooks/kubespray
cp -rfp inventory/sample inventory/cluster
rm -f inventory/cluster/inventory.ini inventory/cluster/group_vars/k8s-cluster/k8s-cluster.yml
cp -fp /ansible/playbooks/inventory.ini inventory/cluster/inventory.ini
cp -fp /ansible/playbooks/k8s-cluster.yml inventory/cluster/group_vars/k8s-cluster/k8s-cluster.yml

echo "Running ansible playbook.."
ansible-playbook -i inventory/cluster/inventory.ini  --become cluster.yml --private-key ./${keyname}.pem

echo 
echo "Save this key! You will need to use it to log in to your Kubernetes instances."
echo
cat ./${keyname}.pem