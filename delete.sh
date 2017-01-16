!#/bin/bash

echo "Removing old records"

hostedzone=$2
tldname=$1
realrecordnum=$(aws route53 list-resource-record-sets --hosted-zone-id $hostedzone | jq .ResourceRecordSets[].Type | wc -l)
realclustersize=$(expr 6 + $(cat newetcdips.txt | wc -l))

if [[ $realclustersize == $realrecordnum ]]; then
    echo "DNS is correct"
    exit
fi

recordnum=$(expr $(aws route53 list-resource-record-sets --hosted-zone-id $hostedzone | jq .ResourceRecordSets[].Type | wc -l) - 1)
clustersize=$(expr 1 + $(cat newetcdips.txt | wc -l))


for (( i = 0; i < $recordnum; i++ )); do
  dnsname=$(aws route53 list-resource-record-sets --hosted-zone-id $hostedzone | jq .ResourceRecordSets[$i].Name | tr -d "\"" | sed -e 's/\.$//')
  etcdip=$(aws route53 list-resource-record-sets --hosted-zone-id $hostedzone | jq .ResourceRecordSets[$i].ResourceRecords[].Value | tr -d "\"")
  if [[ $dnsname =~ [$clustersize-9] ]]; then
    cat delete.json.template > delete$i.json
    etcdpos=$(aws route53 list-resource-record-sets --hosted-zone-id $hostedzone | jq .ResourceRecordSets[$i].Name | tr -d "\"" | sed -e 's/\.$//' | sed 's/[^0-9]*//g')
    echo "Found etcd$etcdpos.$tldname as an A record"
    sed -i "s/etcdnum/etcd$etcdpos/g" delete$i.json
    sed -i "s/etcdip/$etcdip/g" delete$i.json
    sed -i "s/tldname/$tldname/g" delete$i.json
    aws route53 change-resource-record-sets --hosted-zone-id $2 --change-batch file://delete$i.json
  else
    echo "Nvm"
  fi
done
