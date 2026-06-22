# Fresh Robot Deployment Reliability Design

## Context

The JAVIS workspace is deployed across Jetson Orin payload computers and x86 basestation or development machines. The same workspace supports both targets, but installation choices differ based on the selected system parameters and detected platform facts.

The first reliability pass will focus on fresh Jetson Orin installs while keeping the x86 path working. The existing Jetson Docker image choices in the repository are the source of truth. This work will not introduce a JetPack or L4T compatibility matrix.

Current entrypoints stay in place:

- `javis-setup.bash` sources the workspace environment, exports paths, adds tools to `PATH`, and reports install/version warnings.
- `javis install` runs the Ansible installer through `operations/javis_utils/scripts/javis-install`.
- `operations/javis_ansible/playbooks/*` owns host mutation, platform facts, config generation, and package setup.
- `operations/javis_docker/*` owns Docker image build and runtime configuration.

## Goals

- Make fresh installs fail early with clear, actionable errors.
- Treat Jetson Orin as the critical path for reliability.
- Preserve support for x86 basestation and development installs.
- Document one repeatable fresh-install path for Orin payloads, with x86 differences called out.
- Keep changes narrow and compatible with the current installer architecture.

## Non-Goals

- Do not redesign the installer CLI.
- Do not move all install behavior out of `javis-setup.bash` in this pass.
- Do not add support for older Jetson images beyond the images already selected in the repository.
- Do not run destructive install commands on a developer workstation during verification unless explicitly requested.
- Do not refactor Docker compose services or image naming beyond checks needed for install reliability.

## Proposed Approach

Use a preflight-first hardening pass.

The installer should validate the host and workspace before performing expensive or confusing system changes. The first implementation should expand the existing `operations/javis_ansible/playbooks/misc/pre_run_checks.yaml` phase because it is already included near the start of `install.yaml`, `install_min.yaml`, and `install_global.yaml`.

Documentation should be updated in the same pass so the expected flow is visible before the operator runs commands.

## Installation Flow

The documented fresh-install flow should be:

1. Clone the workspace and required submodules.
2. Source `./javis-setup.bash`.
3. Run `javis install` for local tools and base dependencies.
4. Run `javis install --global` and select the correct system identity.
5. For payloads, run `javis install --payload` when `/etc/payload` identity needs to be configured.
6. Reboot if Docker group membership, services, or NVIDIA runtime changes require it.
7. Source the shell again and run verification commands.
8. Build or pull Docker images through the existing deployer flow.

The guide should make clear that Orin payloads and x86 basestations share the same commands but diverge through detected platform facts and selected system parameters.

## Preflight Checks

Preflight checks should validate these categories before the main install proceeds.

### Workspace Sanity

- `JAVIS_PATH` points at the current workspace.
- Required operations directories exist:
  - `operations/javis_ansible`
  - `operations/javis_deploy`
  - `operations/javis_docker`
  - `operations/javis_utils`
- Required installer scripts exist:
  - `operations/javis_utils/scripts/javis-install`
  - `operations/javis_deploy/automate/javis`
- Required Docker compose files exist:
  - `operations/javis_docker/docker-compose.yml`
  - `operations/javis_docker/javis/docker-compose.yml`

### Platform Classification

- Report the detected hostname, username, Ubuntu release, architecture, GPU state, Jetson state, and resolved `javis_arch_type`.
- Fail if the host cannot be classified as one of:
  - `arm-tegra-gpu`
  - `x86-nvidia-gpu`
  - `x86-non-gpu`

### Jetson Orin Critical Path

For Orin installs, validate:

- `uname -m` returns `aarch64`.
- `tegrastats` is available.
- `/etc/nv_tegra_release` exists and is readable.
- Docker is available or the error explains that the selected Jetson image must provide a usable Docker install.
- NVIDIA/Jetson device paths needed by compose are present enough to catch obvious broken base images before launch.
- The generated facts include `JAVIS_L4T_VERSION` when applicable.

### x86 Path

For x86 installs, validate:

- Docker repository setup is available when Docker is being installed.
- NVIDIA Docker setup only runs on x86 GPU hosts.
- Non-GPU x86 hosts are classified as `x86-non-gpu` and do not receive GPU-only install expectations.

### Config Path Sanity

Validate or clearly report:

- `~/.javis/auto`
- `~/.javis/auto/deploy.conf`
- `~/.javis/auto/install.conf`
- `/etc/javis/javis.conf`
- `/etc/javis/payload.conf` when payload identity is configured

## Post-Install Verification

Add a documented verification checklist in this pass. A dedicated read-only verification command can be added later after the checklist has been used on a real Orin image.

The checklist should include:

- `source ./javis-setup.bash`
- `echo "$JAVIS_PATH"`
- `echo "$JAVIS_HOST_TYPE"`
- `echo "$JAVIS_ARCH_T"`
- `docker --version`
- `docker ps`
- `docker-compose --version` or the documented compose equivalent used by this repo
- `hit params` when host info tools are installed
- `javis hosts` on basestations after global setup
- `javis deployer local.make` or the appropriate build/pull command documented for the target

For Orin, the checklist should also verify that image names resolve through the existing variables to the expected `javis/arm...` family.

## Documentation Changes

Update documentation in these places:

- `README.md`: replace the placeholder with a short orientation and links to fresh install, build, launch, and troubleshooting docs.
- `docs/getting_started.md`: make the current install path accurate for JAVIS and remove stale or confusing wording where it affects install reliability.
- `docs/fresh_install_checklist.md`: add the Orin-first fresh-install checklist, with x86 differences called out inline.
- `operations/javis_ansible/README.md`: explain installer ownership, platform facts, preflight checks, and the difference between `install`, `install --global`, and `install --payload`.

## Error Handling

Errors should tell the operator:

- What check failed.
- What value was observed.
- Why it matters.
- What command or setup step is likely needed next.

Avoid silent fallback for platform classification and required workspace paths. A failed Orin classification should stop the install before Docker image work begins.

## Testing And Verification

Use non-destructive verification first:

- Run Ansible syntax checks for touched playbooks.
- Run Bash syntax checks for touched shell scripts.
- Source `javis-setup.bash` locally with checks suppressed when validating syntax-only behavior.
- Review generated docs for command consistency.

Do not run full `javis install`, Docker image builds, Docker image removals, or service-changing commands on the current workstation unless explicitly approved.

## Rollout Plan

1. Add or expand preflight checks in Ansible.
2. Update docs so the fresh install path matches the real installer flow.
3. Run syntax and local smoke verification.
4. Use the checklist on the next available Jetson Orin fresh image.
5. Capture any Orin-only failures as follow-up checks rather than broad refactors.

## Deferred Decisions

- A separate preflight playbook can be introduced later if `misc/pre_run_checks.yaml` becomes too large or starts mixing unrelated responsibilities.
- A dedicated `javis install --check` mode is deferred until after the first Orin validation run.
