# Fresh Install Checklist

This checklist is for installing JAVIS on a fresh robot computer. Jetson Orin payloads are the critical path; x86 basestation differences are called out where they matter.

The supported Jetson image and Docker base image choices are the ones already configured in this repository. Do not mix this checklist with a separate JetPack or L4T compatibility matrix unless the Docker files are updated at the same time.

## 1. Before Running The Installer

On the target machine:

```bash
uname -m
lsb_release -a
```

Expected:

- Jetson Orin payload: `uname -m` is `aarch64`.
- x86 basestation/development machine: `uname -m` is `x86_64`.

For Jetson Orin, also check:

```bash
tegrastats --help
test -r /etc/nv_tegra_release && cat /etc/nv_tegra_release
docker --version
```

If `tegrastats` or `/etc/nv_tegra_release` is missing on Orin, stop and fix the base image first. The JAVIS installer uses these facts to classify the host as `arm-tegra-gpu`.

## 2. Clone Workspace And Operations Submodules

```bash
cd ~
git clone git@github.com:JiaheXu/javis_ws.git javis_ws
cd ~/javis_ws
git submodule update --init --recursive operations
```

If you need source workspaces for development or local builds, initialize the required `src/*` submodules after `operations` is present.

The installer preflight expects these paths to exist:

```text
operations/javis_ansible
operations/javis_deploy
operations/javis_docker
operations/javis_utils
operations/javis_utils/scripts/javis-install
operations/javis_deploy/automate/javis
operations/javis_docker/docker-compose.yml
operations/javis_docker/javis/docker-compose.yml
```

## 3. Source The Workspace

```bash
cd ~/javis_ws
source ./javis-setup.bash
```

On a fresh machine this may print warnings because the install has not run yet. That is expected. The important result is that the `javis` shell function becomes available.

Check:

```bash
type javis
echo "$JAVIS_PATH"
```

## 4. Install Local Dependencies

```bash
javis install
```

This runs the Ansible install path. The preflight checks run first and should fail early if the workspace path, required operation submodules, bootstrap commands, or platform facts are wrong.

If you run the installer from a basestation against a remote robot and the workspace is not at the same path as the basestation checkout, pass the target path explicitly:

```bash
javis install --ws-path /home/<robot-user>/javis_ws -- <robot-hostname>
```

For x86, this path may install Docker and Docker tooling.

For Jetson Orin, Docker and NVIDIA runtime support are expected to match the selected Jetson image. The installer should not silently treat an unrecognized `aarch64` host as a valid Orin payload.

## 5. Configure Host Identity

Run global configuration:

```bash
javis install --global
```

Choose values based on the machine role:

```text
Jetson Orin payload:
  JAVIS System Type: spot, rc, or mapping
  JAVIS System Component: orin

x86 basestation/development machine:
  JAVIS System Type: basestation
  JAVIS System Component: dev
```

Use a unique ROS-safe System ID. Spaces and dashes are sanitized to underscores by the installer.

## 6. Configure Payload Identity

On payload computers, configure `/etc/payload` identity:

```bash
javis install --payload
```

Use the same payload serial for computers mounted in the same payload. Use the payload type that matches the hardware package.

Basestations normally skip this step.

## 7. Reboot When Needed

Reboot after first install if Docker group membership, services, or NVIDIA runtime configuration changed:

```bash
sudo reboot
```

After reboot:

```bash
cd ~/javis_ws
source ./javis-setup.bash
```

## 8. Verify The Install

Run:

```bash
echo "$JAVIS_PATH"
echo "$JAVIS_ARCH_T"
echo "$JAVIS_HOST_TYPE"
echo "$JAVIS_SYSTEM_ID"
echo "$JAVIS_SYSTEM_TYPE"
echo "$JAVIS_SYSTEM_COMPONENT"
docker --version
docker ps
```

Expected host type values:

```text
Jetson Orin payload: arm-tegra-gpu
x86 GPU machine: x86-nvidia-gpu
x86 non-GPU machine: x86-non-gpu
```

If host info tools are installed:

```bash
hit params
javis hosts
```

`javis hosts` is most useful from a basestation after payloads have been installed and are on the same network.

## 9. Build Or Pull Docker Images

Use the existing deployer flow:

```bash
javis deployer local.make
```

For Orin, image names should resolve through the existing environment variables into the `javis/arm...` family. Check the values before building if the wrong architecture appears:

```bash
echo "$JAVIS_ARCH_T"
echo "$JAVIS_HOST_TYPE"
echo "$DOCKER_IMAGE_VERSION"
```

## 10. Launch Smoke Test

List available launch configurations:

```bash
javis launch --list
```

Launch locally only after install verification and Docker image setup are clean:

```bash
javis launch
```

For remote payload launch examples, see [howto_launch.md](howto_launch.md).
