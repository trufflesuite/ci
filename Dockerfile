FROM debian:latest
WORKDIR /var/workspace

# replace bourne with bash to be able to source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# update the repository sources list
# and install dependencies
RUN apt-get update \
    && apt-get install -y curl git python build-essential \
    && apt-get -y autoclean

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 6.9.1

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# fix bug with npm permissions as root (https://github.com/npm/npm/issues/13306)
RUN cd $(npm root -g)/npm && \
    npm install fs-extra && \
    sed -i -e s/graceful-fs/fs-extra/ -e s/fs.rename/fs.move/ ./lib/utils/rename.js

# use https checkout to avoid requiring deploy keys
RUN git config --global url."https://github.com/".insteadOf "git@github.com:"

# for web3's internal bignumber.js dependency
RUN git config --global url."https".insteadOf "git+https"

# confirm installation
RUN node -v
RUN npm -v

# install `tc`
RUN npm install -g "https://github.com/trufflesuite/truffle-checkout/tarball/599309a40cbd3afb8613237304f81cf7535918a9"

# grab reference checkout for faster subsequent `npm install`s
RUN tc use truffle:master

COPY bin /usr/local/bin
