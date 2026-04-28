#!/bin/bash

diff -u <(jq --sort-keys . $1.map.json) <(jq --sort-keys . $2.map.json)
