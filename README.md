# Overview

Ths project is used to perform a load test against a provided URL. The first step will be extracting all URLS the website has and then perform the load test with the URLS that were collected. The script will then output the generated network metrics to a [NDJSON dataset](http://ndjson.org/). The tool uses [K6](https://k6.io/) to extract performance metrics.

# Prerequisites

To operate with this repository, ensure the following packages installed.

- [k6](https://k6.io/docs/getting-started/installation/)
- [python 3.X](https://www.python.org/downloads/)

# To start a load test

```shell
./run.sh
```
