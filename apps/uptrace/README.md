## Docker multi-arch
- Docker introduced a feature called "multi-platform builds" using buildx, which allows you to build Docker images for multiple platforms from a single machine. 
- With this feature, you can build both ARM64 and AMD64 images either as separate tags or as a single multi-platform image. 
- When the multi-platform image is pulled on a specific platform, Docker will automatically pull the appropriate version.

## setup
1. `cd uptrace`
2. `go mod init github.com/robertocamp/gd9-infrastructure/uptrace`
3. `touch main.go` (get code from Github)
4. `go mod tidy` 
5. `touch Dockerfile` (create Dockerfile)
6. `aws ecr create-repository --repository-name uptrace-demo`
```
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-2:240195868935:repository/uptrace-demo",
        "registryId": "240195868935",
        "repositoryName": "uptrace-demo",
        "repositoryUri": "240195868935.dkr.ecr.us-east-2.amazonaws.com/uptrace-demo",
        "createdAt": "2023-08-28T19:43:34-05:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```
7. `docker buildx create --name multiarch-builder --use`
8. `aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 240195868935.dkr.ecr.us-east-2.amazonaws.com`
9. `docker buildx build --platform linux/amd64 -t uptrace-demo:v001 -f Dockerfile . --load`
10. **tag and push to ECR:**
  + `docker tag uptrace-demo:v001 240195868935.dkr.ecr.us-east-2.amazonaws.com/uptrace-demo:v001`
  + `docker push 240195868935.dkr.ecr.us-east-2.amazonaws.com/uptrace-demo:v001`
  + `aws ecr list-images --repository-name uptrace-demo --region us-east-2`

## Kubernetes service types
### clusterIP
- Purpose: ClusterIP is the default type for a Service. 
  + It gives the service a unique IP address internal to the Kubernetes cluster, allowing pods within the cluster to communicate with the service.

- Access: The service is only accessible within the cluster, not from the outside.

- Use Case: Ideal for internal communication between services. 
  + For example, if you have an internal helper or worker service that shouldn't be exposed externally.


### loadbalancer
- Purpose: A LoadBalancer Service is used when you want to expose your service to external traffic.

- Access: When you create a service of type LoadBalancer in a cloud environment like AWS, it provisions a cloud load balancer that routes external traffic to the appropriate pods within your cluster.

- Use Case: Ideal for exposing your applications to outside traffic, like frontend applications, APIs, etc.

### NodePort
- NodePort exposes the service on each Node’s IP at a static port. 
- This can be handy in certain scenarios, but for most cloud deployments where you'd want an external endpoint, LoadBalancer is typically preferred.

## links
https://github.com/uptrace/opentelemetry-go-extra/blob/main/example/echo/main.go