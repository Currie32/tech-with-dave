# Deploy an Elasticsearch service on Google Kubernetes Engine

Google Kubernetes Engine (GKE) is a good choice for an Elasticsearch deployment as it is a managed Kubernetes service that offers a free tier, scalability, high availability, and security features. Using this guide, you'll be able to create an Elasticsearch service in about 10 minutes that you can use to host an index and allow users to search the data from any device.

## Get setup with Google Cloud Platform

Register or sign in to GCP, then create a new project at: <a href=https://console.cloud.google.com target="_blank">https://console.cloud.google.com</a>

Download and install GCP SDK on your local machine: <a href=https://cloud.google.com/sdk/docs/install target="blank">https://cloud.google.com/sdk/docs/install</a>

Enable the Kubernetes Engine API for your project: <a href=https://console.cloud.google.com/marketplace/product/google/container.googleapis.com?returnUrl=%2Fkubernetes target="blank">https://console.cloud.google.com/marketplace/product/google/container.googleapis.com?returnUrl=%2Fkubernetes</a>


In your terminal, make sure that gcloud is configured to your new project:
```
gcloud config set project name-of-project
```

## Create your Kubernetes Cluster

Create an <a href=https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview target="blank">Autopilot cluster</a>. You can choose any name, but I'll be using `es-cluster` for this guide. You can also choose a different region from `us-west1` and it's recommended that you choose a location close to your users to reduce latency. You can see all regions <a href=https://cloud.google.com/compute/docs/regions-zones#available target="blank">here</a>. (It will take a few minutes to create the cluster)
```
gcloud container clusters create-auto es-cluster --region=us-west1
```

After creating your cluster, you need to get authentication credentials to interact with the cluster:
```
gcloud container clusters get-credentials es-cluster --region us-west1
```

## Add an Elasticsearch service to your Kubernetes Cluster

### Download Elastic Cloud on Kubernetes

Download Elastic Cloud on Kubernetes using these two commands taken from this <a href=https://www.elastic.co/downloads/elastic-cloud-kubernetes target="blank">Elasticsearch page</a>:
```
kubectl create -f https://download.elastic.co/downloads/eck/2.9.0/crds.yaml

kubectl apply -f https://download.elastic.co/downloads/eck/2.9.0/operator.yaml
```

The first command creates Custom Resource Definitions (CRDs) in your Kubernetes cluster. CRDs are custom resource types that can be used to define and manage custom objects within a Kubernetes cluster. In this case, the CRDs are defined in the `crds.yaml` file provided by Elastic.

The second command applies the operator deployment configuration to your Kubernetes cluster. The operator is responsible for managing Elasticsearch services and their associated resources.

Next, we'll follow some steps outlined in this <a href=https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-elasticsearch.html target="blank">Elastic documentation page</a>.

### Create your Elasticsearch service

Create a file called `elasticsearch.yml` and add:
```
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 7.13.0
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
```

Feel free to change the name of your service from `quickstart` and to use a different version. I'm using version `7.13.0` as the python client for Elasticsearch <a href=https://stackoverflow.com/questions/68992402/elasticsearch-error-the-client-noticed-that-the-server-is-not-a-supported-dist target="blank">does not support</a> more recent versions.

When you have that file ready, create your Elasticsearch service on your cluster:
```
kubectl apply -f elasticsearch.yml
```

You can get an overview of your Elasticsearch service in the Kubernetes cluster, including health, version and number of nodes:
```
kubectl get elasticsearch
```

When you create the service, there is no `HEALTH` status and the `PHASE` is empty. After a while, the `PHASE` turns into `Ready`, and `HEALTH` becomes `green`. The `HEALTH` status comes from <a href=https://www.elastic.co/guide/en/elasticsearch/reference/8.9/cluster-health.html target="blank">Elasticsearch’s cluster health API</a>.

You can check the status of your pod:
```
kubectl get pods --selector='elasticsearch.k8s.elastic.co/cluster-name=quickstart'
```

A <href=https://kubernetes.io/docs/concepts/workloads/pods/ target="blank">pod</a> is the smallest and simplest unit in the Kubernetes object model. It represents a single instance of a running process in a cluster.

You can get some information about your Kubernetes service:
```
kubectl get service quickstart-es-http
```

A default user named `elastic` is automatically created with the password stored in a Kubernetes secret. To get your password:
```
PASSWORD=$(kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
```

You'll need this password later to access your Elasticsearch service. You can view your password:
```
echo $PASSWORD
```

To be able to access your Elasticsearch service from an external IP address, you'll need to change the type of the service from a `ClusterIP` to a `LoadBalancer`. To do that create a YAML file called `service-patch.yml` and add:
```
apiVersion: v1
kind: Service
metadata:
  name: quickstart-es-http
spec:
  type: LoadBalancer
```

Then apply this patch to your service:
```
kubectl apply -f service-patch.yml
```

You can verify the change:
```
kubectl get svc quickstart-es-http
```

## Connect to your Elasticsearch service

You can verify that your service is running and accessible by going to `https://<EXTERNAL-IP>:9200`, using the `EXTERNAL-IP` value from the previous command, e.g. `https://12.345.678.910:9200`. You might see that this site is unsafe, but if you follow along and enter your username as `elastic` and your password from earlier, you should see something very similar to:
```
{
  "name" : "quickstart-es-default-0",
  "cluster_name" : "quickstart",
  "cluster_uuid" : "ADhxHDGvQUi5U4lcjykG0Q",
  "version" : {
    "number" : "7.13.0",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "5ca8591c6fcdb1260ce95b08a8e023559635c6f3",
    "build_date" : "2021-05-19T22:22:26.081971330Z",
    "build_snapshot" : false,
    "lucene_version" : "8.8.2",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

If you are also working with Python to build and interact with your Elasticsearch index, you can use this command to connect to your Elasticsearch service:
```
from elasticsearch import Elasticsearch

es = Elasticsearch(["https://<EXTERNAL-IP>:9200"], http_auth=["elastic", "<your-password>"], verify_certs=False)
```

`verify_certs=False` is required to connect to your Elasticsearch service. You can add certificates using <a href=https://www.elastic.co/guide/en/elasticsearch/reference/current/secure-cluster.html target="blank">this guide</a>, but your username and password are required to access your service, so there's still some security in place.
