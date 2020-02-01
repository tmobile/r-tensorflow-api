# r-tensorflow-api v1.1.1 - 2019-12-23

- Split package installation into two separate steps. Now installs plumber and keras in the Dockerfile and other packages in `setup.R`
- Updated to R version 3.6.1
- Upgraded miniconda to 4.7.12.1

# r-tensorflow-api v1.1.0 - 2019-10-10

- Updated to R version 3.6.0
- Updated packages to come from MRAN on 2019-07-05
- Added a --no-cache-dir to the pip install to make it save space
- Removed python keras library since that's rolled into tensorflow 2.0
- Added version numbers to the python packages so the container still works if future versions of the packages change
- Switched the example api to be more compact and concisely written
- Updated the documentation to have better options for the docker container run
- Added a news file (you're reading it!)
- Added a .dockerignore file

# r-tensorflow-api v1.0.0 - 2018-10-08