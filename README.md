# NodeJS Lifebit

I will document here all the steps that I took to have installed a nodejs app.

 - Terraform to deploy infra as code
 - Ansible to deploy the app from a github depository
 - TODO: jenkinsfile to deploy the code
 

# Terraform

To deploy terraform I assumed that a VPC was already in place with a NSG and a subnet associated.

    terraform init
    terraform plan
    terraform apply

NOTE: The idea was to create a backend configuration on a S3 bucket, but due to time constrains the local tfstate file was used.

File main.tf should be populated with AWS account **access_key** and **secret_key**, or venvs can be created to be used by terraform.
 
     access_key = "[Goes here]"
     secret_key = "[Goes here]"
 
# Test LOAD on the app

The easy way to test it is to use an app like https://locust.io/
Basically it tests the load by simulating multiple users visits.

First add the LB address on the locust file:
self.client.get("[Loadbalancer FQDN GOES HERE]")

Launch it like:
    `locust -f locust/locustfile.py`

Access it like:
When it starts access your browser like http://0.0.0.0:8089 and simulate the load that you desire.

## Ansible

This tool uses AWS dynamic inventory. These files are located on each environment and should be mapped with tags, env=[prod,stag].

To deploy the app using ansible the following configurations are expected:

ansible.cfg inside the user home dir like:

    [defaults]
    remote_user = ubuntu
    enable_plugins = aws_ec2
    private_key_file = [private ssh key is expected here]
    roles_path =  [locations for ansible roles here]
    
    [ssh_connection]
    ssh_args = -o ControlPersist=15m -o StrictHostKeyChecking=no
    pipelining = False

To execute the playbook you have to use the following command:

    ansible-playbook  -i inventory/[prod,stag] playbooks/nodejs.yaml -vv

 # Architeture/Schema

The autoscale group has policies that based on memory usage will scale up and down the cluster.

Loadbalancer -- connected to --> AWS AutoScale Group ---> VM 1
                                                     ---> VM 2
                                                     ---> VM 3
                                                     ---> VM N
                            