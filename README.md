# Overview

Ths project is used to perform a load test against a provided URL. The first step will be extracting all URLS the website has and then perform the load test with the URLS that were collected. The script will then output the network metric results to [NDJSON Datasets](http://ndjson.org/) within the output folder of this repository.
# Prerequisites

To operate with this repository, make sure you have the following packages installed.

- [K6](https://k6.io/docs/getting-started/installation/)
- [Python](hhttps://www.python.org/downloads/)
- [pip](https://pip.pypa.io/en/stable/installing/)

# To start a load test

```shell
./run.sh
```