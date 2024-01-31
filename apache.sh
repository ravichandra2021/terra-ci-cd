#!/bin/bash

# install apache
apt-get update
apt-get -y install apache2

# make sure apache is started
service apache2 start 
