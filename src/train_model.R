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

# MODEL TRAINING SCRIPT -----------------
# This script is used to train the model that is used in the web service. 
# The script doesn't need to be run to use the web service, since the 
# repository already has a trained model in it. This script generates a new model and saves it
# You'll want to modify this to load your own data and train you own model


# MODEL TRAINING SETUP --------------------

# load the necessary libraries
library(dplyr)
library(readr)
library(stringr)
library(purrr)
library(tidyr)
library(keras) # use install_keras() if running for the first time. See https://keras.rstudio.com/ for details

# load all of the parameters. They are stored in a separate file so they can be used when
# running the model too
source("parameters.R")


# load the data. We don't need most of the columns in it, and we need to clean the strings.
pet_data <- 
  read_csv("seattle_pet_licenses.csv", 
           col_types = cols_only(`Animal's Name` = col_character(),
             Species = col_character(),
             `Primary Breed` = col_character(),
             `Secondary Breed` = col_character())) %>%
  rename(name = `Animal's Name`,
         species = `Species`,
         primary_breed = `Primary Breed`,
         secondary_breed = `Secondary Breed`) %>%
  mutate_all(toupper) %>%
  filter(!is.na(name),!is.na(species)) %>% # remove any missing a name or species
  filter(!str_detect(name,"[^ \\.-[a-zA-Z]]")) %>% # remove names with weird characters
  mutate_all(stringi::stri_trans_tolower) %>%
  filter(name != "") %>%
  mutate(id = row_number())


# modify the data so it's ready for a model
# first we add a character to signify the end of the name ("+")
# then we need to expand each name into subsequences (S, SP, SPO, SPOT) so we can predict each next character.
# finally we make them sequences of the same length. So they can form a matrix

# the subsequence data
subsequence_data <-
  pet_data %>%
  mutate(tokenized_name = 
           name %>%
           str_c("+") %>% # add a stop character
           str_split(""),
         accumulated_name = 
           tokenized_name %>%
           map( ~ purrr::accumulate(.x,c))) %>%
  select(species,accumulated_name) %>%
  unnest(accumulated_name)

# the species split out into a separate data set
x_species <- 
  subsequence_data %>%
  mutate(species = if_else(species=="cat",1,0)) %>%
  pull(species)

# the name data as a matrix. This will then have the last character split off to be the y data
text_matrix <-
  subsequence_data %>%
  pull(accumulated_name) %>%
  map(~ character_lookup$character_id[match(.x,character_lookup$character)]) %>%
  pad_sequences(maxlen = max_length+1) %>%
  to_categorical(num_classes = num_characters)

x_name <- text_matrix[,1:max_length,]
y_name <- text_matrix[,max_length+1,]


# CREATING THE MODEL ---------------

# this model has two inputs: the previous characters in the name and the animal species

species_input <- layer_input(shape = c(1), name = "species_input")

previous_letters_input <- 
  layer_input(shape = c(max_length,num_characters), name = "previous_letters_input") 

# the name data needs to be processed using an LSTM, Check out Deep Learning with R (Chollet & Allaire, 2018) to learn more.
previous_letters_lstm <- 
  previous_letters_input %>%
  layer_lstm(input_shape = c(max_length,num_characters), units=32, name="previous_letters_lstm")

# this combines the inputs and adds a few more layers
output <- 
  layer_concatenate(c(previous_letters_lstm, species_input)) %>%
  layer_dropout(0.2) %>%
  layer_dense(32,name="joined_dense") %>%
  layer_dropout(0.2) %>%
  layer_dense(num_characters, name="reduce_to_characters_dense") %>%
  layer_activation("softmax", "final_activation")

# the actual model
model <- keras_model(inputs = c(previous_letters_input,species_input), outputs = output)

# The optimization settings for the model
model %>% compile(
  loss = 'binary_crossentropy',
  optimizer = "adam",
  metrics = c('accuracy')
)

# RUNNING THE MODEL ----------------

# here we run the model through the data 25 times. 
# In theory the more runs the better the results, but the returns diminish
fit_results <- model %>% keras::fit(
  list(x_name,x_species), y_name,
  batch_size = 64,
  epochs = 25,
  view_metrics = FALSE
)

# SAVE THE MODEL ---------------

# save the model so that it can be used by the web service
save_model_hdf5(model,"model.h5")
