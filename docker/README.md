# 🧼 docker-prune-safe.sh

A safe Docker cleanup script with preview and confirmation – designed to help you remove unused resources without nasty surprises.

---

## 🔍 What it does

This script provides a **preview of what will be deleted** using `docker system prune -a`, including:

- 📦 Stopped containers  
- 🧱 Unused Docker images (including dangling/untagged)  
- 🌐 Unused Docker networks (excluding `bridge`, `host`, `none`)  
- ❌ **Volumes are NOT deleted**

Only after confirmation will the actual cleanup be performed.

---

## 🧪 Example usage

```bash
wget https://github.com/blackscreenofdead/script-collection/blob/main/docker/docker-prune-safe.sh
chmod +x docker-prune-safe.sh
./docker-prune-safe.sh
```
## 🧪 Example Output
```
🧼 This script will clean up Docker:
- Stopped containers
- Unused images (including untagged)
- Unused networks
- Volumes are not touched

🕵️ Preview of what will be deleted:

📦 Stopped containers:
<container list>

🧱 Unused images:
<image list>

🌐 Unused networks:
<network list>

⚠️ Proceed with cleanup (this will delete the above)? (yes/[no]):

```
If you type yes, the following will be run:

docker system prune -a

⚠️ Notes
This script does not delete Docker volumes. If you also want to remove unused volumes, use:

docker system prune -a --volumes
