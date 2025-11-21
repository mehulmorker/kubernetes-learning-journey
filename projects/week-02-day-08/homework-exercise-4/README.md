# Exercise 4: Label-Based Resource Management

This exercise provides a script to manage Kubernetes resources by environment using labels.

## Script

`manage-env.sh` - A bash script for managing resources by environment label

## Usage

```bash
# Make script executable
chmod +x manage-env.sh

# List all resources in an environment
./manage-env.sh production list

# Scale up all deployments in an environment
./manage-env.sh production scale-up

# Scale down all deployments in an environment
./manage-env.sh production scale-down

# Delete all resources in an environment (with confirmation)
./manage-env.sh development delete
```

## Actions

- **list**: List all resources with the specified environment label
- **scale-up**: Scale all deployments to 5 replicas
- **scale-down**: Scale all deployments to 1 replica
- **delete**: Delete all resources (requires confirmation)

## Prerequisites

Resources must have an `environment` label matching the environment name:

```yaml
metadata:
  labels:
    environment: production
```

## Examples

```bash
# List all development resources
./manage-env.sh development list

# Scale up staging deployments
./manage-env.sh staging scale-up

# Scale down production (be careful!)
./manage-env.sh production scale-down

# Delete development environment
./manage-env.sh development delete
```

## Safety Features

- Delete action requires explicit "yes" confirmation
- Clear error messages for invalid inputs
- Lists resources before destructive operations


