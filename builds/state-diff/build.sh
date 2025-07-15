#!/bin/bash

[ ! -d "statediff-RECUP/" ] && git clone https://github.com/RECUP-DOE/statediff-RECUP.git
cd statediff-RECUP

./bootstrap.sh