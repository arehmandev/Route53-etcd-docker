#!/bin/bash


EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
ASGNAME=$(aws autoscaling describe-auto-scaling-instances --region=$EC2_REGION | grep AutoScalingGroupName | tail -1 | cut -d '"' -f 4)

function getip {
        for i in `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $ASGNAME --region=$EC2_REGION | grep -i instanceid  | awk '{ print $2}' | cut -d',' -f1| sed -e 's/"//g'`
        do
                aws ec2 describe-instances --instance-ids $i --region=$EC2_REGION | grep -i PrivateIpAddress | awk '{ print $2 }' | head -1 | cut -d '"' -f2 |  xargs printf '%s\n'
        done;
}

getip > newetcdips.txt

realclustersize=$(cat newetcdips.txt | wc -l)

if [[ $realclustersize = 3 ]]; then
  route53json=3-etcdroute53.json
elif [[ $realclustersize = 5 ]]; then
  route53json=5-etcdroute53.json
elif [[ $realclustersize = 7 ]]; then
  route53json=7-etcdroute53.json
fi

clustersize=$(expr $(cat newetcdips.txt | wc -l) + 1)

for (( i = 1; i < $clustersize; i++ )); do
          oldip=etcdip$i
          newip=$(sed -n $i\p newetcdips.txt)
          sed -i "s/${oldip}/${newip}/g" $route53json;
done

sed -i "s/tldname/$1/g" $route53json

aws route53 change-resource-record-sets \
               --hosted-zone-id $2 \
               --change-batch file://$route53json


##
#USAGE
# $1 = TLD name
# $2 = hosted-zone-id

#Example
#bash iterative.sh abdul.com Z2ZYS3N4HRA09T
