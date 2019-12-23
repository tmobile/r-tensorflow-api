# r-tensorflow-api <img src="misc/logo.png" align="right" height="40px" />

[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](LICENSE)

_(version 1.1.0)_

This repository creates a production-ready docker image that uses R and the [keras](https://keras.rstudio.com/) and [plumber](https://github.com/trestletech/plumber) R packages to create a neural network powered REST API. The package keras provides the ability to create neural networks, while plumber allows it to run R as a web service. The docker container is designed to be:

* __R first__ - designed so that R users can comfortably create their own neural network powered services without having to learn other languages.
* __Production ready__ - as small of an image size as possible while still being maintainable and understandable. At our last measure, it was 1.86gb, with around 800mb from Python and the keras backend and 900mb from R and R libraries.
* __TensorFlow compatible__ - the container works with models created using the R keras package without any additional Python configuration. Note: this uses the _cpu_ version of Tensorflow since it is designed for running models (not training them).
* __HTTPS enabled__ - unfortunately, the R plumber library does not support SSL encrypted traffic. Since encryption is likely required for enterprise use, we have an optional dockerfile which uses an Apache 2 server. The server redirects HTTPS traffic as HTTP to plumber, and then take the plumber response and re-encrypts it back to HTTPS.

Check out our blog post on the [T-Mobile open source website](https://opensource.t-mobile.com/blog/posts/r-tensorflow-api/).

## How to use this repository

To use this repository, first download and install [docker](https://www.docker.com/get-started). Once docker is installed and the repository is downloaded, go to the repository folder and open a terminal, then run the following commands:

```
docker build -t r-tensorflow-api .
docker run --rm -it -p 80:80 r-tensorflow-api
```

The first command builds the docker image (which may take up to 30 minutes to compile the R libraries), and the second runs the container.

If the image successfully built, you should be able to go to [http://127.0.0.1/names](http://127.0.0.1/names) in your browser and see a random 20 pet names generated from a neural network. The names are based on [pet licenses from the City of Seattle](https://data.seattle.gov/Community/Seattle-Pet-Licenses/jguv-t9rb).

## Creating your own API

To make your own API, you only need to modify the R code in the `src` folder. The code in there is split into several files:

  1. `main.R` _[required]_ - this is what gets run by the API, and only contains code to start plumber. You should not need to modify this.
  2. `rest_controller.R` _[required]_ - this file specifies the endpoints for your web service. You should modify this heavily as you create your own endpoints.
  3. `setup.R` _[required]_ - this script is run when building the image to install the R libraries. If any libraries fail to install, the build aborts. You should modify this to include the libraries you need. If you want to install packages from GitHub, you can install devtools and then call it from within this script. _Plumber and keras are installed within the Dockerfile before this script runs so that you don't need to reinstall them each time you edit this file._
  4. `runtime_functions.R` - this file contains any additional functions that are needed when you run the service. It's a good place to store functions to keep the `rest_controller.R` file clean.
  5. `parameters.R` - this file contains parameters needed for the model. It's a good place to put values that are need for both building the model and during runtime.
  6. `train_model.R` - this script trains the model and saves it. _It is not run as part of the container, it's only here as a reference._ The repository already includes the output of the script (the model as an hdf5 object), but if you wanted to rebuild them you only need to run this file.

## dockerfile details

The dockerfile does the following steps:

  1. Load from the [`rocker/r-ver`](https://hub.docker.com/r/rocker/r-ver/) docker image - This image was chosen as a balance of ease of maintenance (compared to a pure debian or alpine base) and size of the image (compared to [`rocker/tidyverse`](https://hub.docker.com/r/rocker/tidyverse/) which also includes RStudio). Unfortunately this means many R packages have to be manually installed. If you are finding the images builds too slowly for your tastes, switch to using [`rocker/tidyverse`](https://hub.docker.com/r/rocker/tidyverse/) as the base image.
  2. Install the necessary linux libraries. These libraries should be sufficient for most tidyverse libraries, however if you need more check out the libraries loaded by the [`rocker/tidyverse`](https://hub.docker.com/r/rocker/tidyverse/) image.
  3. Install miniconda and the appropriate Python libraries for keras. This image uses a Miniconda version based on Python 3.6. Miniconda Python was chosen instead of Anaconda Python to decrease the size of the image by 3gb. An environmental variable is also set so R knows to use the correct Python version.
  4. Install the necessary R packages. Any package that you would want to install to run your service (that you'd normally use `install.packages()` for) you need to list in the `setup.R` file. Instead of using an R script to install the libraries, you could do it directly from within the dockerfile using `install2.r`. We chose to split this out so that data scientists have fewer reasons to touch the dockerfile.
  5. Copy the R code over.
  6. At runtime, use Rscript to start the `main.R` script, which has the plumber web server code.

## HTTPS details

To run the _HTTPS_ version, use these commands:

```
docker build -f Dockerfile.https -t r-tensorflow-api-https .
docker run --rm -it -p 443:443 r-tensorflow-api-https
```

If you try to test it by going to [https://127.0.0.1/names](https://127.0.0.1/names) you'll get a warning that the certificates are invalid. You'll want to replace the https/server.cert and https/server.key file with your valid certificates before deploying.

The dockerfile has several differences from the HTTP one:

  1. It sets up an Apache 2 server to reroute HTTPS traffic (port 443) to HTTP traffic (port 80) which gets received by plumber. This includes transferring a config file (`000-default.conf`) and setting Apache 2 to only listen to port 443 and not port 80.
  2. It transfers the certificate and key file to use for the HTTPS encryption.
  3. It has a `run-r-and-redirect.sh` script which is executed when the image is run. This script first starts the apache2 server then runs the `main.R` R script. Thus, the docker container has two programs running simultaneously: R and Apache 2.

## Thanks to

  * The [Rocker project](https://www.rocker-project.org/) for maintaining the R docker images these build from.
  * The [plumber](https://github.com/trestletech/plumber) maintainers for creating a way to use R as a web service.
  * The [RStudio](https://www.rstudio.com/) developers for creating the keras interface to python keras.
  * Rbloggers author gluc, for writing the [blog post](https://www.r-bloggers.com/shiny-https-securing-shiny-open-source-with-ssl/) that informed our solution for https redirecting.
  * The City of Seattle for making the pet license data available for public use.

## Terms and conditions

From the City of Seattle on the pet license data:

> The data made available here has been modified for use from its original source, which is the City of Seattle. Neither the City of Seattle nor the Office of the Chief Technology Officer (OCTO) makes any claims as to the completeness, timeliness, accuracy or content of any data contained in this application; makes any representation of any kind, including, but not limited to, warranty of the accuracy or fitness for a particular use; nor are any such warranties to be implied or inferred with respect to the information or data furnished herein. The data is subject to change as modifications and updates are complete. It is understood that the information contained in the web feed is being used at one's own risk.

From RStudio for using some of the R Keras example code as a framework for our model:

> the keras library is copyright 2017: RStudio, Inc; Google, Inc; François Chollet; Yuan Tang
