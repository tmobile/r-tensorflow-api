# =========================================================================
# Copyright © 2019 T-Mobile USA, Inc.
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
library(keras) # use install_keras() if running for the first time locally. See https://keras.rstudio.com/ for details

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
  mutate(accumulated_name =
           name %>%
           str_c("+") %>% # add a stop character
           str_split("") %>% # split into characters
           map( ~ purrr::accumulate(.x,c)) # make into cumulative sequences
         ) %>%
  select(accumulated_name) %>% # get only the column with the names
  unnest(accumulated_name) %>% # break the cumulations into individual rows
  arrange(runif(n())) %>% # shuffle for good measure
  pull(accumulated_name) # change to a list

# the name data as a matrix. This will then have the last character split off to be the y data
# this is nowhere near the fastest code that does what we need to, but it's easy to read so who cares?
text_matrix <-
  subsequence_data %>%
  map(~ character_lookup$character_id[match(.x,character_lookup$character)]) %>% # change characters into the right numbers
  pad_sequences(maxlen = max_length+1) %>% # add padding so all of the sequences have the same length
  to_categorical(num_classes = num_characters) # 1-hot encode them (so like make 2 into [0,1,0,...,0])

x_name <- text_matrix[,1:max_length,] # make the X data of the letters before
y_name <- text_matrix[,max_length+1,] # make the Y data of the next letter


# CREATING THE MODEL ---------------

# the input to the network
input <- layer_input(shape = c(max_length,num_characters)) 

# the name data needs to be processed using an LSTM, 
# Check out Deep Learning with R (Chollet & Allaire, 2018) to learn more.
# if we were using words instead of characters, or we had 10x the datapoints,
# we'd want to use more lstm layers instead of just two
output <- 
  input %>%
  layer_lstm(units = 32, return_sequences = TRUE) %>%
  layer_lstm(units = 32, return_sequences = FALSE) %>%
  layer_dropout(rate = 0.2) %>%
  layer_dense(num_characters) %>%
  layer_activation("softmax")

# the actual model, compiled
model <- keras_model(inputs = input, outputs = output) %>% 
  compile(
    loss = 'binary_crossentropy',
    optimizer = "adam"
  )


# RUNNING THE MODEL ----------------

# here we run the model through the data 25 times. 
# In theory the more runs the better the results, but the returns diminish
fit_results <- model %>% keras::fit(
  x_name, 
  y_name,
  batch_size = 64,
  epochs = 25
)

# SAVE THE MODEL ---------------

# save the model so that it can be used in the future
save_model_hdf5(model,"model.h5")
