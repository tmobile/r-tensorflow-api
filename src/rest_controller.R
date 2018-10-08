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


library(dplyr)
library(purrr)
library(tidyr)
library(keras)
library(jsonlite)
library(stringr)

source("parameters.R")
source("runtime_functions.R")

model <- load_model_hdf5("model.h5")

# Set an endpoint to return a pet name
#* @get /name
get_name <- function(species="",start=""){
  species <- tolower(species)
  if(species == ""){
    species <- sample(c("cat","dog"),1)
  }
  
  start <- 
    start %>%
    stringi::stri_trans_tolower() %>%
    str_remove_all("[^ \\.-[a-zA-Z]]+")
  
  generate_name(species, start, model, character_lookup,max_length)
}
