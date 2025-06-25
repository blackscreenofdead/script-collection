#!/bin/bash

echo "⚠️  WARNING: This will remove all unused Docker containers, images, networks, and volumes."
echo "It will not touch running containers, but stopped ones and dangling resources will be gone."
echo
read -p "Are you sure you want to continue? (yes/[no]): " confirm

if [ "$confirm" = "yes" ]; then
    echo "Running: docker system prune -a --volumes"
    docker system prune -a --volumes
    echo "✅ Docker system cleaned."
else
    echo "❌ Aborted. Nothing was changed."
fi
