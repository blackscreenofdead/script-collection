#!/bin/bash
echo "$(date +%T) Prüfe auf Duplikate..."
files=("$@")
keys=("vlan-id" "vlan-subnet" "ip6-address" "vlan-name")

declare -A seen_module_name
declare -A dup_module_name

declare -A seen_vlan_id
declare -A seen_vlan_subnet
declare -A seen_ip6_address
declare -A seen_vlan_name

declare -A dup_vlan_id
declare -A dup_vlan_subnet
declare -A dup_ip6_address
declare -A dup_vlan_name

for file in "${files[@]}"; do
  inside_module=0
  current_module=""
  current_source_valid=0
  declare -A current_values

  while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    line="$(echo "$raw_line" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue

    # Modulstart
    if [[ $line =~ ^module[[:space:]]+\"([^\"]+)\"[[:space:]]*\{ ]]; then
      inside_module=1
      current_module="${BASH_REMATCH[1]}"
      current_values=()
      current_source_valid=0

      # Duplikatprüfung für Modulnamen
      if [[ -n "${seen_module_name[$current_module]}" ]]; then
        dup_module_name["$current_module"]+="$file"$'\n'
      else
        seen_module_name["$current_module"]="$file"
      fi

      continue
    fi

    # Source validieren
    if [[ $inside_module -eq 1 && $line =~ ^source[[:space:]]*=[[:space:]]*\".*forti_network_interfaces ]]; then
      current_source_valid=1
      continue
    fi

    # Modulende
    if [[ $inside_module -eq 1 && "$line" == *"}" ]]; then
      if [[ $current_source_valid -eq 1 ]]; then
        for key in "${keys[@]}"; do
          val="${current_values[$key]}"
          if [[ -n "$val" ]]; then
            ref="seen_${key//-/_}"
            dup="dup_${key//-/_}"
            declare -n seen_ref="$ref"
            declare -n dup_ref="$dup"

            if [[ -n "${seen_ref[$val]}" ]]; then
              dup_ref["$val"]+="$file (module: $current_module)"$'\n'
            else
              seen_ref["$val"]="$file"
            fi
          fi
        done
      fi
      inside_module=0
      continue
    fi

    # Key-Wert extrahieren (lockere Regex)
    if [[ $inside_module -eq 1 ]]; then
      for key in "${keys[@]}"; do
        if [[ $line =~ ^[[:space:]]*$key[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
          current_values[$key]="${BASH_REMATCH[1]}"
        fi
      done
    fi

  done < "$file"
done

# Ausgabe
errors=0
print_duplicates() {
  local label="$1"
  local -n map="$2"
  if (( ${#map[@]} )); then
    echo "🚨 Doppelte Werte bei '$label' gefunden:"
    for val in "${!map[@]}"; do
      echo "  ➤ \"$val\" mehrfach verwendet in:"
      echo -n "${map[$val]}"
      echo ""
    done
    ((errors++))
  fi
}

# Ausgaben:
print_duplicates "module-name" dup_module_name
print_duplicates "vlan-id" dup_vlan_id
print_duplicates "vlan-subnet" dup_vlan_subnet
print_duplicates "ip6-address" dup_ip6_address
print_duplicates "vlan-name" dup_vlan_name

if (( errors == 0 )); then
  echo "$(date +%T)✅ Keine Duplikate gefunden bei module-name, vlan-id, vlan-subnet, ip6-address oder vlan-name."
  exit 0
else
  exit 1
fi
