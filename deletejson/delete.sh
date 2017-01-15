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


hostedzone=$2
realclustersize=$(cat newetcdips.txt | wc -l)
recordnum=$(aws route53 list-resource-record-sets --hosted-zone-id $hostedzone | jq .ResourceRecordSets[].Name | grep etcd | sed 's/[^0-9]//g' | sort -n | tail -1)

ipoverdraft=$(expr $recordnum - $realclustersize)
echo "ipoverdraft = $ipoverdraft"

clustersize=$(expr $(cat newetcdips.txt | wc -l) + 1)

for (( i = $ipoverdraft; i < $recordnum; i++ )); do
  cat delete.json.template > delete.json
  etcdrec=$(expr $i + 4)
  etcdip=$(aws route53 list-resource-record-sets --hosted-zone-id $hostedzone | jq .ResourceRecordSets[$etcdrec].ResourceRecords[].Value)
  etcdnum=etcd$i
  sed -i "s/etcdnum/$etcdnum/g" delete.json
  sed -i "s/etcdip/$etcdip/g" delete.json
  sed -i "s/tldname/$1/g" delete.json
  aws route53 change-resource-record-sets --hosted-zone-id $1 --change-batch file://delete.json
done
# Usage: $0 tld hosted-zone-id
# requirements: jq, awscli, curl
