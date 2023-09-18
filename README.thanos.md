# Thanos deployment using kube-thanos

## thanos remote-write
- all managed services for Prometheus from AWS and GCP use the remote-write protocol
- in theory switching from Thanos to a managed service should be a simple as swapping out one URL
- Prometheus natively supports the remote write protocol
- Thanos remote-write supports mTLS, which lets only authorized Prometheus instances push data to our Thanos
- For data older than 15 days, the query will go thru the `storage gateway`
## thanos reference diagram
- ![thanos ref arch](./IMG/thanos-remote-write-ref.png)

## what is jasonnet?
### Superset of JSON: Jsonnet is a data templating language that is a strict superset of JSON
- `Jsonnet` is a configuration language that helps to define and generate JSON data. 
- It's especially useful in the cloud-native and Kubernetes world, where configuration files, particularly in YAML or JSON format, can proliferate rapidly and become difficult to manage due to their sheer volume and redundancy.
- *any valid JSON document is also a valid Jsonnet program*
#### Variables & Logic: 
- Unlike plain JSON, Jsonnet lets you use variables, conditionals, and even loops. 
- This allows for the creation of more dynamic and parameterized configuration files.
#### Functions: 
- You can define functions in Jsonnet, which can be reused across different parts of your configuration
### Mixins and Imports: 
- Jsonnet supports importing other Jsonnet or JSON files, allowing for modular configurations and code reusability.

### jasonnet package manager:  jsonnet-bundler
- aka "jb
- The behavior of the go get command outside of a Go module has changed
- 
- installation: `go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest`
- `which jb`

## kube-thanos: Jsonnet based Kubernetes templates
### design
- With IRSA (IAM Roles for Service Accounts), you avoid hardcoding any access or secret keys. Instead, the service account your pods run as is associated with an IAM role via the OIDC provider, and they automatically receive temporary credentials for that IAM role.
- In the context of Thanos and the thanos.yaml configuration file, this means you'll only need to specify the bucket and endpoint. 
- The access and secret keys will be automatically sourced by the SDK inside the Thanos application from the IAM Role attached to the Kubernetes service account, thanks to the IRSA setup.
### installation
- `cd kube-thanos`
- `jb init`
- `cat jsonnetfile.json`  (creates the initial/empty jsonnetfile )
```
{
  "version": 1,
  "dependencies": [],
  "legacyImports": true
}
```
- `jb install github.com/thanos-io/kube-thanos/jsonnet/kube-thanos@main`
- `jb update`
- `go install github.com/brancz/gojsontoyaml@latest`
- After running this, the gojsontoyaml binary will be installed in your $GOPATH/bin directory

## links
- https://github.com/thanos-io/kube-thanos
- Anton: https://www.youtube.com/watch?v=feHSU0BMcco&t=12s
- https://thanos.io/
- https://github.com/dsayan154/thanos-receiver-demo


