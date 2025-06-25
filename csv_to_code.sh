#!/bin/sh

cat name.csv | while read line
do
        name=$(echo $line | cut -d ';' -f1)


echo '  dstaddr {'
echo '    name = "'$name'"'
echo '  }'
echo ''
done
