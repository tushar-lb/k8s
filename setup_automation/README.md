How to use this (Setup Instructions):

- Make your servers ready (one master node and multiple worker nodes).

- Make an entry of your each hosts in /etc/hosts file for name resolution.

- Make sure kubernetes master node and other worker nodes are reachable between each other.

- Internet connection must be enabled in all nodes, required packages will be downloaded from kubernetes official yum repository.

- Clone this repository into your master node.

- once it is cloned, get into the directory

- cd kubernetes-and-ansible/centos

- There is a file "hosts" available in "centos" directory, Just make your entries of your all kubernetes nodes.

- Provide your server details in "env_variables" available in "centos" directory.

- Deploy the ssh key from master node to other nodes for password less authentication.

- ssh-keygen

- Copy the public key to all nodes including your master node and make sure you are able to login into any nodes without password.

- Run "settingup_kubernetes_cluster.yml" playbook to setup all nodes and kubernetes master configuration.

- ansible-playbook settingup_kubernetes_cluster.yml

- Run "join_kubernetes_workers_nodes.yml" playbook to join the worker nodes with kubernetes master node once "settingup_kubernetes_cluster.yml" playbook tasks are completed.

- ansible-playbook join_kubernetes_workers_nodes.yml

- Verify the configuration from master node.

- kubectl get nodes


What are the files this repository has?:
- ansible.cfg - Ansible configuration file created locally.
- hosts - Ansible Inventory File
- env_variables - Main environment variable file where we have to specify based on our environment.
- settingup_kubernetes_cluster.yml - Ansible Playbook to perform prerequisites ready, setting up nodes, configure master node.
- configure_worker_nodes.yml - Ansible Playbook to join worker nodes with master node.
- clear_k8s_setup.yml - Ansible Playbook helps to delete entire configurations from all nodes.
- playbooks - Its a directory holds all playbooks.