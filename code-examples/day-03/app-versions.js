// Node.js app versions for rolling update practice

// v1: message: "Version 1"
const appV1 = {
  message: "Version 1",
  version: "1.0.0"
};

// v2: message: "Version 2"
const appV2 = {
  message: "Version 2",
  version: "2.0.0"
};

// v3: message: "Version 3"
const appV3 = {
  message: "Version 3",
  version: "3.0.0"
};

// Production problems example
const productionProblems = {
  podCrashes: "App crashes, Pod dies, no auto-restart",
  nodeFailure: "Server dies, all Pods on it are lost",
  scaling: "Need 10 copies? Create 10 Pods manually?",
  updates: "How to update without downtime?",
  rollback: "New version broken? Manually recreate old Pods?",
  selfHealing: "No automatic recovery"
};

// Deployment structure example
const deployment = {
  metadata: {
    name: 'node-app-deployment'  // Deployment name
  },
  spec: {
    replicas: 3,                  // How many Pods
    selector: {
      matchLabels: { app: 'node-demo' }  // Find Pods with this label
    },
    template: {                   // Pod blueprint
      metadata: {
        labels: { app: 'node-demo' }     // Label for selector
      },
      spec: {
        containers: [/* container spec */]
      }
    }
  }
};

// Kubernetes way mindset
const kubernetesWay = {
  never: "Manually create Pods",
  always: "Use Deployments (or other controllers)",
  because: "Controllers provide self-healing, scaling, and updates",
  remember: "Declare desired state, let Kubernetes make it happen"
};

