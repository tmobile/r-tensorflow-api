# =========================================================================
# Copyright © 2018 T-Mobile USA, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =========================================================================

FROM rocker/r-ver:3.5.0

# update some packages, including sodium and apache2, then clean
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    file \
    libcurl4-openssl-dev \
    libedit2 \
    libssl-dev \
    lsb-release \
    psmisc \
    procps \
    wget \
    libxml2-dev \
    libpq-dev \
    libssh2-1-dev \
    ca-certificates \
    libglib2.0-0 \
	libxext6 \
	libsm6  \
	libxrender1 \
	bzip2 \
	libsodium-dev \
    apache2 \
    zlib1g-dev \
    && wget -O libssl1.0.0.deb http://ftp.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u8_amd64.deb \
    && dpkg -i libssl1.0.0.deb \
    && rm libssl1.0.0.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ 

# install miniconda, and set the appropriate path variables.
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc
ENV PATH /opt/conda/bin:$PATH

# install keras, tensorflow, and h5py using the pip that links to miniconda (the default pip is for python 2.7)
RUN /opt/conda/bin/pip install keras tensorflow h5py

# let R know the right version of python to use
ENV RETICULATE_PYTHON /opt/conda/bin/python

# copy the setup script, run it, then delete it
COPY src/setup.R /
RUN Rscript setup.R && rm setup.R

# copy all the other R files.
COPY src /src

# Set up the apache2 server by adding modules and setting the ports to only 443 (not 80)
RUN sh -c '/bin/echo -e "ssl proxy proxy_ajp proxy_http rewrite deflate headers proxy_balancer proxy_connect proxy_html\n" | a2enmod' && \
    rm /etc/apache2/ports.conf && \
    echo "Listen 443" > /etc/apache2/ports.conf

# add the files needed for https
COPY https/server.cert /etc/ssl/certs/server.cert
COPY https/server.key  /etc/ssl/private/server.key
COPY https/000-default.conf /etc/apache2/sites-enabled
COPY https/run-r-and-redirect.sh /usr/bin/run-r-and-redirect.sh

# fixes an issue where the run script has windows line endings if running from windows
RUN sed -i 's/\r//g' /usr/bin/run-r-and-redirect.sh

EXPOSE 443

ENTRYPOINT ["/usr/bin/run-r-and-redirect.sh"]