#!/bin/sh

# Ziel-Datei festlegen
output_file="output.txt"

# Datei leeren oder erstellen
> "$output_file"

# CSV einlesen und verarbeiten
cat test.csv | while read line
do
    name=$(echo "$line" | cut -d ';' -f1)
    ip=$(echo "$line" | cut -d ';' -f2)

    {
        echo '  dstaddr {'
        echo '    name = "'$name'"'
        echo '    ip = "'$ip'"'
        echo '  }'
        echo ''
    } >> "$output_file"
done
