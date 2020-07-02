# ecHome Kubernetes Launcher

Dockerfile and small set of scripts that automatically launches a Kubernetes cluster in an ecHome server. The image is built upon ubuntu:18.04 and install Python3, Ansible, the [ecHome-cli](https://github.com/mgtrrz/echome-cli) and [Kubespray](https://github.com/kubernetes-sigs/kubespray)

Although limited in functionality for testing, the idea is that this will become a function in ecHome to be able to launch a k8s environment.  In the future, this will use a python script with the echome-sdk and would be more customizable in addition to using pre-configured images instead of Kubespray through ansible to set them up.

## Building and running

In this scripts current configuration:

Copy the `echome_env.list.template` file to `echome_env.list` and fill in the variables. Modify `inventory.ini` with the desired local network IPs that the instances will use. These VMs should not exist and the IP addresses should be available as the init.sh script will automatically create the VMs with these IPs.

Modify `k8s-cluster.yml` to optionally include or remove any features.

Run the following commands locally on your computer (assumed linux/mac):

```
docker build --tag k8s-deployer:0.1.0 .

docker run --env-file echome_env.list -i k8s-deployer:0.1.0
```