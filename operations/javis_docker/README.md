# Docker and Tools

> Docker Setup of JAVIS

*Docker & Tools* will need to be installed on both an **arm** & **x86** system. Different systems have different instructions. Please see your systems' relevant install instructions.

**Table Of Contents**

[TOC]

## System Requirements

- *At minimum*:
    - x86: Ubuntu 16.04
    - arm: Ubuntu 16.04
- Internet connection

* * *

## System x86

Example would be your local laptop for gazebo, rviz visualization simulations.

### Install Docker

1. Remove old versions of Docker

    `sudo apt-get remove docker docker-engine docker.io`

2. Install dependencies and keys

    `sudo apt install curl apt-transport-https ca-certificates curl software-properties-common`

3. Add the official GPG key of Docker

        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"


4. Install Docker

    `sudo apt-get update && sudo apt-get install docker-ce`


5. Add your user to the docker group:

    `sudo usermod -a -G docker $USER`

    - logout-log-back-in for the changes to take effect


6. Verify your Docker installation

    * **Please** do not run with `sudo docker`. Go back to Step 5 if you still cannot run as a non-root user.


    *To verify if `docker` is installed:*

    `docker -v`

    *Try running a sample container:*

    `sudo docker run hello-world`

    - You should see the message *Hello from Docker!* confirming that your installation was successfully completed.

### Docker Compose

1. Download current stable release of *docker compose*
   
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends curl
        sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

2. Apply executable permissions to the binary

        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

3. Test docker compose install
        
        docker-compose --version

### Install NVIDIA Docker

* **Proceed with the below instructions only if you have a NVidia GPU.**

1. Remove old version of Nvidia Docker

        docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f

2. Install NVIDIA Docker

        sudo apt-get purge -y nvidia-docker

3. Setup the NVIDIA Docker Repository

        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        sudo apt-get update

4. Install NVIDIA Docker (version 2):

        sudo apt-get install -y nvidia-docker2

5. Restart the Docker daemon

        sudo service docker restart

6. Verify the installation:

    *To verify if `nvidia-docker` is installed:*

    `nvidia-docker -v`

    *Try running a sample container:*

    `docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi`

    - The docker image `nvidia/cuda` requires a recent CUDA version. If you have an earlier CUDA version, then [find a tag](https://hub.docker.com/r/nvidia/cuda/tags) with an earlier version.
        - Example: `docker pull nvidia/cuda:8.0-runtime` and then run the `docker run` command with the `nvidia/cuda:8.0-runtime` image.

    - This command should print your GPU information.


#### Enable NVidia Docker


1. Test NVIDIA Docker runntime is enabled:

        docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi


2. If NVIDIA docker fails to run, with the following error message: `Unknown runtime specified nvidia`


    - Systemd drop-in file

            sudo mkdir -p /etc/systemd/system/docker.service.d
            sudo tee /etc/systemd/system/docker.service.d/override.conf <<EOF
            [Service]
            ExecStart=
            ExecStart=/usr/bin/dockerd --host=fd:// --add-runtime=nvidia=/usr/bin/nvidia-container-runtime
            EOF
            sudo systemctl daemon-reload
            sudo systemctl restart docker

        
    - Daemon configuration file

            sudo tee /etc/docker/daemon.json <<EOF
            {
            "runtimes": {
                    "nvidia": {
                    "path": "/usr/bin/nvidia-container-runtime",
                    "runtimeArgs": []
                    }
            }
            }
            EOF
            sudo pkill -SIGHUP dockerd

    - Try NVIDIA runntime argument again:
        
            docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi        

* * *

## System arm

Example ARM system would be NVIDIA Jetson orin.

### Install Docker

1. Install Docker

        sudo apt-get update
        sudo apt-get install curl
        curl -fsSL test.docker.com -o get-docker.sh && sh get-docker.sh

2. Add your user to the docker group        
        
        sudo usermod -aG docker $USER

3. Reboot your system.

        sudo reboot -h now

4. Build an example docker image
        
        docker run hello-world 

- Do not run `docker` with `sudo`...


### Docker Compose

There is [no offical](https://github.com/docker/compose/issues/6188) docker-compose binary for ARM, so docker-compose must be install using `python-pip`.

1. Install latest python & python pip packages

        sudo apt-get update
        sudo apt install -y --no-install-recommends python python-setuptools python-pip

2. Install docker-compose dependencies
    
        sudo apt install -y --no-install-recommends libssl-dev libffi-dev python-backports.ssl-match-hostname

3. Install docker-compose

        sudo pip install docker-compose

### Install NVIDIA Docker

Currently, `nvidia-docker` install is done.

Instead, `docker run` will pass the NVIDIA `/dev` devices to docker as arguments.
  - See [here](https://github.com/Technica-Corporation/Tegra-Docker) for more details.

To test out that docker NVIDIA passthu works, please try out the following:

1. Build deviceQuery on local system
        
        cd /usr/local/cuda/samples/1_Utilities/deviceQuery/
        make -j8
        ./deviceQuery

  * Make sure you **do not** see:

                cudaGetDeviceCount returned 35
                -> CUDA driver version is insufficient for CUDA runtime version
                Result = FAIL

2. Copy deviceQuery executable to the javis docker build context

        cp /usr/local/cuda/samples/1_Utilities/deviceQuery/deviceQuery ${JAVIS_PATH}/javis_docker/dockerfiles/cuda/arm/deviceQuery

3. Build the docker `deviceQuery` image

        docker-compose-wrapper --env arch=arm -f dockerfiles/cuda/cuda.yml build deviceQuery

4. Run the docker `deviceQuery` image

        docker-compose-wrapper --env arch=arm -f dockerfiles/cuda/cuda.yml up deviceQuery
