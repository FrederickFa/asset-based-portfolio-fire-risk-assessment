# =====================
# Portfolio Assessment Tool for Fires (Open-Source & Near-Real-Time)
# =====================

# Prototype by Frederick Fabian
# Please feel free to send feedback and questions to frederick.fabian@aol.com


source("global.R")

# control which data should be updated (usually only wildfires as the other data sources do not change that much)
load_processed_data_or_create_new(type = "wildfires", create_new = TRUE)

load_processed_data_or_create_new(type = "ald", create_new = FALSE)

load_processed_data_or_create_new(type = "lei", create_new = FALSE)

load_processed_data_or_create_new(type = "ald_lei_name_mapping", create_new = FALSE)

load_processed_data_or_create_new(type = "ald_lei_ownership_mapping", create_new = FALSE)


# run app
shiny::runApp()
