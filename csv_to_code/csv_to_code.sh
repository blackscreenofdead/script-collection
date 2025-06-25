#!/bin/sh

output_file="output.txt"

> "$output_file"

cat test.csv | while read line
do
    name=$(echo "$line" | cut -d ';' -f1)
    ip=$(echo "$line" | cut -d ';' -f2)

    {
        echo '  module "'$name'" {'
        echo '    source    = "git::https://gitlab.XXXX.com/terradorm/module.example.git?ref=1.0.0"'
        echo '    name      = "'$name'"'
        echo '    subnet    = "'$ip'"'
        echo '    vdomparam = "vdom01"'
        echo '  }'
        echo ''
    } >> "$output_file"
done
