# library(scales)
# library(viridis)
# library(shiny)
# library(leaflet)
# library(htmltools)
# library(dplyr)
# library(leaflet.esri)
# library(leaflet.extras2)
# library(tidyverse)
# library(sf)
# library(leafgl)
# library(DT)
# library(ggplot2)


load_processed_data_or_create_new <- function(type, create_new = FALSE) {


  if(type == "wildfires") {

    if(create_new == FALSE) all_wildfires <- readr::read_csv(fs::path("data", "all_wildfires", ext = "csv"))
    if(create_new == TRUE) source(fs::path("scripts", "prep_NASA_wildfire_data", ext = "R"))
  }

  if(type == "ald") {

    if(create_new == FALSE) all_wildfires <- readr::read_csv(fs::path("data", "ald_mapped", ext = "csv"))
    if(create_new == TRUE) source(fs::path("scripts", "prep_ald", ext = "R"))
  }

  if(type == "portfolios") {

    if(create_new == FALSE) all_wildfires <- readr::read_csv(fs::path("data", "portfolios", ext = "csv"))
    if(create_new == TRUE) source(fs::path("scripts", "prep_portfolio_data", ext = "R"))
  }

  if(type == "lei") {

    if(create_new == TRUE) source(fs::path("scripts", "prep_LEI_data", ext = "R"))
  }

  if(type == "ald_lei_name_mapping") {

    if(create_new == TRUE) source(fs::path("scripts", "mapping_ald_lei_companies", ext = "R"))
  }

  if(type == "ald_lei_ownership_mapping") {

    if(create_new == TRUE) source(fs::path("scripts", "mapping_ownership_tree", ext = "R"))
  }
}

#read portfolios
portfolios <- readr::read_csv(fs::path("data", "portfolios", ext = "csv"))


# prep wildfire data
all_wildfires <- readr::read_csv(fs::path("data", "all_wildfires", ext = "csv"))

all_wildfires <- all_wildfires |>
  dplyr::mutate(long = longitude, lat = latitude) |>
  sf::st_as_sf(coords = c("longitude","latitude"))

sf::st_crs(all_wildfires) <- 4326

all_wildfires <- sf::st_join(all_wildfires, spData::world |> dplyr::select(geom, name_long), join = sf::st_within)


# prep ald
ald <- readr::read_csv(fs::path("data", "ald_mapped", ext = "csv"))

ald <- ald |>
  dplyr::mutate(
    capacity_unit = dplyr::case_when(
      sector == "Cement" ~ "Mio t.",
      sector == "Steel" ~ "Mio t.",
      sector == "Power" ~ "MW"
    )
  )


ald <- ald |>
  dplyr::mutate(
    lei_info = dplyr::case_when(
      !is.na(parent_lei) ~ "LEI of parent in raw data",
      is.na(parent_lei) & !is.na(lei) ~ "LEI of parent via name matching",
      is.na(final_lei) ~ "LEI not available"
    )
  )

ald <- ald |>
  sf::st_as_sf(coords = c("longitude","latitude"))

sf::st_crs(ald) <- 4326

ald <- sf::st_join(ald, all_wildfires, join = sf::st_nearest_feature)

fire <- ald |>
  sf::st_drop_geometry() |>
  dplyr::select(fire_id) |>
  dplyr::left_join(all_wildfires, by = "fire_id") |>
  sf::st_as_sf()

sf::st_crs(fire) <- 4326

ald$dist <- sf::st_distance(ald, fire, by_element=T)

# prep wild fires
all_wildfires <- sf::st_join(all_wildfires, ald |> dplyr::select(geometry, uid), join = sf::st_nearest_feature)

fire_2 <- all_wildfires |>
  sf::st_drop_geometry() |>
  dplyr::select(uid) |>
  dplyr::left_join(ald |> dplyr::distinct(uid, .keep_all = T), by = "uid") |>
  sf::st_as_sf()

sf::st_crs(fire_2) <- 4326

all_wildfires$dist <- sf::st_distance(all_wildfires, fire_2, by_element=T)

# define distance categories
ald$distlevel <- cut(
  ald$dist,
  c(0,1000,5000,10000,20000, 50000, 100000, 100000000000000000), include.lowest = T,
  labels = c('0-1 km', '1-5 km', '5-10 km', '10-20 km', '20-50 km', '50-100 km', 'More than 100km')
)

# creating color palette
number_colors <- 12
viridis_colors <- viridis::viridis(number_colors, option = "B")

palette <- leaflet::colorFactor(palette = c(viridis_colors[1:7]), ald$distlevel, reverse = T)

rm(number_colors, viridis_colors, fire_2, fire)

