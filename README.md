# Vagrant Lab

Hands-on lab: build a Vagrant-ready Docker base image, package it as a
versioned box, and run web, multi-machine cluster, Ansible, fleet, and
troubleshooting drills with the Vagrant **docker** provider.

## Layout
- `image/`        – Dockerfile + SSH keypair (private key not committed)
- `boxes/`        – `publish-box.sh` and generated catalogue
- `first/`        – first single machine using the built image
- `web/`          – nginx site with synced folder + forwarded port
- `cluster/`      – app1/app2/lb on a private Docker network
- `cluster/ansible/` – Ansible playbook replacing the shell provisioner
- `fleet/`        – YAML-driven fleet + host-side and guest-side triggers
- `troubleshoot/` – intentionally broken project used for drills

## Prereqs
See the environment setup steps (Docker, Vagrant 2.4.x, bsdtar, jq,
Python 3 venv with ansible-core 2.17.x).

## Quickstart
```bash
source ~/vagrant-lab/.venv/bin/activate   # required for Ansible task
cd ~/vagrant-lab/<subdir>
vagrant up
