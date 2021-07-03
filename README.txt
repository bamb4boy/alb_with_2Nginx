#make sure you have your aws cli configured with the appropriate IAM role

#make sure you are using the ami from the correct region

#create iam profile with which the instances will authenticate
#aws iam create-instance-profile --instance-profile-name buckets3

#giving the profile a role
#aws iam add-role-to-instance-profile --instance-profile-name buckets3 --role-name S3access

#upload to your bucket your blue and red directories

#make sure you have your pem key


to run the script > sh ec2_and_alb_creation.sh