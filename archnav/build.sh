#!/bin/bash
set -e

echo "Bringing down containers and volumes..."
cd ~/archnav
sudo docker-compose down -v

echo "Building apacheds..."
sudo docker build -t archnav-apacheds ./apacheds --no-cache

echo "Building fortress..."
sudo docker build -t archnav-fortress ./fortress --no-cache

echo "Building glassfish..."
sudo docker build -t archnav-glassfish ./glassfish --no-cache

echo "Starting containers..."
sudo docker-compose up
