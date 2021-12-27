# cement
cement_ald <- openxlsx::read.xlsx("https://spatialfinanceinitiative.com/wp-content/uploads/2021/07/SFI-Global-Cement-Database-July-2021.xlsx", sheet = 2)

cement_ald <- cement_ald |>
  dplyr::filter(status == "Operating")

cement_ald <- cement_ald |>
  dplyr::filter(!is.na(parent_name))

# cement_ald |>
#   dplyr::count(uid) |>
#   dplyr::filter(n > 1)

cement_parent_one <- cement_ald |>
  dplyr::select(uid, parent_name, parent_lei, ownership_stake, latitude, longitude)

cement_parent_two <- cement_ald |>
  dplyr::transmute(uid, parent_name = parent_name_2, parent_lei = parent_lei_2, ownership_stake = ownership_stake_2, latitude, longitude) |>
  dplyr::filter(!is.na(parent_name))

cement_parents <- rbind.data.frame(
  cement_parent_one,
  cement_parent_two
)

cement_ald <- cement_ald |>
  dplyr::transmute(
    sector = "Cement",
    uid,
    iso3, latitude, longitude, primary_production_type = production_type, capacity, capacity_source, owner_name, owner_source
  )

cement_ald <- cement_ald |>
  dplyr::left_join(cement_parents, by = c("uid", "longitude", "latitude"))

rm(cement_parent_one, cement_parent_two, cement_parents)


# steel
steel_ald <- openxlsx::read.xlsx("https://spatialfinanceinitiative.com/wp-content/uploads/2021/07/SFI-Global-Steel-Database-July-2021.xlsx", sheet = 2)

steel_ald <- steel_ald |>
  dplyr::filter(status == "Operating")

steel_ald <- steel_ald |>
  dplyr::filter(!is.na(parent_name))

# steel_ald |>
#   dplyr::count(uid) |>
#   dplyr::filter(n > 1)

steel_parent_one <- steel_ald |>
  dplyr::select(uid, parent_name, parent_lei, ownership_stake, latitude, longitude)

steel_parent_two <- steel_ald |>
  dplyr::transmute(uid, parent_name = parent_name_2, parent_lei = parent_lei_2, ownership_stake = ownership_stake_2, latitude, longitude) |>
  dplyr::filter(!is.na(parent_name))

steel_parents <- rbind.data.frame(
  steel_parent_one,
  steel_parent_two
)

steel_ald <- steel_ald |>
  dplyr::transmute(
    sector = "Steel",
    uid,
    iso3, latitude, longitude, primary_production_type, capacity, capacity_source, owner_name, owner_source
  )

steel_ald <- steel_ald |>
  dplyr::left_join(steel_parents, by = c("uid", "longitude", "latitude"))

rm(steel_parent_one, steel_parent_two, steel_parents)

# power
temp <- tempfile()
download.file("https://wri-dataportal-prod.s3.amazonaws.com/manual/global_power_plant_database_v_1_3.zip", temp)
power_ald <- readr::read_csv(unz(temp, "global_power_plant_database.csv"))

power_ald <- power_ald |>
  dplyr::filter(!is.na(owner))

power_ald <- power_ald |>
  dplyr::transmute(
    sector = "Power",
    uid = gppd_idnr,
    iso3 = country, latitude, longitude, primary_production_type = primary_fuel, capacity = capacity_mw, capacity_source = url, owner_name = owner, owner_source = url,
    parent_name = owner, parent_lei = NA, ownership_stake = NA
  )

# ald
ald <- rbind.data.frame(
   cement_ald,
   steel_ald,
   power_ald
 )

# add country
ald <- ald |>
  dplyr::filter(iso3 != "XKX") |>
  dplyr::mutate(
    country = countrycode::countrycode(iso3, origin = 'iso3c', destination = 'country.name')
  )

# save

readr::write_csv(
  ald, fs::path("data", "ald", ext = "csv")
)


rm(cement_ald, steel_ald, power_ald, ald, temp)

