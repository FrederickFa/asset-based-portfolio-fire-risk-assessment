
# MODIS 1km
## download datax
ODIS_C6_1_Global_24h <- readr::read_csv("https://firms.modaps.eosdis.nasa.gov/data/active_fire/modis-c6.1/csv/MODIS_C6_1_Global_24h.csv")

## define source
ODIS_C6_1_Global_24h <- ODIS_C6_1_Global_24h |>
  dplyr::mutate(source = "MODIS")

## select relevant columns
ODIS_C6_1_Global_24h <- ODIS_C6_1_Global_24h |>
  dplyr::select(
    latitude,
    longitude,
    source,
    frp
  )


# VIIRS 375m / S-NPP
## download data
SUOMI_VIIRS_C2_Global_24h <- readr::read_csv("https://firms.modaps.eosdis.nasa.gov/data/active_fire/suomi-npp-viirs-c2/csv/SUOMI_VIIRS_C2_Global_24h.csv")

## define source
SUOMI_VIIRS_C2_Global_24h <- SUOMI_VIIRS_C2_Global_24h |>
  dplyr::mutate(source = "SUOMI_VIIRS")

## select relevant columns
SUOMI_VIIRS_C2_Global_24h <- SUOMI_VIIRS_C2_Global_24h |>
  dplyr::select(
    latitude,
    longitude,
    source,
    frp
  )

# VIIRS 375m / NOAA-20
## download data
J1_VIIRS_C2_Global_24h <- readr::read_csv("https://firms.modaps.eosdis.nasa.gov/data/active_fire/noaa-20-viirs-c2/csv/J1_VIIRS_C2_Global_24h.csv")

## define source
J1_VIIRS_C2_Global_24h <- J1_VIIRS_C2_Global_24h |>
  dplyr::mutate(source = "J1_VIIRS")

## select relevant columns
J1_VIIRS_C2_Global_24h <- J1_VIIRS_C2_Global_24h |>
  dplyr::select(
    latitude,
    longitude,
    source,
    frp
  )

# bind together
all_wildfires <- rbind.data.frame(
  ODIS_C6_1_Global_24h,
  SUOMI_VIIRS_C2_Global_24h,
  J1_VIIRS_C2_Global_24h
)

# ensure distinct geo locations
all_wildfires <- all_wildfires |>
  dplyr::distinct(latitude, longitude, .keep_all = TRUE)

# assign unique ID
all_wildfires <- all_wildfires |>
  dplyr::mutate(fire_id = openssl::md5(paste0(latitude, longitude)))

# filter fires based on fire radiative power (frp)
all_wildfires <- all_wildfires |>
  dplyr::filter(frp > 50)

# save
readr::write_csv(all_wildfires, fs::path("data", "all_wildfires", ext = "csv"))


rm(all_wildfires, J1_VIIRS_C2_Global_24h, ODIS_C6_1_Global_24h, SUOMI_VIIRS_C2_Global_24h)
