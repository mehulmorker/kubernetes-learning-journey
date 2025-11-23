# Namespace Manager Script

A simple bash script to manage Kubernetes namespaces.

## Usage

```bash
./namespace-manager.sh {create|list|quota|cleanup} <namespace>
```

## Commands

### create
Creates a new namespace and labels it with `environment=<namespace>`.

```bash
./namespace-manager.sh create development
```

### list
Lists all resources in the specified namespace.

```bash
./namespace-manager.sh list development
```

### quota
Shows resource quotas for the specified namespace.

```bash
./namespace-manager.sh quota development
```

### cleanup
Deletes the namespace and all resources in it. **Use with caution!**

```bash
./namespace-manager.sh cleanup development
```

## Examples

```bash
# Create namespaces for different environments
./namespace-manager.sh create dev
./namespace-manager.sh create staging
./namespace-manager.sh create prod

# List resources in dev namespace
./namespace-manager.sh list dev

# Check quotas
./namespace-manager.sh quota dev

# Clean up (with confirmation)
./namespace-manager.sh cleanup dev
```

## Permissions

Make the script executable:

```bash
chmod +x namespace-manager.sh
```

## Notes

- The script requires `kubectl` to be installed and configured
- The `cleanup` command requires confirmation before deletion
- All commands require a namespace name as the second argument


