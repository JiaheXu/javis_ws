# Fresh Robot Deployment Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the fresh JAVIS install path so Jetson Orin payload installs fail early with clear checks while preserving x86 basestation installs.

**Architecture:** Keep `javis-setup.bash` as the environment source entrypoint and `javis install` as the mutation entrypoint. Add low-risk Ansible preflight checks, improve platform-fact failure messages, lightly harden shell quoting, and update docs around the real Orin-first install flow.

**Tech Stack:** Bash, Ansible playbooks, Docker Compose configuration, Markdown docs.

---

### Task 1: Baseline Verification

**Files:**
- Inspect: `operations/javis_ansible/playbooks/misc/pre_run_checks.yaml`
- Inspect: `operations/javis_ansible/playbooks/facts/platform_facts.yaml`
- Inspect: `javis-setup.bash`
- Inspect: `operations/javis_utils/scripts/javis-install`

- [ ] **Step 1: Run baseline Bash syntax checks**

Run:
```bash
bash -n javis-setup.bash
bash -n operations/javis_utils/scripts/javis-install
```
Expected: both commands exit 0.

- [ ] **Step 2: Run baseline Ansible syntax checks**

Run:
```bash
cd operations/javis_ansible
ansible-playbook --syntax-check -i localhost, playbooks/install.yaml
ansible-playbook --syntax-check -i localhost, playbooks/install_min.yaml
ansible-playbook --syntax-check -i localhost, playbooks/install_global.yaml
```
Expected: syntax checks exit 0. If they fail on pre-existing Ansible compatibility issues, record the exact failure and continue with narrower file-level validation after edits.

### Task 2: Ansible Preflight And Platform Hardening

**Files:**
- Modify: `operations/javis_ansible/playbooks/misc/pre_run_checks.yaml`
- Modify: `operations/javis_ansible/playbooks/facts/platform_facts.yaml`

- [ ] **Step 1: Add workspace sanity checks before apt mutation**

In `pre_run_checks.yaml`, before `apt update`, check that `javis_path` or `JAVIS_PATH` resolves to the workspace and that required operations paths exist. Fail with messages naming the missing path.

- [ ] **Step 2: Add required command checks**

In `pre_run_checks.yaml`, check target-side commands `git`, `ssh`, `python3`, and `pip3`. Check Docker commands without failing immediately on hosts where Ansible is expected to install Docker. Do not require `ansible` on remote targets; the wrapper installs/checks it on the controller before the playbook starts.

- [ ] **Step 3: Improve Jetson fact failures**

In `platform_facts.yaml`, keep the current fact names but add clearer failures for `aarch64` hosts where `tegrastats` or `/etc/nv_tegra_release` is missing, and report detected platform data before failing.

- [ ] **Step 4: Validate Ansible syntax**

Run:
```bash
cd operations/javis_ansible
ansible-playbook --syntax-check -i localhost, playbooks/install.yaml
ansible-playbook --syntax-check -i localhost, playbooks/install_min.yaml
ansible-playbook --syntax-check -i localhost, playbooks/install_global.yaml
```
Expected: syntax checks exit 0 or only show baseline pre-existing failures.

### Task 3: Shell Safety Cleanup

**Files:**
- Modify: `javis-setup.bash`
- Modify: `operations/javis_utils/scripts/javis-install`

- [ ] **Step 1: Quote path variables in touched hot paths**

Quote path variables used by `cat`, `source`, `mkdir`, `cd`, `pathadd`, and file tests in the top-level setup and installer flow. Do not rewrite the whole argument parser.

- [ ] **Step 2: Fix obvious user-facing typos in touched messages**

Fix misspellings such as `procede`, `Attenting`, and `Varibale` only in touched installer/preflight areas.

- [ ] **Step 3: Validate Bash syntax**

Run:
```bash
bash -n javis-setup.bash
bash -n operations/javis_utils/scripts/javis-install
```
Expected: both commands exit 0.

### Task 4: Fresh Install Documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/getting_started.md`
- Create: `docs/fresh_install_checklist.md`
- Modify: `operations/javis_ansible/README.md`

- [ ] **Step 1: Replace the top-level README placeholder**

Add a short repo orientation and link to fresh install, getting started, launch, host management, and troubleshooting docs.

- [ ] **Step 2: Add Orin-first fresh install checklist**

Create `docs/fresh_install_checklist.md` with the supported install order, Orin checks, x86 differences, and non-destructive verification commands.

- [ ] **Step 3: Update getting started and Ansible docs**

Make `docs/getting_started.md` point at the checklist and explain the current `javis install`, `--global`, and `--payload` sequence. Update `operations/javis_ansible/README.md` with installer ownership and preflight behavior.

- [ ] **Step 4: Verify docs references**

Run:
```bash
rg -n "mmpug|MMPUg|fresh_install_checklist|javis install --payload|pre_run_checks" README.md docs operations/javis_ansible/README.md
```
Expected: remaining `mmpug` references are either removed from touched install docs or intentionally outside this first reliability pass.

### Task 5: Final Verification

**Files:**
- Verify all modified files.

- [ ] **Step 1: Run final syntax checks**

Run:
```bash
bash -n javis-setup.bash
bash -n operations/javis_utils/scripts/javis-install
cd operations/javis_ansible
ansible-playbook --syntax-check -i localhost, playbooks/install.yaml
ansible-playbook --syntax-check -i localhost, playbooks/install_min.yaml
ansible-playbook --syntax-check -i localhost, playbooks/install_global.yaml
```
Expected: commands exit 0 or any failure is clearly identified as pre-existing from Task 1.

- [ ] **Step 2: Review git diff**

Run:
```bash
git diff --stat
git diff -- README.md docs/fresh_install_checklist.md docs/getting_started.md operations/javis_ansible/README.md operations/javis_ansible/playbooks/misc/pre_run_checks.yaml operations/javis_ansible/playbooks/facts/platform_facts.yaml javis-setup.bash operations/javis_utils/scripts/javis-install
```
Expected: changes are limited to the plan scope.
