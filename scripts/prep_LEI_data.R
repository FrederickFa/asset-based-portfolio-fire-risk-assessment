hyperlink_lei_cdf_v2.1_csv <- "https://leidata-preview.gleif.org/storage/golden-copy-files/2021/12/26/579060/20211226-0800-gleif-goldencopy-lei2-golden-copy.csv.zip#"
hyperlink_rr_cdf_v1.1_csv <- "https://leidata-preview.gleif.org/storage/golden-copy-files/2021/12/26/579105/20211226-0800-gleif-goldencopy-rr-golden-copy.csv.zip#"
hyperlink_isin_to_leif <- "https://isinmapping.gleif.org/api/v2/isin-lei/3558/download"


# specify elements of hyperlinks
date <- stringr::str_remove_all(c(Sys.Date()), "-")

temp <- tempfile()

download.file(hyperlink_lei_cdf_v2.1_csv, temp)
lei_company_data <- readr::read_csv(unz(temp, paste0(date, "-0800-gleif-goldencopy-lei2-golden-copy.csv")))

lei_company_data <- lei_company_data |>
  dplyr::select(Entity.LegalName, LEI)

download.file(hyperlink_rr_cdf_v1.1_csv, temp)
lei_ownership_data <- readr::read_csv(unz(temp, paste0(date, "-0800-gleif-goldencopy-rr-golden-copy.csv")))

lei_ownership_data <- lei_ownership_data |>
  dplyr::select(Relationship.RelationshipType, Relationship.StartNode.NodeID, Relationship.EndNode.NodeID)

download.file(hyperlink_isin_to_leif, temp)
lei_isin <- readr::read_csv(unz(temp, paste0("ISIN_LEI_", date, ".csv")))


# code for automated updates

# # specify elements of hyperlinks
# todays_date <- Sys.Date()
# todays_date_first_path_element <- stringr::str_replace_all(c(Sys.Date()), "-", "/")
# todays_date_second_path_element <- stringr::str_remove_all(c(Sys.Date()), "-")
#
# # extract starting ID from hyperlink
# id <- 544097
#
# lei_company_data <- NULL
#
# while(!is.data.frame(lei_company_data)) {
#
#   id <- id + 1
#   print((id))
#
#   temp <- tempfile()
#   try(download.file(paste0("https://leidata-preview.gleif.org/storage/golden-copy-files/", todays_date_first_path_element, "/", id, "/", todays_date_second_path_element, "-0000-gleif-goldencopy-lei2-golden-copy.csv.zip"),temp))
#   try(lei_company_data <- readr::read_csv(unz(temp, paste0(todays_date_second_path_element, "-0000-gleif-goldencopy-lei2-golden-copy.csv"))))
#
#   Sys.sleep(0.2)
# }
#
# lei_ownership_data <- NULL
#
# while(!is.data.frame(lei_ownership_data)) {
#
#   id <- id + 1
#   print((id))
#
#   temp <- tempfile()
#   try(download.file(paste0("https://leidata-preview.gleif.org/storage/golden-copy-files/", todays_date_first_path_element, "/", id, "/", todays_date_second_path_element, "-0000-gleif-goldencopy-rr-golden-copy.csv.zip"), temp))
#   try(lei_ownership_data <- readr::read_csv(unz(temp, paste0(todays_date_second_path_element, "-0000-gleif-goldencopy-rr-golden-copy.csv"))))
#
#   Sys.sleep(0.2)
# }
#
#
# download.file(paste0("https://isinmapping.gleif.org/file-by-date/", todays_date_second_path_element), temp)
# lei_isin <- readr::read_csv(unz(temp, paste0("ISIN_LEI_", todays_date_second_path_element, ".csv")))
#
# rm(temp, id, todays_date, todays_date_first_path_element, todays_date_second_path_element)


# save
readr::write_csv(lei_company_data, fs::path("data", "lei_company_data", ext = "csv"))

readr::write_csv(lei_ownership_data, fs::path("data", "lei_ownership_data", ext = "csv"))

readr::write_csv(lei_isin, fs::path("data", "lei_isin", ext = "csv"))


rm(hyperlink_lei_cdf_v2.1_csv, hyperlink_rr_cdf_v1.1_csv, hyperlink_isin_to_leif, date, temp, lei_company_data, lei_ownership_data, lei_isin)

