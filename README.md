# AWS Scalable and Secure Web Application using Terraform

This README provides a step-by-step guide on how to use Terraform to set up an AWS environment with an auto-scaling EC2 setup behind a load balancer and an RDS instance with High Availability, ensuring secure communication between them.

<b>*_Objective:_*</b>

We're planning to launch a new web application. You are to create a
Terraform script that sets up an AWS environment with an auto-scaling EC2 setup
behind a load balancer, and an RDS instance, ensuring secure communication
between them.

<b>*_Deliverable:_*</b>

Provide the Terraform scripts and a README file that explains the
architecture and instructions to execute the scripts.

## Table of Contents

- [Prerequisites]()
- [Assumptions]()
- [Infrastructure Overview](#infrastructure-overview-of-our-web-application)
- [Terraform Setup]()
- [Terraform Configuration]()
- [Deploying Infrastructure]()
- [Clean Up]()
- [Technical Trade-Offs]()

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

9. __Public Subnet:__ Public Subnet is for connecting the resources in the private subnet to the internet securely.

10. __Private Subnet:__ Private Subent is where the sensitive resources like the web app server and database servers to prevent security breach so they are not directly connected to the internet.

11. __Multi-AZ Deployment:__ I made use of two availability zones to avoid single point of failure for smooth running of our web app, should there be a disaster in one of the AZs.

Here is a diagram illustrating the architecture:

![Infrastructural Diagram](/img/architectural_diagram.png)

