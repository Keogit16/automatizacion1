#!/bin/bash

directorio=$(ls ../)
peso=$(df-h | grep root | awk '{print $4}' | sed 's/G//')

echo $directorio
echo $peso

#_______________________

if (($peso>15)); then

mkdir primer carpeta
touch primer_carpeta/primer_archivo
echo $directorio > primer_carpeta/primer_archivo
elif (($peso==11)); then
echo "Se tiene espacio pero queremos poner un elif en la condicion"

else
echo "Sin espacio suficiente"

fi

"primer_script.sh" 22L, 319B

cd ../

