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

generate_name <- function(species, starting_text="", model, character_lookup, max_length,temperature=1){
  choose_next_char <- function(preds, character_lookup,temperature = 1){
    preds <- log(preds)/temperature
    exp_preds <- exp(preds)
    preds <- exp_preds/sum(exp(preds))
    
    next_index <- 
      rmultinom(1, 1, preds) %>% 
      as.integer() %>%
      which.max()
    character_lookup$character[next_index-1]
  }
  
  max_generated_length <- 30
  continue <- TRUE
  in_progress_name <- starting_text %>% str_split("") %>% .[[1]]
  species_data <- if(tolower(species) == "cat") 1 else 0
  

  while(continue){
    previous_letters_data <- 
      in_progress_name %>%
      list() %>%
      map(~ character_lookup$character_id[match(.x,character_lookup$character)]) %>%
      pad_sequences(maxlen = max_length) %>%
      to_categorical(num_classes = num_characters)
    next_letter_probabilities <- 
      predict(model,list(previous_letters_data,species_data))
    
    next_letter <- choose_next_char(next_letter_probabilities,character_lookup,temperature)
    
    if(next_letter == "+" || length(in_progress_name) > max_generated_length){
      continue <- FALSE
    } else {
      in_progress_name <- c(in_progress_name,next_letter)
    }
  }
  in_progress_name %>%
    paste0(collapse="")
}

