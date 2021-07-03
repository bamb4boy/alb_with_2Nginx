#!/bin/bash

###pre
#make sure you have your aws cli configured with the appropriate IAM role
#make sure you are using the ami from the correct region
#create iam profile with which the instances will authenticate
#aws iam create-instance-profile --instance-profile-name buckets3
#giving the profile a role
#aws iam add-role-to-instance-profile --instance-profile-name buckets3 --role-name S3access
#upload to your bucket your blue and red directories
#make sure you have your pem key


#Create and run two different instances to set different configuration of the nginx server later on
aws ec2 run-instances \
  --image-id ami-0ab4d1e9cf9a1215a \
  --count 1 \
  --instance-type t2.micro \
  --key-name Dev \
  --security-group-ids sg-9bf91c91 \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=blue}]" \
  --no-cli-pager \
  --iam-instance-profile Arn=arn:aws:iam::966444541051:instance-profile/buckets3 \
  --user-data file://nginx_conf_blue.sh

aws ec2 run-instances \
  --image-id ami-0ab4d1e9cf9a1215a \
  --count 1 \
  --instance-type t2.micro \
  --key-name Dev \
  --security-group-ids sg-9bf91c91 \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=red}]" \
  --no-cli-pager \
  --iam-instance-profile Arn=arn:aws:iam::966444541051:instance-profile/buckets3 \
  --user-data file://nginx_conf_red.sh

#setting sleep in order to give the instances enough time to create
sleep 60

#describe the instances in order to use their ids while creating the load balancer target group as a variable
#filtering the output to get specific info
instance1=$(aws ec2 describe-instances \
  --filters Name=tag-value,Values=blue \
  --query Reservations[].Instances[].InstanceId \
  --output text | awk \{'print $1'\})

instance2=$(aws ec2 describe-instances \
  --filters Name=tag-value,Values=red \
  --query Reservations[].Instances[].InstanceId \
  --output text | awk \{'print $1'\})


#creating a load balancer using all the subnets of the VPC so no matter where the instance will be created
#the lb would be able to redirect to it
aws elbv2 create-load-balancer --name my-load-balancer  \
  --subnets subnet-1b72e47d subnet-78b39535  subnet-71cd5150 subnet-c8d87df9 	subnet-07e1a909 subnet-e273e0bd\
  --security-groups sg-9bf91c91 \
  --no-cli-pager \

#creating a variable for the LB arn(the lb resource number)
lbArn=$(aws elbv2 describe-load-balancers\
  --output text | grep LOADBALANCERS | awk \{'print $6'\})


#creating a target group to the LB (two groups each for other instance)
aws elbv2 create-target-group --name blue-targetgroup --protocol HTTP --port 8080 \
  --vpc-id vpc-d9ff5da4 \
  --no-cli-pager

aws elbv2 create-target-group --name red-targetgroup --protocol HTTP --port 8080 \
  --vpc-id vpc-d9ff5da4 \
  --no-cli-pager


#creating a variable for the targetGroup arn
tgArn1=$(aws elbv2 describe-target-groups\
  --output text | grep blue-targetgroup | awk \{'print $12'\})
tgArn2=$(aws elbv2 describe-target-groups\
  --output text | grep red-targetgroup | awk \{'print $12'\})


#adding the instances to the target group by using their var
aws elbv2 register-targets --target-group-arn "${tgArn1}"  \
  --targets Id="${instance1}" \
  --no-cli-pager
aws elbv2 register-targets --target-group-arn "${tgArn2}"  \
  --targets Id="${instance2}" \
  --no-cli-pager


#creating a default rule that will show when there is no forwarding
aws elbv2 create-listener --load-balancer-arn "${lbArn}" \
  --protocol HTTP --port 8080  \
  --default-actions Type=fixed-response,FixedResponseConfig='{MessageBody=Please Enter /red or /blue at the end of the URL,StatusCode=400,ContentType=text/plain}' \
  --no-cli-pager

#creating variable of the listener arn
lsArn=$(aws elbv2 describe-listeners \
  --load-balancer-arn "${lbArn}" \
  --output text \
  --no-cli-pager | grep listener | awk \{'print $2'\})


#creating a rule that forwards traffic to url/blue
aws elbv2 create-rule \
    --listener-arn "${lsArn}" \
    --priority 1 \
    --conditions Field=path-pattern,PathPatternConfig='{Values=/blue}' \
    --actions Type=forward,TargetGroupArn="${tgArn1}" \
    --no-cli-pager

#creating a rule that forwards traffic to url/red
aws elbv2 create-rule \
    --listener-arn "${lsArn}" \
    --priority 2 \
    --conditions Field=path-pattern,PathPatternConfig='{Values=/red}' \
    --actions Type=forward,TargetGroupArn="${tgArn2}" \
    --no-cli-pager