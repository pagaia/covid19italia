#!/bin/bash

set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/rawdata
mkdir -p "$folder"/processing

URL="https://www.epicentro.iss.it/coronavirus/open-data/covid_19-iss.xlsx"

# leggi la risposta HTTP del sito
code=$(curl --cipher 'DEFAULT:!DH' -s -L -o /dev/null -w "%{http_code}" ''"$URL"'')

# se il sito è raggiungibile scarica i dati
if [ $code -eq 200 ]; then

  curl -kL --cipher 'DEFAULT:!DH' "https://www.epicentro.iss.it/coronavirus/open-data/covid_19-iss.xlsx" >"$folder"/rawdata/covid_19-iss.xlsx

  rm "$folder"/rawdata/*.csv

  # leggi lista dei fogli, rimuovendo Contenuto e foglio che contiene spazio nel nome
  in2csv -n "$folder"/rawdata/covid_19-iss.xlsx | grep -vP "( |Contenuto)" >"$folder"/rawdata/listafogli

  # crea un CSV per ogni foglio
  while read p; do
    in2csv -I --sheet "$p" "$folder"/rawdata/covid_19-iss.xlsx >"$folder"/rawdata/"$p".csv
  done <"$folder"/rawdata/listafogli

  # se la cartella processing è vuota copia i CSV da rawdata a processing
  if [ -z "$(ls -A "$folder"/processing)" ]; then
    cp "$folder"/rawdata/*.csv "$folder"/processing
  else
    # aggiungi nuovi dati ai fogli archiviati
    while read p; do
      mlr --csv cat then uniq -a "$folder"/processing/"$p".csv "$folder"/rawdata/"$p".csv >"$folder"/processing/tmp.csv
      mv "$folder"/processing/tmp.csv "$folder"/processing/"$p".csv
    done <"$folder"/rawdata/listafogli
  fi
fi
