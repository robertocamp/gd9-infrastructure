1. validate session manager:  `session-manager-plugin`
2. `brew install wireshark`
3. aws eks describe-cluster --name <EKS_CLUSTER_NAME> --query "cluster.resourcesVpcConfig.vpcId"
4. aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=<VPC_ID>
5. get pods:  `k get pods -n {NAMESPACE}`
6. NODE_NAME=$(kubectl get pod <POD_NAME> -n {NAMESPACE} -o=jsonpath='{.spec.nodeName}')
  + USES: `k get pod {POD-NAME} -n {NAMESPACE}  -o=jsonpath='{.spec.nodeName}'`
7. `INSTANCE_ID=$(aws ec2 describe-instances --region us-east-2 --filters "Name=private-dns-name,Values=$NODE_NAME" --query 'Reservations[*].Instances[*].InstanceId' --output text)`
8. `echo $INSTANCE_ID`
9. `aws ssm start-session --target $INSTANCE_ID`
10. sudo yum install -y tcpdump
11. sudo timeout 1m tcpdump -i eth0
## 5m trace:
sudo timeout 5m tcpdump -i <INTERFACE> -w /path/to/outputfile.pcap '<FILTER>'

## 1h trace:
sudo timeout 1h tcpdump -i <INTERFACE> -w /path/to/outputfile.pcap '<FILTER>'
12. get role of EC2 node: `aws ec2 describe-instances --instance-ids INSTANCE_ID --query "Reservations[*].Instances[*].IamInstanceProfile.Arn" --output text`

12. aws s3 cp /tmp/tcpdump-demo0.pcap s3://dev-gd9
arn:aws:s3:::dev-gd9


NODE_NAME=$(kubectl get pod docker-gs-ping-deployment-788ffd9f9f-g4f7r -n staging -o=jsonpath='{.spec.nodeName}')

aws s3 cp ssm://i-066b020e346e8f32d/tmp/tcpdump-demo0.pcap /Users/robert/Downloads/tcpdump-demo0.pcap


aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].IamInstanceProfile.Arn" --output text