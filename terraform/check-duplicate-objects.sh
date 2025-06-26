#!/bin/bash
echo "$(date +%T) Prüfe auf Duplikate..."
files=("$@")

# Felder
declare -A seen_module
declare -A seen_name
declare -A seen_subnet
declare -A seen_fqdn

declare -A dup_module
declare -A dup_name
declare -A dup_subnet
declare -A dup_fqdn

for file in "${files[@]}"; do
  inside_module=0
  current_module=""
  current_source_valid=0
  current_type=""
  declare -A current_values

  while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    # Zeile säubern
    line="$(echo "$raw_line" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue

    # Modulstart erkennen
    if [[ $line =~ ^module[[:space:]]+\"([^\"]+)\"[[:space:]]*\{ ]]; then
      inside_module=1
      current_module="${BASH_REMATCH[1]}"
      current_values=()
      current_source_valid=0
      current_type=""

      if [[ -n "${seen_module[$current_module]}" ]]; then
        dup_module["$current_module"]+="$file"$'\n'
      else
        seen_module["$current_module"]="$file"
      fi

      continue
    fi

    # Source prüfen
    if [[ $inside_module -eq 1 && $line =~ ^source[[:space:]]*=[[:space:]]*\".*forti_firewall_object ]]; then
      current_source_valid=1
      continue
    fi

    # Modulende
    if [[ $inside_module -eq 1 && "$line" == *"}" ]]; then
      if [[ $current_source_valid -eq 1 ]]; then
        name="${current_values[name]}"
        type="${current_type}"
        subnet="${current_values[subnet]}"
        fqdn="${current_values[fqdn]}"

        # Name immer prüfen
        if [[ -n "$name" ]]; then
          if [[ -n "${seen_name[$name]}" ]]; then
            dup_name["$name"]+="$file (module: $current_module)"$'\n'
          else
            seen_name["$name"]="$file"
          fi
        fi

        # Typ abhängig prüfen
        if [[ "$type" == "fqdn" ]]; then
          if [[ -n "$fqdn" ]]; then
            if [[ -n "${seen_fqdn[$fqdn]}" ]]; then
              dup_fqdn["$fqdn"]+="$file (module: $current_module)"$'\n'
            else
              seen_fqdn["$fqdn"]="$file"
            fi
          fi
        else
          if [[ -n "$subnet" ]]; then
            if [[ -n "${seen_subnet[$subnet]}" ]]; then
              dup_subnet["$subnet"]+="$file (module: $current_module)"$'\n'
            else
              seen_subnet["$subnet"]="$file"
            fi
          fi
        fi
      fi
      inside_module=0
      continue
    fi

    # Key-Werte extrahieren (lockere Regex)
    if [[ $inside_module -eq 1 ]]; then
      for key in "name" "subnet" "fqdn" "type"; do
        if [[ $line =~ ^[[:space:]]*$key[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
          current_values[$key]="${BASH_REMATCH[1]}"
          # Für type separat merken
          [[ "$key" == "type" ]] && current_type="${BASH_REMATCH[1]}"
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

print_duplicates "module-name" dup_module
print_duplicates "name" dup_name
print_duplicates "subnet" dup_subnet
print_duplicates "fqdn" dup_fqdn

if (( errors == 0 )); then
  echo "$(date +%T)✅ Keine Duplikate gefunden bei module-name, name, subnet oder fqdn."
  exit 0
else
  exit 1
fi
