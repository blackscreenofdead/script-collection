#!/bin/bash
echo "$(date +%T) Prüfe auf Duplikate..."
files=("$@")

# Felder, die geprüft werden
keys=("name" "subnet")

# Speicher für Duplikate
declare -A seen_module
declare -A seen_name
declare -A seen_subnet

declare -A dup_module
declare -A dup_name
declare -A dup_subnet

for file in "${files[@]}"; do
  inside_module=0
  current_module=""
  current_source_valid=0
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
        for key in "${keys[@]}"; do
          val="${current_values[$key]}"
          if [[ -n "$val" ]]; then
            ref="seen_${key}"
            dup="dup_${key}"
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

    # Key-Werte extrahieren (lockere Regex)
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

print_duplicates "module-name" dup_module
print_duplicates "name" dup_name
print_duplicates "subnet" dup_subnet

if (( errors == 0 )); then
  echo "$(date +%T)✅ Keine Duplikate gefunden bei module-name, name oder subnet."
  exit 0
else
  exit 1
fi
