#!/bin/bash
# Verify Docker installation

echo "Checking Docker version..."
docker --version

echo "Checking Docker info..."
docker info

echo "Testing with hello-world container..."
docker run hello-world

