#!/bin/bash
set -o pipefail

cyan=$(tput setaf 6)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
warn=$(tput setaf 3)
bold=$(tput bold)
normal=$(tput sgr0)

pip=$(python3 -m pip --version)
linkchecker=$(pip list | grep -w LinkChecker)

if [[ $linkchecker ]]; then
  echo "${bold}pip installed...${normal}"
else
  echo "${bold}installing pip...${normal}"
  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  python3 get-pip.py
  rm -rf get-pip.py
fi

if [[ $linkchecker ]]; then
  echo "${bold}python dependancies installed...${normal}"
else
  echo "${bold}installing python dependancies...${normal}"
  pip install linkchecker
fi

read -p "Enter a website URL: (default: https://www.<DOMAIN>.com/): " WEBSITE
[ -n "${WEBSITE}" ] || WEBSITE='https://example.com'

read -p "Enter a recursive setting for how many urls should be collected (default: 2): " RECURSIVENESS
[ -n "${RECURSIVENESS}" ] || RECURSIVENESS='2'

read -p "Enter the duration in (m/s) (default: 60s): " DURATION
[ -n "${DURATION}" ] || DURATION='60s'

read -p "Enter the amount of virtual users (default: 2): " VUS
[ -n "${VUS}" ] || VUS='2'

if [[ "$WEBSITE" == *"www"* ]]; then
  export NAME=$(echo $WEBSITE | cut -d"." -f2 | cut -d"." -f3)
else
  export NAME=$(echo $WEBSITE | cut -d"." -f1 | cut -d"/" -f3-)
fi

run(){
mkdir -p output
export urls=($(linkchecker ${WEBSITE} -r ${RECURSIVENESS} -v | sed '/Real/!d; s/Real URL//; '/https/\!d'; s/ //g'))

printf "%s\n" "${urls[@]}" > output/crawl-${NAME}-`date +"%m-%d-%Y-%H%M%S"`
echo "${bold}k6 template file stored in the output folder...${normal}"

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
rm -rf ./output/k6-template-${NAME}.js-e output/settings output/urls output/crawl-*

k6 run --insecure-skip-tls-verify --summary-time-unit=ms --out json=output/metrics-${NAME}-`date +"%m-%d-%Y-%H%M%S"`.json ./recipe-${NAME}.js
rm -rf recipe-*
echo "${bold}${green}http metrics are in the output folder${normal}"
}

template(){
mkdir -p output
export urls=($(linkchecker ${WEBSITE} -r ${RECURSIVENESS} -v | sed '/Real/!d; s/Real URL//; '/https/\!d'; s/ //g'))

printf "%s\n" "${urls[@]}" > output/crawl-${NAME}-`date +"%m-%d-%Y-%H%M%S"`

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

cp ./recipe_template.js ./output/k6-template-${NAME}.js
sed -i -e "/let res;/r output/urls" ./output/k6-template-${NAME}.js
sed -i -e "/options/r output/settings" ./output/k6-template-${NAME}.js
rm -rf ./output/k6-template-${NAME}.js-e output/settings output/urls output/crawl-*
echo "${bold}${green}k6 template file stored in the output folder...${normal}"
}

menu(){    

logo="$(wget -q -O /tmp/logo artii.herokuapp.com/make?text=K6X&font=small)"
logo="$(cat /tmp/logo)"

rm -rf /tmp/logo
numchoice=1
while [[ $numchoice != 0 ]]; do
    echo "${cyan}${logo}${normal}"
    echo "${cyan}Version: 0.001${normal}"
    echo -n "
    1. Run a load test for website
    2. Make a k6 load testing template
    0. Exit
    enter choice [ 1 | 2 | 3 | 0 ]: "
    read numchoice
    case $numchoice in
        "1" ) run ;;
        "2" ) template ;;
        "0" ) break ;;
        * ) echo -n "You entered an incorrect option. Please try again." ;;
    esac
done
}

menu
