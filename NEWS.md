# r-tensorflow-api v1.1.2 - 2021-09-16
- Updated to R version 4.1.0
- Upgraded to Python 3.9 and TensorFlow 2.6.0
- Switched Python packages back to pip to get more recent versions unavailable on conda
- removed the apache2 dependency from the HTTP version

# r-tensorflow-api v1.1.1 - 2020-05-31

- Updated to R version 3.6.3
- Fixed an issue with Miniconda failing to download
- Python packages now use conda instead of pip to install
- Removed unnecessary EXPOSE commands

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