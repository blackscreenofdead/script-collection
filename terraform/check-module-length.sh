#!/bin/bash
# check-module-length.sh

file="$1"
grep -oP 'module\s+"\K[^"]+' "$file" | while read name; do
  len=${#name}
  if [ $len -gt 15 ]; then
    echo "❌ Fehler in Datei '$file': Modulname '$name' hat $len Zeichen (max. 15 erlaubt)"
  fi
done
