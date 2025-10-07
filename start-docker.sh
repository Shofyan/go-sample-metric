#!/bin/bash

# Go Sample Metric Docker Startup Script
# This script builds and starts all services using Docker Compose

set -e

echo "🚀 Starting Go Sample Metric with Docker Compose..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose > /dev/null 2>&1 && ! docker compose version > /dev/null 2>&1; then
    echo "❌ Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Function to clean up on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down services..."
    if command -v docker-compose > /dev/null 2>&1; then
        docker-compose down
    else
        docker compose down
    fi
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

# Build and start all services
echo "🔨 Building and starting services..."
if command -v docker-compose > /dev/null 2>&1; then
    docker-compose up --build
else
    docker compose up --build
fi