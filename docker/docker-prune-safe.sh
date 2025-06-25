#!/bin/bash

echo "🧼 This script will clean up Docker:"
echo "- Stopped containers"
echo "- Unused images (including untagged)"
echo "- Unused networks"
echo "- Volumes are not touched"
echo
echo "🕵️ Preview of what will be deleted:"

echo
echo "📦 Stopped containers:"
docker container ls -a -f status=exited

echo
echo "🧱 Unused images:"
docker images -f dangling=true

echo
echo "🌐 Unused networks:"
docker network ls | grep -v "bridge\|host\|none"

echo
read -p "⚠️ Proceed with cleanup (this will delete the above)? (yes/[no]): " confirm

if [ "$confirm" = "yes" ]; then
    echo
    echo "🚀 Running: docker system prune -a"
    docker system prune -a
    echo "✅ Done."
else
    echo "❌ Aborted. Nothing was deleted."
fi
