# Docker container for Route53 synchronisation of etcd

## Usage:
- This container is made to autodetect the autoscaling group, region and IPs of the autoscaling group of a 3/5/7 node etcd cluster
- It is used to update internal Route53 records for DNS based etcd discovery
- On startup of the new instance in the cluster, autoscaling group IPs are submitted to Route53
- Note: IAM role requirements:
  - Readonly AutoScalingGroup permissions
  - Modifiable Route53 records permissions
  - EC2 readonly permissions
- This is primary my PoC to be used with tack - https://github.com/kz8s/tack/blob/master/modules/route53/route53.tf

## Example format:
docker run arehmandev/route53etcd TLDNAME HOSTEDZONE-ID

e.g:
```

docker run arehmandev/route53etcd abs.com Z2ZYS3N4HRA09T
```

Tested and working as of 15/1/17
