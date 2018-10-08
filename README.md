Prerequisites:
--------------
1. Creat a new keyvalue pair in AWS -- `mypersonal.pem`. This is used to ssh into server
2. Create and save AWS_PROFILE keys in `~/.ssh`

VPC architecture:
-----------------
1. VPC
2. Public subnet
3. Private subnet
4. IGW --> (Attach VPC and link to public subnet)
5. NGW --> (Create in public subnet and link to private subnet)
6. Elastic IP --> (Tag it to NGW)
7. Route tables and subnet association 

EC2 instance:
-------------
Load Balancer (Classic) --> ASG --> EC2 

Click on the below link
`test-narvar-lb-1680139374.us-east-1.elb.amazonaws.com`

Securiy groups:
---------------
1. test-narvar-elb-sg (tcp 80, tcp 443, ALL)
2. test-narvar-asg-sg (tcp 80 --> test-narvar-elb-sg)
3. test-narvar-nat-sg (tcp 22, ALL)
4. test-narvar-default (tcp 22 --> test-narvar-nat-sg)

How to run terraform
---------------------
setup your aws credentials on your local account. 
`https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html`

Install terraform:
------------------
1. Install brew if using Mac
2. `brew install terraform`

Terraform commands to use:
Navigate to the terraform folder earnest > vpc_terraform
1. `AWS_PROFILE=devops terraform init`
2. `AWS_PROFILE=devops terraform plan`
3. `AWS_PROFILE=devops terraform apply`

Installing Ansible:
-------------------
1. `brew install ansible`
2. `ssh-add ~/.ssh/mypersonal.pem`

Since our EC2 instance is in private subnet, ansible will not have the ability to communicate to the EC2 instance and install `docker`, and `nginx container`. So we need to create `NAT (bastion)` host in public subnet which will help to ssh to private instance. But even in this case ansible will not have the ability to coonect to bastion first and then private instance. 

To solve this problem we need to use `SSH CONFIG` file. Place the below line in `~/.ssh` location

```
HOST bastion
  IdentityFile ~/.ssh/mypersonal.pem
  User ubuntu
  Hostname 18.232.182.16

HOST 10.0.3.107
  User ubuntu
  IdentityFile ~/.ssh/mypersonal.pem
  ProxyCommand ssh bastion -W %h:%p
```
Hence using the proxy command you Ansible will be able to login to private ip address in the host file

To make Ansible playbook install `Python`, `Patch updates`, `Docker Demon` and `nginx conatiner`. run the following commands

`AWS_PROFILE=devops ansible-playbook -i inventories/dev playbook/config.yml`

To enable debug mode 

`AWS_PROFILE=devops ansible-playbook -i inventories/dev -vvv playbook/config.yml`

Above commands will give output something like below
```
TASK [BOOTSTRAPPING HOST: Ensuring python-lxml is installed (for maven artifact install)] ******************
ok: [10.0.3.107]

TASK [setup] ***********************************************************************************************
ok: [10.0.3.107]

TASK [docker_role : Add Docker's GPG key] ******************************************************************
ok: [10.0.3.107]

TASK [docker_role : Configure upstream APT repository] *****************************************************
ok: [10.0.3.107]

TASK [docker_role : Remove Docker] *************************************************************************
skipping: [10.0.3.107]

TASK [docker_role : Install Docker] ************************************************************************
ok: [10.0.3.107]

TASK [docker_role : Create "docker" group] *****************************************************************
ok: [10.0.3.107]

TASK [docker_role : Add remote "ubuntu" user to "docker" group] ********************************************
ok: [10.0.3.107]

TASK [docker_role : Remove Upstart config file] ************************************************************
ok: [10.0.3.107]

TASK [docker_role : Ensure systemd directory exists] *******************************************************
ok: [10.0.3.107]

TASK [nginx_docker : Install pip] **************************************************************************
ok: [10.0.3.107]

TASK [nginx_docker : install docker-py package] ************************************************************
ok: [10.0.3.107]

TASK [nginx_docker : Install nginx Docker] *****************************************************************
ok: [10.0.3.107]

TASK [nginx_docker : Check if Nginx conatiner exist] *******************************************************
ok: [10.0.3.107]

TASK [nginx_docker : Restart nginx container] **************************************************************
changed: [10.0.3.107]

TASK [nginx_docker : Check if container is running] ********************************************************
changed: [10.0.3.107]

PLAY RECAP *************************************************************************************************
10.0.3.107                 : ok=16   changed=3    unreachable=0    failed=0
```

Verify if the installation is done:
----------------------------------
1. ssh 10.0.3.107 --> (you should be able to login with this command as this command will take the adavantage of ssh config file)
2. `sudo systemctl status docker`
you will see some this like this 
```
● docker.service - Docker Application Container Engine
   Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2018-10-07 00:45:14 UTC; 20h ago
     Docs: https://docs.docker.com
 Main PID: 1115 (dockerd)
    Tasks: 65
   Memory: 155.4M
      CPU: 3min 26.941s
   CGroup: /system.slice/docker.service
           ├─ 1115 /usr/bin/dockerd -H fd://
           ├─ 1261 docker-containerd --config /var/run/docker/containerd/containerd.toml
           ├─ 2698 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 32768 -container-ip 172.17.0
           ├─ 2711 docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.cont
           ├─ 5136 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 80 -container-ip 172.17.0.4
           ├─ 5154 docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.cont
           └─14369 docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.cont
```
3. To verify if which docker images are installed 
`sudo docker images`
```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               1.15                be1f31be9a87        5 days ago          109MB
nginx               latest              be1f31be9a87        5 days ago          109MB
```
4. To check if the nginx container is running 
`sudo docker ps`
```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                NAMES
8946da26e5fe        nginx               "nginx -g 'daemon of…"   3 minutes ago       Up 3 minutes        0.0.0.0:80->80/tcp   test_narvar_nginx
7faa48c9de8d        nginx               "nginx -g 'daemon of…"   6 minutes ago       Up 6 minutes        80/tcp               nginx
```
```
curl 10.0.3.107 32768

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
5. To find the `monitor_script` and `cpu_monitor`
navigate to 
`sudo su -`
`cd /bin`

6. TO check the crone tab 
`cd /bin`
`crontab -e`
