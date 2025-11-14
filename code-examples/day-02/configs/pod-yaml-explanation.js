// Think of it like this JavaScript object:
const pod = {
  apiVersion: 'v1',          // API version to use
  kind: 'Pod',               // Type of resource
  metadata: {
    name: 'node-app-pod',    // Unique name
    labels: {                // Key-value pairs for organization
      app: 'node-demo',
      version: 'v1'
    }
  },
  spec: {                    // Specification/desired state
    containers: [{
      name: 'node-app',
      image: 'node-k8s-demo:v1',
      ports: [{ containerPort: 3000 }],
      env: [
        { name: 'NODE_ENV', value: 'production' }
      ]
    }]
  }
};

