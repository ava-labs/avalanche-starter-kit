# Local Development Setup

While this repository is optimized for GitHub Codespaces, you can also run it locally. This guide provides the necessary steps for local setup.

## Prerequisites

- [Git](https://git-scm.com/downloads)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Docker](https://docs.docker.com/get-docker/)

## Setup Instructions

1. Clone the repository:
```bash
git clone https://github.com/your-username/avalanche-starter-kit.git
cd avalanche-starter-kit
```

2. Install dependencies:
```bash
forge install
```

3. Follow the setup instructions in [CODESPACE.md](./CODESPACE.md), starting from the "Environment Setup" section.

## Important Notes

- Ensure Docker is running before starting the ICM relayer
- All commands in CODESPACE.md will work the same way locally
- Your local environment must have all the required tools installed and properly configured 