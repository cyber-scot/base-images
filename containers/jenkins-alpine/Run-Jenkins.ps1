# Define the image name
$ImageName = "ghcr.io/cyber-scot/base-images/jenkins-alpine-cicd-base:latest"

# Pull the latest Jenkins Docker image
docker pull $ImageName

# Set the Jenkins container parameters
$jenkinsParams = @{
    "name" = "jenkins"
    "publish" = "8080:8080" # Maps port 8080 of the container to port 8080 on the host
    "volume" = "jenkins_home:/var/jenkins_home" # Maps the Jenkins home directory to a volume
    "detach" = $True # Runs the container in the background
    "privileged" = $True # Grants additional privileges to the container
    "image" = $ImageName
}

# Run the Jenkins container
docker run @jenkinsParams
