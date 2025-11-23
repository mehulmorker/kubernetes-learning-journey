# Day 01: Container Fundamentals - Interview Questions

## 1. What is the difference between a Docker image and a Docker container?

**Answer:**
- **Docker Image**: A read-only template or blueprint used to create containers. It contains the application code, dependencies, libraries, and configuration files. Images are built from Dockerfiles and stored in layers.
- **Docker Container**: A running instance of an image. Containers are created from images and have a writable layer on top of the read-only image layers. Multiple containers can be created from the same image.

**Analogy**: Think of an image as a class definition in programming (like a JavaScript class), and a container as an object instance created from that class.

---

## 2. Explain the concept of Docker image layers and why they are important.

**Answer:**
Docker images are built in layers, where each instruction in a Dockerfile creates a new layer. Layers are:
- **Immutable**: Once created, they cannot be changed
- **Cached**: Docker caches layers, so if a layer hasn't changed, it can be reused
- **Layered**: Each layer builds on top of the previous one

**Benefits:**
- Faster builds (cached layers don't need to be rebuilt)
- Smaller image sizes (shared layers across images)
- Efficient storage (Docker uses copy-on-write)

**Example:**
```dockerfile
FROM node:18-alpine        # Layer 1: Base image
WORKDIR /app              # Layer 2: Working directory
COPY package*.json ./     # Layer 3: Dependencies file
RUN npm install           # Layer 4: Install dependencies
COPY . .                  # Layer 5: Application code
CMD ["node", "app.js"]    # Layer 6: Command
```

---

## 3. Multiple Choice: What happens when you run `docker build -t myapp:v1 .`?

A. Creates a new container from the image  
B. Builds a Docker image from the Dockerfile in the current directory  
C. Runs a container with the name myapp:v1  
D. Pushes the image to Docker Hub

**Answer: B**

**Explanation:** The `docker build` command builds a Docker image from a Dockerfile. The `-t` flag tags the image with the name `myapp:v1`, and the `.` specifies the build context (current directory).

---

## 4. Why do we need Kubernetes when we already have Docker?

**Answer:**
Docker solves containerization, but Kubernetes solves orchestration:

**Problems Docker alone can't solve:**
- **Scaling**: How to run 10 instances of an app across multiple servers?
- **Self-healing**: What if a container crashes? Docker won't restart it automatically.
- **Load balancing**: How to distribute traffic across multiple containers?
- **Rolling updates**: How to update an app without downtime?
- **Service discovery**: How do containers find each other?
- **Storage orchestration**: How to manage persistent data across containers?
- **Configuration management**: How to manage configs and secrets centrally?

**Kubernetes provides:**
- Automatic container scheduling and distribution
- Self-healing (restarts failed containers)
- Horizontal scaling
- Load balancing and service discovery
- Rolling updates and rollbacks
- Persistent storage management
- Configuration and secret management

---

## 5. Multiple Choice: Which Dockerfile instruction is used to set environment variables?

A. `ENV`  
B. `ARG`  
C. `EXPOSE`  
D. `WORKDIR`

**Answer: A**

**Explanation:** 
- `ENV` sets environment variables that are available to containers at runtime
- `ARG` sets build-time variables (not available at runtime)
- `EXPOSE` documents which ports the container listens on
- `WORKDIR` sets the working directory

---

## 6. Explain the purpose of `.dockerignore` file.

**Answer:**
The `.dockerignore` file tells Docker which files and directories to exclude from the build context when building an image. This is similar to `.gitignore` but for Docker builds.

**Benefits:**
- **Faster builds**: Smaller build context means faster upload to Docker daemon
- **Smaller images**: Excludes unnecessary files from the image
- **Security**: Prevents sensitive files (like `.env`, credentials) from being included
- **Efficiency**: Excludes large files like `node_modules`, `.git`, etc.

**Example `.dockerignore`:**
```
node_modules
npm-debug.log
.git
.gitignore
.env
*.md
.DS_Store
```

---

## 7. Scenario: You have a Node.js application that needs to run on port 3000. Write a minimal Dockerfile for it.

**Answer:**
```dockerfile
# Use official Node.js LTS image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files first (for better layer caching)
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

**Key points:**
- Copy `package*.json` before copying code to leverage Docker layer caching
- Use `--production` flag to install only production dependencies
- `EXPOSE` documents the port but doesn't publish it
- `CMD` specifies the default command to run

---

## 8. Multiple Choice: What is the difference between `CMD` and `ENTRYPOINT` in a Dockerfile?

A. `CMD` is for build-time, `ENTRYPOINT` is for runtime  
B. `CMD` can be overridden, `ENTRYPOINT` cannot  
C. `CMD` provides default arguments, `ENTRYPOINT` sets the executable  
D. There is no difference

**Answer: C**

**Explanation:**
- `ENTRYPOINT` sets the main command that will always run (the executable)
- `CMD` provides default arguments to the `ENTRYPOINT` (can be overridden)
- When both are used: `ENTRYPOINT ["docker-entrypoint.sh"]` + `CMD ["--help"]` = `docker-entrypoint.sh --help`
- `CMD` can be overridden when running `docker run`, but `ENTRYPOINT` cannot (unless using `--entrypoint` flag)

---

## 9. Explain the container lifecycle in Docker.

**Answer:**
A container goes through several states:

1. **Created**: Container is created but not started (`docker create`)
2. **Running**: Container is actively running (`docker start` or `docker run`)
3. **Paused**: Container is paused (suspended) (`docker pause`)
4. **Stopped**: Container is stopped but not removed (`docker stop`)
5. **Removed**: Container is deleted (`docker rm`)

**Common commands:**
- `docker create`: Creates a container without starting it
- `docker start`: Starts a stopped container
- `docker stop`: Gracefully stops a running container (SIGTERM, then SIGKILL)
- `docker kill`: Immediately stops a container (SIGKILL)
- `docker pause`: Pauses a container (freezes all processes)
- `docker unpause`: Resumes a paused container
- `docker rm`: Removes a stopped container

---

## 10. Multiple Choice: Which command is used to view logs from a running container?

A. `docker logs <container>`  
B. `docker view <container>`  
C. `docker show <container>`  
D. `docker inspect <container>`

**Answer: A**

**Explanation:**
- `docker logs` shows the logs from a container
- `docker inspect` shows detailed information about a container/image
- There are no `docker view` or `docker show` commands

---

## 11. What is the purpose of multi-stage builds in Docker, and when should you use them?

**Answer:**
Multi-stage builds allow you to use multiple `FROM` statements in a single Dockerfile, where each stage can have its own base image and dependencies.

**Benefits:**
- **Smaller final images**: Only include what's needed for runtime
- **Security**: Exclude build tools and dependencies from production image
- **Efficiency**: Build artifacts in one stage, copy only needed files to final stage

**Example:**
```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
RUN npm install --production
CMD ["node", "dist/index.js"]
```

**When to use:**
- When you need build tools but not in production
- When you want to minimize image size
- When building compiled languages (Go, Rust, etc.)

---

## 12. Scenario: Your containerized application needs to read a configuration file. How would you provide this file to the container?

**Answer:**
Multiple approaches:

**Method 1: Copy during build (static config)**
```dockerfile
COPY config.json /app/config.json
```

**Method 2: Volume mount (dynamic config)**
```bash
docker run -v /host/path/config.json:/app/config.json myapp
```

**Method 3: Environment variables**
```bash
docker run -e CONFIG_PATH=/app/config.json myapp
```

**Method 4: Bind mount (for development)**
```bash
docker run -v $(pwd)/config.json:/app/config.json myapp
```

**Best practice:** For production, use Kubernetes ConfigMaps/Secrets instead of bind mounts.

---

## 13. Multiple Choice: What does `docker run -d -p 3000:3000 myapp` do?

A. Builds an image named myapp  
B. Runs a container in detached mode, mapping port 3000  
C. Stops a running container  
D. Removes a container

**Answer: B**

**Explanation:**
- `-d` (detached): Runs container in background
- `-p 3000:3000`: Maps host port 3000 to container port 3000 (host:container)
- `myapp`: Image name to run

---

## 14. Explain the difference between `docker exec` and `docker attach`.

**Answer:**

**`docker exec`:**
- Runs a new command in a running container
- Creates a new process
- Doesn't affect the main container process
- Example: `docker exec -it mycontainer sh`

**`docker attach`:**
- Attaches to the main process (PID 1) of the container
- Shows the output of the main process
- If you exit (Ctrl+C), it may stop the container
- Example: `docker attach mycontainer`

**Best practice:** Use `docker exec` for debugging and running additional commands. Use `docker attach` only when you need to see the main process output interactively.

---

## 15. What are the key advantages of containerization over traditional virtualization?

**Answer:**

| Aspect | Containers | Virtual Machines |
|--------|-----------|------------------|
| **Resource usage** | Lightweight, shares host OS | Heavy, requires full OS |
| **Startup time** | Seconds | Minutes |
| **Isolation** | Process-level | Hardware-level |
| **Overhead** | Minimal | Significant |
| **Portability** | High (same OS) | Medium (needs hypervisor) |
| **Density** | High (many containers per host) | Low (few VMs per host) |

**Key advantages:**
- **Faster deployment**: Containers start in seconds vs minutes for VMs
- **Resource efficiency**: Better utilization of host resources
- **Consistency**: Same environment across dev, staging, prod
- **Microservices**: Perfect for microservices architecture
- **Scalability**: Easy to scale horizontally

**Use VMs when:**
- You need different operating systems
- Strong isolation is required
- Running legacy applications
- Compliance requires hardware-level isolation

