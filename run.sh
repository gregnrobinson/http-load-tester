#!/bin/bash
set -o pipefail

logo=$(tput setaf 6)
warn=$(tput setaf 3)
bold=$(tput bold)
normal=$(tput sgr0)

linkchecker=$(pip list | grep -w LinkChecker)

if [[ $linkchecker ]]; then
    echo "${bold}python dependancies already installed...${normal}"
else
    echo "${bold}instaling python dependancies...${normal}"
    pip install linkchecker
fi

run(){
mkdir -p output

printf "Enter a website with https://: eg. (https://www.<DOMAIN>.com/): "
read -r WEBSITE

printf "Enter a recursive setting for how many urls should be collected: "
read -r RECURSIVENESS

printf "Enter the duration in (m/s): eg. 60s: "
read -r DURATION

printf "Enter the amount of virtual users: eg. 2: "
read -r VUS

if [[ "$WEBSITE" == *"www"* ]]; then
  export NAME=$(echo $WEBSITE | cut -d"." -f2 | cut -d"." -f3)
else
  export NAME=$(echo $WEBSITE | cut -d"." -f1 | cut -d"/" -f3-)
fi

export urls=($(linkchecker ${WEBSITE} -r ${RECURSIVENESS} -v | sed '/Real/!d; s/Real URL//; '/https/\!d'; s/ //g'))

printf "%s\n" "${urls[@]}" > output/crawl-${NAME}-`date +"%m-%d-%Y-%H%M%S"`
echo "${bold}Output file is in the .helper folder${normal}"

for i in ${urls[@]}; do
cat >> output/urls <<HERE
  res = http.get("${i}");
  trackDataMetricsPerURL(res);
HERE
done

cat > output/settings <<HERE
  duration: '${DURATION}',
  vus: ${VUS},
HERE

cp ./recipe_template.js ./recipe-${NAME}.js
sed -i -e "/let res;/r output/urls" ./recipe-${NAME}.js
sed -i -e "/options/r output/settings" ./recipe-${NAME}.js
rm -rf ./recipe-${NAME}.js-e output/settings output/urls

k6 run --insecure-skip-tls-verify --summary-time-unit=ms --out json=output/metrics-${NAME}-`date +"%m-%d-%Y-%H%M%S"`.json ./recipe-${NAME}.js
}

menu(){    

LOGO="$(wget -q -O /tmp/logo artii.herokuapp.com/make?text=Load+Tester&font=small)"
LOGO="$(cat /tmp/logo)"
rm -rf /tmp/logo
numchoice=1
while [[ $numchoice != 0 ]]; do
    echo "${logo}${LOGO}${normal}"
    echo "${logo}Version: 0.001${normal}"
    echo -n "
    1. Run a load test for website
    0. Exit
    enter choice [ 1 | 2 | 3 | 0 ]: "
    read numchoice
    case $numchoice in
        "1" ) run ;;
        "0" ) break ;;
        * ) echo -n "You entered an incorrect option. Please try again." ;;
    esac
done
}

menu
