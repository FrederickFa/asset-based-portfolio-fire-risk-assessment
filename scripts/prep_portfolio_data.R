date <- "20210929"


msci_world <- readr::read_csv(paste0("https://www.ishares.com/uk/individual/en/products/251882/ishares-msci-world-ucits-etf-acc-fund/1506575576011.ajax?fileType=csv&fileName=SWDA_holdings&dataType=fund&asOfDate=", date), skip = 2)


msci_world <- msci_world |>
  janitor::clean_names(case = "snake") |>
  dplyr::mutate(fund_name = "iShares Core MSCI World UCITS ETF")

sp500 <- readr::read_csv(paste0("https://www.ishares.com/uk/individual/en/products/253743/ishares-sp-500-b-ucits-etf-acc-fund/1506575576011.ajax?fileType=csv&fileName=CSPX_holdings&dataType=fund&asOfDate=", date), skip = 2)


sp500 <- sp500 |>
  janitor::clean_names(case = "snake") |>
  dplyr::mutate(fund_name = "iShares Core S&P 500 UCITS ETF")



emimi <- readr::read_csv(paste0("https://www.ishares.com/uk/individual/en/products/264659/ishares-msci-emerging-markets-imi-ucits-etf/1506575576011.ajax?fileType=csv&fileName=EIMI_holdings&dataType=fund&asOfDate=", date), skip = 2)


emimi <- emimi |>
  janitor::clean_names(case = "snake") |>
  dplyr::mutate(fund_name = "iShares Core MSCI EM IMI UCITS ETF")


devmarkets <- readr::read_csv(paste0("https://www.ishares.com/uk/individual/en/products/264659/ishares-msci-emerging-markets-imi-ucits-etf/1506575576011.ajax?fileType=csv&fileName=EIMI_holdings&dataType=fund&asOfDate=", date), skip = 2)


devmarkets <- devmarkets |>
  janitor::clean_names(case = "snake") |>
  dplyr::mutate(fund_name = "iShares Developed World Index Fund (IE)")


cleanenergy <- readr::read_csv(paste0("https://www.ishares.com/uk/individual/en/products/251911/ishares-global-clean-energy-ucits-etf/1506575576011.ajax?fileType=csv&fileName=INRG_holdings&dataType=fund&asOfDate=", date), skip = 2)


cleanenergy <- cleanenergy |>
  janitor::clean_names(case = "snake") |>
  dplyr::mutate(fund_name = "iShares Global Clean Energy UCITS ETF")


msciworldenergy <- readr::read_csv(paste0("https://www.ishares.com/uk/individual/en/products/308904/fund/1506575576011.ajax?fileType=csv&fileName=WENS_holdings&dataType=fund&asOfDate=", date), skip = 2)


msciworldenergy <- msciworldenergy |>
  janitor::clean_names(case = "snake") |>
  dplyr::mutate(fund_name = "iShares MSCI World Energy Sector UCITS ETF")


portfolios <- rbind.data.frame(
  msci_world,
  msciworldenergy,
  emimi,
  devmarkets,
  cleanenergy |> dplyr::select(-x3),
  sp500
)

portfolios <- portfolios |>
  dplyr::left_join(lei_isin, by = c("isin" = "ISIN"))

portfolios <- portfolios |>
  dplyr::filter(!is.na(LEI))


# save

readr::write_csv(portfolios, fs::path("data", "portfolios", ext = "csv"))

rm(msci_world, msciworldenergy, emimi, devmarkets, cleanenergy, sp500, portfolios)

