# load data
ald <- readr::read_csv(fs::path("data", "ald", ext = "csv"))
all_matched_names <- readr::read_csv(fs::path("data", "all_matched_names", ext = "csv"))
lei_ownership_data <- readr::read_csv(fs::path("data", "lei_ownership_data", ext = "csv"))
lei_company_data <- readr::read_csv(fs::path("data", "lei_company_data", ext = "csv"))


### after the following lines there are some duplicate due to non-unique lei_alias

ald_mapped <- ald |>
  dplyr::left_join(all_matched_names, by = "ald_alias") |>
  dplyr::as_tibble()

ald_mapped <- ald_mapped |>
  dplyr::left_join(lei_company_data |> dplyr::transmute(LEI, lei_parent_name = Entity.LegalName), by = c("lei" = "LEI"))

ald_mapped <- ald_mapped |>
  dplyr::mutate(
    final_lei = dplyr::if_else(
      is.na(parent_lei), lei, parent_lei
    ),
    lei_info = dplyr::case_when(
      !is.na(parent_lei) ~ "Original LEI",
      is.na(parent_lei) & !is.na(lei) ~ "LEI via name matching",
      is.na(final_lei) ~ "LEI not available"
    )
  )

ald_mapped <- ald_mapped |>
  dplyr::left_join(
    lei_ownership_data |> dplyr::filter(Relationship.RelationshipType == "IS_ULTIMATELY_CONSOLIDATED_BY") |> dplyr::transmute(child_lei = Relationship.StartNode.NodeID, ultimate_lei = Relationship.EndNode.NodeID),
    by = c("final_lei" = "child_lei")
  )

ald_mapped <- ald_mapped |>
  dplyr::mutate(
    ultimate_lei = dplyr::if_else(
      is.na(ultimate_lei), final_lei, ultimate_lei
    )
  )

ald_mapped <- ald_mapped |>
  dplyr::left_join(
    lei_company_data |> dplyr::select(LEI, Entity.LegalName), by = c("ultimate_lei" = "LEI")
  )


# save

readr::write_csv(ald_mapped, fs::path("data", "ald_mapped", ext = "csv"))

rm(ald, all_matched_names, ald_mapped, lei_ownership_data, lei_company_data)
