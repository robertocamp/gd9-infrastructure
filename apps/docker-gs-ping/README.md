# app deployment
## Docker multi-arch
- Docker introduced a feature called "multi-platform builds" using buildx, which allows you to build Docker images for multiple platforms from a single machine. 
- With this feature, you can build both ARM64 and AMD64 images either as separate tags or as a single multi-platform image. 
- When the multi-platform image is pulled on a specific platform, Docker will automatically pull the appropriate version.


## Docker UI must be running!
## create ECR repository
- validate identity and connectivity to AWS: `aws sts get-caller-identity`
- create repository: `aws ecr create-repository --repository-name docker-gs-ping`
```
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-2:240195868935:repository/docker-gs-ping",
        "registryId": "240195868935",
        "repositoryName": "docker-gs-ping",
        "repositoryUri": "240195868935.dkr.ecr.us-east-2.amazonaws.com/docker-gs-ping",
        "createdAt": "2023-08-23T13:38:28-05:00",
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

## Docker images build on M1 (Mac)
- Docker images built with Apple Silicon (or another ARM64 based architecture) can create issues when deploying the images to a Linux or Windows based *AMD64 environment (e.g. AWS EC2, ECS, etc.). 
- For example, you may try to upload your docker image made on the M1 chip to an AWS ECR repository and it fails to run. 
- Therefore, you need a way to build AMD64 based images on the ARM64 architecture, whether it's using Docker build (for individual images) or docker-compose build (e.g. for multi-image apps running in a docker compose network)
- **OLD WAY**: For building single docker images: Set your environment variable using the command line or modifying your .bashrc or .zshenv file:
  + `export DOCKER_DEFAULT_PLATFORM=linux/amd64`
- **NEW WAY**:
  + list the current builder instances: `docker buildx ls`
  + create a new builder instance: `docker buildx create --name multiarch-builder --use`
## app deployment steps
1. initialize Go app: `go mod init github.com/robertocamp/gd9-infrastructure/apps/docker-gs-ping`
2. `touch main.go`
3. `touch main_test.go`
4. code the app: `go mod tidy` after coding to pickup any dependencies that need to be downloaded
5. run unit tests:  `go test -v`
```
=== RUN   TestIntMinBasic
--- PASS: TestIntMinBasic (0.00s)
=== RUN   TestIntMinTableDriven
=== RUN   TestIntMinTableDriven/0,1
=== RUN   TestIntMinTableDriven/1,0
=== RUN   TestIntMinTableDriven/2,-2
=== RUN   TestIntMinTableDriven/0,-1
=== RUN   TestIntMinTableDriven/-1,0
--- PASS: TestIntMinTableDriven (0.00s)
    --- PASS: TestIntMinTableDriven/0,1 (0.00s)
    --- PASS: TestIntMinTableDriven/1,0 (0.00s)
    --- PASS: TestIntMinTableDriven/2,-2 (0.00s)
    --- PASS: TestIntMinTableDriven/0,-1 (0.00s)
    --- PASS: TestIntMinTableDriven/-1,0 (0.00s)
PASS
ok      github.com/robertocamp/gd9-infrastructure/apps/docker-gs-ping   0.159s
```
6. smoke test the app:  `go run main.go`
  + connect to localhost:3000
7. build the image: `docker build --tag docker-gs-ping .`
8. list and validate the image:
  + `docker image ls` should see "latest" as tag
  + you should also see the "moby/buildkit" image installed, if you have used `buildx` already
  + run the image from Docker UI, choose host port 3000 and then connect to localhost:3000
    + CLI example: `docker run -p 8080:8080 myservice:local`
  + you see the same page you got with `go run main.go`
6. authenticate to the ECR: `aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 240195868935.dkr.ecr.us-east-2.amazonaws.com`
7. Build for AMD64 Architecture:
  + First, create a new builder instance that can target multiple architectures: `docker buildx create --name multiarch-builder --use`
  + `docker buildx build --platform linux/amd64 -t docker-gs-ping:amd64-latest . --load`
8. tag and push to ECR:
  + `docker tag docker-gs-ping:amd64-latest 240195868935.dkr.ecr.us-east-2.amazonaws.com/docker-gs-ping:latest`
  + `docker push 240195868935.dkr.ecr.us-east-2.amazonaws.com/docker-gs-ping:latest`
  + `aws ecr list-images --repository-name docker-gs-ping --region us-east-2`

## links
- https://randallkent.com/2021/12/31/how-to-build-an-amd64-and-arm64-docker-image-on-a-m1-mac/
- https://blog.jaimyn.dev/how-to-build-multi-architecture-docker-images-on-an-m1-mac/
- https://docs.docker.com/language/golang/build-images/
- https://github.com/docker/docker-gs-ping
- go by example: https://gobyexample.com/
