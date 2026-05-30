#!bin/bash

path=carpeta2
file=archivo2.log
ruta=$path/$file

if [[-f "path" ]]; then
mkdir $path
fi
if [[-f "ruta" ]]; then
touch $ruta
fi

while true; do
fecha=$(date'+%Y-%m-%d %H:%M:%S')
echo $fecha >> $ruta
sleep 5
done

