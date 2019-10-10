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
library(keras)

# load the parameters
source("parameters.R")

# load the neural network model
model <- load_model_hdf5("model.h5")


# a function that generates a single pet name from a model
generate_name <- function(model, character_lookup, max_length, temperature=1){
  # model - the trained neural network
  # character_lookup - the table for how characters convert to numbers
  # max_length - the expected length of the training data in characters
  # temperature - how weird to make the names, higher is weirder
  
  # given the probabilities returned from the model, this code
  choose_next_char <- function(preds, character_lookup,temperature = 1){
    preds <- log(preds)/temperature
    exp_preds <- exp(preds)
    preds <- exp_preds/sum(exp(preds))
    
    next_index <- which.max(as.integer(rmultinom(1, 1, preds)))
    character_lookup$character[next_index-1]
  }
  
  in_progress_name <- character(0)
  next_letter <- ""
  
  # while we haven't hit a stop character and the name isn't too long
  while(next_letter != "+" && length(in_progress_name) < 30){
    # prep the data to run in the model again
    previous_letters_data <- 
      lapply(list(in_progress_name), function(.x){
        character_lookup$character_id[match(.x,character_lookup$character)]
      })
    previous_letters_data <- pad_sequences(previous_letters_data, maxlen = max_length)
    previous_letters_data <- to_categorical(previous_letters_data, num_classes = num_characters)
    
    # get the probabilities of each possible next character by running the model
    next_letter_probabilities <- 
      predict(model,previous_letters_data)
    
    # determine what the actual letter is
    next_letter <- choose_next_char(next_letter_probabilities,character_lookup,temperature)
    
    if(next_letter != "+")
      # if the next character isn't stop add the latest generated character to the name and continue
      in_progress_name <- c(in_progress_name,next_letter)
  }
  
  # turn the list of characters into a single string
  raw_name <- paste0(in_progress_name, collapse="")
  
  # capitalize the first letter of each word
  capitalized_name <-gsub("\\b(\\w)","\\U\\1",raw_name,perl=TRUE)
  
  capitalized_name
}

# a function to generate many names
generate_many_names <- function(n=10, model, character_lookup, max_length, temperature=1){
  # n - the number of names to generate
  # (then everything else you'd pass to generate_name)
  unlist(lapply(1:n,function(x) generate_name(model, character_lookup, max_length, temperature)))
}
