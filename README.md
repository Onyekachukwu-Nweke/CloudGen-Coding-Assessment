# Scalable and Secure Web Application

<b>*_Objective:_*</b>

We're planning to launch a new web application. You are to create a
Terraform script that sets up an AWS environment with an auto-scaling EC2 setup
behind a load balancer, and an RDS instance, ensuring secure communication
between them.

<b>*_Deliverable:_*</b>

Provide the Terraform scripts and a README file that explains the
architecture and instructions to execute the scripts.

## Infrastructure Overview of our Web Application

The architecture we are going to set up consists of the following components:

1. __VPC Internet Gateway:__ AWS Internet Gateway lets a resource in your public subnets that has a public IPv4 or IPv6 address connect to the Internet. Resources on the internet can link to resources in your subnet using the accessible IPv4 or IPv6 address.
2. __Load Balancer:__ An Elastic Load Balancer (ELB) that distributes incoming traffic across multiple EC2 instances.
3. __Elastic IP Address:__ An Elastic IP address is a static IPv4 address designed for dynamic cloud computing. An Elastic IP address is a public IPv4 address, which is reachable from the internet. If your instance does not have a public IPv4 address, you can associate an Elastic IP address with your instance to enable communication with the internet.
4. __AWS NAT Gateway:__ NAT Gateway is used to connect instances securely in the private subnet to the internet.
5. __Auto Scaling Group:__ A group of EC2 instances that automatically scales based on traffic load and health status.
6. __EC2 Instances:__ The web application servers that will host your web application.
7. __RDS Instance:__ A highly available Relational Database Service (RDS) instance for storing application data securely and enabling its data replication feature.
8. __Route Tables:__ Route Tables to control where traffic is directed.

![Infrastructural Diagram](/img/architectural_diagram.png)

