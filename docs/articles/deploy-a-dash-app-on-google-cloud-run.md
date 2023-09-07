# Deploy a Dash App on Google Cloud Run

Google Cloud Run is a great place to deploy a web app. Depending on the usage of your app, the costs can be near zero due to the serverless architecture of Google Cloud Run and as your traffic increases, the autoscaling will provide more resources to meet the demand. Plus, as you'll see below, it is rather straightforward to deploy your app to Google Cloud Run.

## Get setup with Google Cloud Platform

Register or Sign in to GCP, then create a new project at: <a href=https://console.cloud.google.com target="_blank">https://console.cloud.google.com</a>

Download and install GCP SDK on your local machine: <a href=https://cloud.google.com/sdk/docs/install target="blank">https://cloud.google.com/sdk/docs/install</a>

## Prepare your Google Cloud Project for your App

Enable the Cloud Run API for your project: <a href=https://console.cloud.google.com/apis/library/run.googleapis.com target="blank">https://console.cloud.google.com/apis/library/run.googleapis.com</a>

Enable the Artifact Registry API (you'll need to have a billing account for this) and create a repository to store your docker image(s): <a href="https://cloud.google.com/artifact-registry/docs/repositories/create-repos#create-console" target="blank">https://cloud.google.com/artifact-registry/docs/repositories/create-repos#create-console</a>

I usually call this repository `docker`. We will use this repository in the [.Tag](./deploy-a-dash-app-on-google-cloud-run.md#tag) step.

## Write the required files for deployment

In your terminal, make sure that gcloud is configured to your new project:
```
gcloud config set project name-of-project
```

Create a Dockerfile that will be used to create your Docker image. You can use some that I have created as templates:

- <a href=https://github.com/Currie32/statistical_stories/blob/master/Dockerfile target="blank">https://github.com/Currie32/statistical_stories/blob/master/Dockerfile</a>
- <a href=https://github.com/Currie32/practice-a-language/blob/master/Dockerfile target="blank">https://github.com/Currie32/practice-a-language/blob/master/Dockerfile</a>

This step assumes that you already have a requirements.txt file. If you don't have one yet, you can create it by:

```
pip freeze > requirements.txt
```

It's good practice to remove any packages from `requirements.txt` that are not required to run your app as this will make your Docker image unnecessarily larger and take longer to build.

## Build, Push, and Deploy your Docker Image

### Build

Build your Docker image:
```
docker build -t name-of-image:1.0.0 .
```

The version of your image is optional, so you could also do:
```
docker build -t name-of-image
```

It might take 1-2 minutes to build your Docker image, depending on its size.

You can check that your image has been built properly by:
```
docker run -i --rm name-of-image:1.0.0
```

### Tag

Tag your Docker image so that it will be pushed to the Docker registry on Google Cloud Platform:
```
docker tag name-of-image:1.0.0 location-of-project-docker.pkg.dev/name-of-project/name-of-docker-repository/name-of-image:1.0.0
```

An example of what this command could like is:
```
docker tag pal-image:1.0.0 us-west1-docker.pkg.dev/practice-a-language/docker/pal-image:1.0.0
```

Depending on the location of your project, you might have to change `us-west1` to a different value.

### Push

Push your image to your Docker repository:
```
docker push location-of-project-docker.pkg.dev/name-of-project/name-of-docker-repository/name-of-image:1.0.0
```

### Deploy

Deploy your image to Google Cloud Run:
```
gcloud run deploy pal-image \
--image=location-of-project-docker.pkg.dev/name-of-project/name-of-docker-repository/name-of-image:1.0.0 \
--allow-unauthenticated \
--service-account=your-service-account-number-compute@developer.gserviceaccount.com \
--region=your-region \
--project=your-project-name
```

Notice that you will need to add your own values to four of these parameters. You can find your service account number at `https://console.cloud.google.com/iam-admin/iam?project=your-project-name`

Depending on your needs, you can specify additional deployment parameters, which can be found at: <a href=https://cloud.google.com/sdk/gcloud/reference/run/deploy target="blank">https://cloud.google.com/sdk/gcloud/reference/run/deploy</a>
