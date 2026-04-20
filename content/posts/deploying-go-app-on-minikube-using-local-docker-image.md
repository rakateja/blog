---
title: "Deploying Go App on Minikube Using Local Docker Image"
date: 2019-12-08T00:00:00+07:00
draft: false
description: "Step-by-step guide to deploying a Go application on Minikube using a locally-built Docker image, covering Dockerfile multi-stage build, Kubernetes deployment YAML, and kubectl commands."
keywords: ["golang", "go", "minikube", "kubernetes", "docker", "local docker image", "kubectl", "deployment", "container"]
---

In this post I will guide you how to running local Docker Image on Minikube, a Virtual Machine which runs a single-node Kubernetes cluster locally. To go thru this post, I expect you already have Docker, kubectl and Minikube installed in local environment.

Before starting into main topic, we need to create a small Go application first, it's just a server that is receiving HTTP requests.

```go
package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/google/uuid"
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Port int `envconfig:"PORT" default:"8080"`
}

func main() {
	var conf Config
	if err := envconfig.Process("KLAUS", &conf); err != nil {
		log.Fatalf("%v", err)
	}
	log.Println("[INFO] Starting klaus server ...")

	http.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		id, err := uuid.NewUUID()
		if err != nil {
			fmt.Fprintf(w, err.Error())
			return
		}
		log.Printf("[INFO] ReqID: %v", id.String())
		fmt.Fprintf(w, "Hello Klaus!!")
	})
	log.Printf("[INFO] Listening on port :%d", conf.Port)
	http.ListenAndServe(fmt.Sprintf(":%d", conf.Port), nil)
}
```

Let's test the application first, run following command to resolve external packages

```
$ go get github.com/google/uuid
$ go get github.com/kelseyhightower/envconfig
```

Then we are ready to run the app using following command, it will receive HTTP requests, then respond a simple message to client.

```
$ go run main.go
```

Finally, test the app

```
$ curl -XGET localhost:8080
```

If you get a hello message, that means you have successfully created the Go app server. So that we are ready to go thru to the next step, which is dockerizing the app.

## Dockerize the Go app

To dockerize our Go app, I will use multi-stage Docker pattern to produce small Docker Image size.

Here is the Dockerfile that we use to dockerize the Go app.

```dockerfile
FROM golang:1-alpine AS builder

WORKDIR /go/src/github.com/rakateja/klaus/hello-world

RUN apk add --update git

COPY main.go .
RUN go get github.com/google/uuid
RUN go get github.com/kelseyhightower/envconfig

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o app .

FROM alpine
EXPOSE 8080

COPY --from=builder /go/src/github.com/rakateja/klaus/hello-world/app .

ENTRYPOINT ./app
```

To build Docker Image using Dockerfile above, we could execute following command.

```
$ docker build --rm -t klaus-hello-world .
```

You'll see a message something like this, if the Docker Image was successfully created.

```
Successfully built 4028d9d649e6
Successfully tagged klaus-hello-world:latest
```

You also can use `docker images` command to see the result.

![docker images](/docker-images.png)

To run the Docker Image, you can use following command.

```
$ docker run -e PORT=8080 -p 8080:8080 --name=klaus-hello-world klaus-hello-world
```

Then test it again by sending HTTP request using curl

```
$ curl localhost:8080
```

## Deploying Local Docker Image on Minikube

In the previous section, we've successfully created a Docker Image for Go app, then in this section we'll deploy it in Minikube, a local Kubernetes cluster that's running in local machine. Before go thru into this section, I expect you already have Minikube in your local machine, to test it you can use following command.

```
$ minikube start
```

The result should be something like this

```
host: Running
kubelet: Running
apiserver: Running
kubectl: Correctly Configured: pointing to minikube-vm at 192.168.99.100
```

First thing we need to understand is, a minikube is a virtual machine that's already have Docker image installed. So that we can say its Docker engine is different with Docker engine that's already running on our local environment.

To proof that we can execute `docker images` command in local environment and in Minikube virtual machine, the result should be different. To execute the command inside Minikube virtual machine, you need ssh into Minikube first by running following command.

```
$ minikube ssh
```

Then the next step is pointing out local docker environment to Minikube by using following command. But first, we need to exit from Minikube virtual machine first, use `exit` command to do so.

```
$ eval $(minikube docker-env)
```

Execute `docker images` in Minikube and local environment, now the result should be same. Then the next step is building docker image for our Go app to Minikube's Docker engine, the command is still the same.

```
$ docker build --rm -t klaus-hello-world .
```

To check the result, you can ssh into Minikube first then execute `docker images`, the Docker Image `klaus-hello-world` should be appeared there.

Then the next step is to create a yaml file about Kubernetes Deployment. To make Minikube uses local Docker Image, we need to configure its Image Pull Policy, use `Never` for the configuration.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: load-balancer-klaus-hello-world
  name: klaus-hello-world
spec:
  replicas: 5
  selector:
    matchLabels:
      app.kubernetes.io/name: load-balancer-klaus-hello-world
  template:
    metadata:
      labels:
        app.kubernetes.io/name: load-balancer-klaus-hello-world
    spec:
      containers:
      - image: klaus-hello-world:latest
        name: klaus-hello-world
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        env:
        - name: KLAUS_PORT
          value: "8080"
```

To execute the file, we run following command.

```
$ kubectl apply -f minikubeDeployment.yaml
```

It will create Deployment object and associated with ReplicaSet object. The ReplicaSet object will has 5 pods, each object runs the application.

```
$ kubectl get pods
```

The output is similar to this.

![kubectl get pods](/get-pods.png)

Then you can use following command to check the Deployment

```
$ kubectl get deployment klaus-hello-world
```

Then the final step is creating Service object to expose the Deployment.

```
$ kubectl expose deployment klaus-hello-world --type=LoadBalancer --name=klaus-hello-world-service
```

To check the result, use following command

```
$ kubectl get services klaus-hello-world-service
```

The output is similar to this.

![kubectl get services](/get-services.png)

If EXTERNAL-IP is still pending, wait for couple of minute or execute `minikube tunnel` in different terminal. Then check the result by using the same command, if it's still not appeared, try again and again.

You can also can use following command to see detail information about the Service.

```
$ kubectl describe services klaus-hello-world-service
```

Then finally use the EXTERNAL-IP address to access the application.

```
$ curl http://<EXTERNAL-IP>:<PORT>
```

The response to successful request is a hello message:

```
Hello Klaus!!
```

Yay it means we've successfully deployed Go application using local Docker Image on Minikube.

Thanks for reading and enjoy!

## References

- https://kubernetes.io/docs/tutorials/stateless-application/expose-external-ip-address/
