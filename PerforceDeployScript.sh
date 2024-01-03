#!/bin/bash

# Create necessary directories
mkdir -p /docker/perforce-data/configs

# Creating p4d.template file
echo "#-------------------------------------------------------------------------------
# Template p4dctl configuration file for Helix Core Server
#-------------------------------------------------------------------------------

p4d %NAME%
{
    Owner    =	perforce
    Execute  =	/opt/perforce/sbin/p4d
    Umask    =	077

    # Enabled by default. 
    Enabled  =	true

    Environment
    {
        P4ROOT    =	%ROOT%
        P4SSLDIR  =	ssl
        PATH      =	/bin:/usr/bin:/usr/local/bin:/opt/perforce/bin:/opt/perforce/sbin

	# Enables nightly checkpoint routine
	# This should *not* be considered a complete backup solution
	MAINTENANCE = 	true
    }

}"> /docker/perforce-data/configs/p4d.template


# Create Dockerfile
echo "FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install -y wget gnupg
RUN wget -qO - https://package.perforce.com/perforce.pubkey | apt-key add -
RUN echo 'deb http://package.perforce.com/apt/ubuntu focal release' > /etc/apt/sources.list.d/perforce.list
RUN apt-get update
RUN apt-get install -y helix-p4d nano
RUN echo export EDITOR=nano >> ~/.bashrc
RUN mkdir /perforce

RUN echo "export EDITOR=nano" >> ~/.bashrc

CMD chown -R perforce:perforce /perforce && cd /dbs && p4dctl start master && tail -F /perforce/logs/log"> Dockerfile

# Create docker-compose.yml
echo "version: '3'
services:
   perforce:
       container_name: perforce-container
       volumes:
           - /docker/perforce-data:/perforce
           - /docker/perforce-data/configs:/etc/perforce/p4dctl.conf.d
           - /docker/perforce-data/dbs:/dbs
       build:
           context: .
           dockerfile: Dockerfile
       restart: unless-stopped
       environment:
           - P4PORT=ssl:1666
           - P4ROOT=/perforce
       ports:
           - 1667:1666
       network_mode: bridge" > docker-compose.yml


# Configure the server

docker-compose run --rm perforce /opt/perforce/sbin/configure-helix-p4d.sh


#
# Start the service
docker-compose up --build -d
# Get into the container as bash
docker exec -it perforce-container bash


