# Day 1: Container Fundamentals

## Overview
Today's focus is on understanding container fundamentals and preparing to use Kubernetes effectively. We'll review Docker basics, containerize a Node.js app, and explore why Kubernetes is essential for container orchestration.

---

## Part 1: Quick Docker Review

### Verify Docker Installation
```bash
docker --version
docker info
```

### Test Docker Setup
```bash
docker run hello-world
```

### Core Concepts
| Concept | Description | Analogy |
|----------|--------------|----------|
| **Images** | Blueprints for containers. Built in layers, immutable and cached. | Like a **class** in JavaScript |
| **Containers** | Running instances of images. | Like an **object instance** |
| **Layers** | Incremental filesystem changes stacked to form an image. | Cached build history |

---

## Part 2: Containerize a Node.js App

### Step 1: Create a Node.js Application
```bash
# Create project directory
mkdir node-k8s-demo
cd node-k8s-demo

# Initialize npm
npm init -y

# Install Express
npm install express
```

### Step 2: Create `app.js`
```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello from Kubernetes!',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Step 3: Create `Dockerfile`
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
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

### Step 5: Build and Run the Container
```bash
docker build -t node-k8s-demo:v1 .
docker run -d -p 3000:3000 --name my-node-app node-k8s-demo:v1
curl http://localhost:3000
curl http://localhost:3000/health
docker logs my-node-app
docker stop my-node-app
docker rm my-node-app
```

---

## Part 3: Why Kubernetes?

Once your app runs in a container, managing it at scale becomes complex.

### Problems with Just Docker
```javascript
// What if you need to:
// 1. Run 10 instances (load balancing)
// 2. Auto-restart if one crashes
// 3. Update without downtime (rolling update)
// 4. Scale up/down based on traffic
// 5. Manage across 50 servers
// 6. Handle configurations, secrets, storage
```

### Kubernetes Solves:
✅ Orchestration  
✅ Self-healing  
✅ Scaling  
✅ Load balancing  
✅ Rolling updates  
✅ Service discovery  
✅ Storage orchestration  
✅ Configuration management  

**Analogy:**
- **Docker** = Managing a single async function.  
- **Kubernetes** = Managing an entire distributed system (like PM2, load balancers, health checks, and scaling combined).

---

## Homework

### Modify the App
Add a version endpoint:
```javascript
app.get('/version', (req, res) => {
  res.json({ version: '1.0.0' });
});
```

### Rebuild with v2 Tag
```bash
docker build -t node-k8s-demo:v2 .
```

### Run with Environment Variables
```bash
docker run -d -p 3000:3000 -e PORT=3000 -e NODE_ENV=production --name my-app node-k8s-demo:v2
```

### Practice Commands
```bash
docker ps
docker images
docker exec -it my-app sh
docker inspect my-app
```

### Reading
- **Kubernetes Overview:** “What is Kubernetes” section (official documentation)
