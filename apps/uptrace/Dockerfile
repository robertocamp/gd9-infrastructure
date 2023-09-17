# syntax=docker/dockerfile:1

##
## Build the application from source
##

FROM golang:1.19 AS build-stage

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o /uptrace-demo

##
## Run the tests in the container
##

# TODO: build test cases and run them here
# FROM build-stage AS run-test-stage
# RUN go test -v ./...

##
## Deploy the application binary into a lean image
##

FROM gcr.io/distroless/base-debian11 AS build-release-stage

WORKDIR /

COPY --from=build-stage /uptrace-demo /uptrace-demo

EXPOSE 3000

USER nonroot:nonroot

ENTRYPOINT ["/uptrace-demo"]