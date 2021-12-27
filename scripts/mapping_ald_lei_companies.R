# load data
ald <- readr::read_csv(fs::path("data", "ald", ext = "csv"))
lei_company_data <- readr::read_csv(fs::path("data", "lei_company_data", ext = "csv"))

# start mapping process

ald <- ald |>
  dplyr::mutate(ald_alias = r2dii.match:::to_alias(parent_name))

ald_names <- ald |>
  dplyr::filter(is.na(parent_lei)) |>
  dplyr::transmute(
    ald_alias,
    ald_alias_start_letters = stringr::str_sub(ald_alias, 1,1),
    ald_alias_length = stringr::str_count(ald_alias)
  ) |>
  dplyr::distinct()

lei_names <- lei_company_data |>
  dplyr::transmute(
    lei_alias = r2dii.match:::to_alias(Entity.LegalName),
    lei_alias_start_letters = stringr::str_sub(lei_alias, 1,1),
    lei_alias_length = stringr::str_count(lei_alias),
    lei = LEI
  )


lower_threshold_alias_length <- 0.8
upper_threshold_alias_length <- 1.2

min_ald_alias_length <- floor(min(ald_names$ald_alias_length)*lower_threshold_alias_length)
max_ald_alias_length <- ceiling(max(ald_names$ald_alias_length)*upper_threshold_alias_length)


lei_names <- lei_names |>
  dplyr::filter(
    lei_alias_start_letters %in% unique(ald_names$ald_alias_start_letters),
    dplyr::between(lei_alias_length, min_ald_alias_length, max_ald_alias_length)
  ) |>
  dplyr::distinct()



all_matched_names <- data.frame(
  lei_alias = NA,
  ald_alias = NA,
  score = NA
)

matched_ald_names <- 0
unique_ald_names <- length(unique(ald_names$ald_alias))
all_duration <- NA

for (single_letter in letters) {

  ald_names_sub <- ald_names |>
    dplyr::filter(ald_alias_start_letters == single_letter)

  lei_names_sub <- lei_names |>
    dplyr::filter(lei_alias_start_letters == single_letter)



  for (ald_alias_sub in ald_names_sub$ald_alias) {


    matched_ald_names <- matched_ald_names + 1
    cat(crayon::green("Matching name Nr.", matched_ald_names, "of total", unique_ald_names, "unique names", "| "))

    # define start time to get an estimate how much time is needed to match the data
    start_time <- Sys.time()

    lei_names_sub_sub <- lei_names_sub |>
      dplyr::filter(
        lei_alias_start_letters == stringr::str_sub(ald_alias_sub, 1,1),
        dplyr::between(
          lei_alias_length,
          floor(stringr::str_count(ald_alias_sub)*lower_threshold_alias_length),
          ceiling(stringr::str_count(ald_alias_sub)*upper_threshold_alias_length)
        )
      )

    crossed_names <- tidyr::crossing(lei_alias = lei_names_sub_sub$lei_alias, ald_alias = ald_alias_sub)

    crossed_names <- crossed_names |>
      dplyr::mutate(
        score = stringdist::stringsim(lei_alias, ald_alias, method = "jw", p = 0.1)
      )

    matched_names <- crossed_names |>
      dplyr::slice_max(score, n = 1)

    all_matched_names <- rbind.data.frame(
      all_matched_names,
      matched_names
    )

    # determine the end time
    end_time <- Sys.time()

    # calculate how long it took
    duration <- as.double(end_time) - as.double(start_time)
    all_duration <- c(all_duration, duration)

    # estimate how many minutes are left based on current processing time
    minutes_left <- round((unique_ald_names - matched_ald_names)*mean(all_duration, na.rm = TRUE)/60,0)

    # print estimated processing time which is left
    cat(crayon::yellow("Roughly ", minutes_left, " minutes left", "\n"))
  }
}

all_matched_names <- all_matched_names |>
  dplyr::filter(!is.na(ald_alias))

all_matched_names <- all_matched_names |>
  dplyr::filter(score > 0.99 | (score > 0.95 & stringr::str_count(lei_alias) > 7))

all_matched_names <- all_matched_names |>
  dplyr::arrange(score)

all_matched_names <- all_matched_names |>
  dplyr::distinct(ald_alias, .keep_all = TRUE)

all_matched_names <- all_matched_names |>
  dplyr::left_join(lei_names |> dplyr::select(lei_alias, lei) |> dplyr::distinct(lei_alias, .keep_all = TRUE), by = "lei_alias")


# save

readr::write_csv(all_matched_names, fs::path("data", "all_matched_names", ext = "csv"))
readr::write_csv(ald, fs::path("data", "ald", ext = "csv"))


rm(ald, ald_names, ald_names_sub, all_matched_names, crossed_names, lei_names, lei_names_sub, lei_names_sub_sub, matched_names,
   lei_company_data, ald_alias_sub, all_duration, duration, end_time, minutes_left, min_ald_alias_length, max_ald_alias_length,
   single_letter, start_time, unique_ald_names, upper_threshold_alias_length, lower_threshold_alias_length, matched_ald_names)


