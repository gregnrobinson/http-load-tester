#!/bin/bash
set -o pipefail

cyan=$(tput setaf 6)
yellow=$(tput setaf 3)
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

read -p "Enter a website URL: (default: https://www.<DOMAIN>.com/): " WEBSITE
[ -z "${WEBSITE}" ] && WEBSITE='https://example.com'

read -p "Enter a recursive setting for how many urls should be collected (default: 2): " RECURSIVENESS
[ -z "${RECURSIVENESS}" ] && RECURSIVENESS='2'

read -p "Enter the duration in (m/s) (default: 60s): " DURATION
[ -z "${DURATION}" ] && DURATION='60s'

read -p "Enter the amount of virtual users (default: 2): " VUS
[ -z "${VUS}" ] && VUS='2'

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

logo="$(wget -q -O /tmp/logo artii.herokuapp.com/make?text=K69&font=small)"
logo="$(cat /tmp/logo)"

rm -rf /tmp/logo
numchoice=1
while [[ $numchoice != 0 ]]; do
    echo "${cyan}${logo}${normal}"
    echo "${cyan}Version: 0.001${normal}"
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
