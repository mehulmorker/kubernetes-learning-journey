# Day 1: Container Fundamentals

Since you already have Docker installed, we'll quickly review the essentials and focus on concepts you need for Kubernetes.

## Part 1: Quick Docker Review (20 minutes)

Let's verify your Docker setup and refresh key concepts:

```bash
# Verify Docker installation
docker --version
docker info

# Test with a simple container
docker run hello-world
```

### Core Concepts to Understand:

- **Images** = Blueprint (like a class in JavaScript)
- **Containers** = Running instance (like an object instance)
- **Layers** = Images are built in layers (immutable, cached)

## Part 2: Containerize a Node.js App (40-60 minutes)

Let's create a simple Express.js app and containerize it - this will be your foundation for Kubernetes.

### Step 1: Create a simple Node.js application

```bash
# Create project directory
mkdir node-k8s-demo
cd node-k8s-demo

# Initialize npm
npm init -y

# Install Express
npm install express
```

### Step 2: Create app.js

```javascript
const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.json({
    message: "Hello from Kubernetes!",
    hostname: require("os").hostname(),
    timestamp: new Date().toISOString(),
  });
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy" });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Step 3: Create Dockerfile

```dockerfile
# Use official Node.js LTS image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "app.js"]
```

### Step 4: Create `.dockerignore`

```
node_modules
npm-debug.log
.git
.gitignore
README.md
```

### Step 5: Build and run your container

```bash
# Build the image
docker build -t node-k8s-demo:v1 .

# Run the container
docker run -d -p 3000:3000 --name my-node-app node-k8s-demo:v1

# Test it
curl http://localhost:3000
curl http://localhost:3000/health

# Check logs
docker logs my-node-app

# Stop and remove
docker stop my-node-app
docker rm my-node-app
```

## Part 3: Why Kubernetes? (15-20 minutes)

Now that you have a containerized app, let's understand why we need Kubernetes:

### Problems with just Docker:

```javascript
// Imagine you need to:
// 1. Run 10 instances of this app (load balancing)
// 2. Auto-restart if one crashes
// 3. Update to v2 without downtime (rolling update)
// 4. Scale up during high traffic, scale down after
// 5. Manage on 50 servers
// 6. Handle configurations, secrets, storage
```

### Kubernetes solves:

✅ **Orchestration** - Manages multiple containers across multiple machines  
✅ **Self-healing** - Automatically restarts failed containers  
✅ **Scaling** - Horizontal scaling (add/remove instances)  
✅ **Load balancing** - Distributes traffic automatically  
✅ **Rolling updates** - Zero-downtime deployments  
✅ **Service discovery** - Containers find each other automatically  
✅ **Storage orchestration** - Manages persistent data  
✅ **Configuration management** - Centralized config and secrets

### Think of it this way (JavaScript analogy):

- **Docker** = Managing a single async function
- **Kubernetes** = Managing an entire microservices architecture with PM2, load balancers, health checks, and auto-scaling

## 📝 Day 1 Homework (20-30 minutes)

### Modify the app to include version info:

```javascript
app.get("/version", (req, res) => {
  res.json({ version: "1.0.0" });
});
```

### Rebuild with v2 tag:

```bash
docker build -t node-k8s-demo:v2 .
```

### Experiment with environment variables:

```bash
docker run -d -p 3000:3000 -e PORT=3000 -e NODE_ENV=production --name my-app node-k8s-demo:v2
```

### Practice these commands:

```bash
docker ps                    # List running containers
docker images               # List images
docker exec -it my-app sh   # Get shell inside container
docker inspect my-app       # Detailed container info
```
