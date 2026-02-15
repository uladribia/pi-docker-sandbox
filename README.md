# Pi Agent Sandbox

This repository contains a Docker-based sandbox environment for running the Pi Coding Agent securely.

## Overview

The sandbox isolates the agent inside a Docker container. This prevents it from accessing your entire filesystem or sensitive data outside the project directory you are working on.

## Prerequisites

You must have Docker installed on your system.

### Install Docker (Ubuntu/Debian)

Since the agent cannot run `sudo` commands interactively, please run the following commands in your terminal:

```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
newgrp docker
```

Verify the installation:
```bash
docker --version
docker run hello-world
```

## Installation

The sandbox script `pi-sandboxed` has been added to your `~/.local/bin/` directory. Ensure this directory is in your `PATH`.

To build the sandbox image for the first time, simply run:

```bash
pi-sandboxed --help
```

This will automatically detect that the image is missing and build it from the `Dockerfile` in this repository.

## Usage

Navigate to any project directory you want the agent to work on:

```bash
cd ~/my-project
pi-sandboxed
```

This command will:
1.  Start a Docker container.
2.  Mount the current directory (`~/my-project`) to `/workspace` inside the container.
3.  Start the Pi agent within that isolated environment.

## Limitations & Security

*   **Filesystem Isolation**: The agent can **only** see and modify files within the directory where you ran `pi-sandboxed`. It cannot access your home directory, system files, or other projects.
*   **Tool Availability**: The agent is limited to tools installed in the `Dockerfile` (Node.js, Python, Git, etc.). If you need additional tools (e.g., `rustc`, `go`), you must edit the `Dockerfile` and rebuild the image.
*   **Root Access**: The agent runs as a non-root user (`piuser`) inside the container. It cannot install new system packages or modify container system files.
*   **Persistence**: Any files created in the mounted directory persist on your host machine. However, changes to the container itself (like installing a package with `npm install -g`) are lost when the session ends.

## Customization

To add more tools to the agent's environment, edit `Dockerfile` in this repository and run:

```bash
./build.sh
```
