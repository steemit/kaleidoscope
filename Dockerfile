######################################################################################
##  Build JS Client App
######################################################################################
FROM node:9-alpine as build-js
WORKDIR /app

# install build dependencies
RUN apk add --no-cache \
    bash \
    git \
    make

# install application dependencies
COPY client/package.json client/yarn.lock ./
RUN JOBS=max yarn install --non-interactive --frozen-lockfile

# copy in application source
COPY client/ .


# run tests and compile sources
RUN CI=true yarn test && yarn build

WORKDIR /app
# prune modules
RUN yarn install --non-interactive --frozen-lockfile --production

# save git short id
WORKDIR /tmp
COPY .git /tmp/
RUN git rev-parse --short HEAD > /app/gitversion.txt

######################################################################################
##  Build Python Serverside App
######################################################################################
FROM phusion/baseimage:0.10.0 as build-python

RUN \
    apt-get update && \
    apt-get install -y \
        build-essential \
        libssl-dev \
        make \
        python3 \
        python3-dev \
        python3-pip

RUN \
    pip3 install --upgrade pip setuptools pipenv

######################################################################################
##  Build Final Runtime Container
######################################################################################
FROM phusion/baseimage:0.10.0
WORKDIR /app
COPY --from=js-build /app/build /app/webroot/
COPY --from=js-build /app/gitversion.txt /app/

#####################################################################################
##  Default Container Environment
######################################################################################
ENV PORT 80
