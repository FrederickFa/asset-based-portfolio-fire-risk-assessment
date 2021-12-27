

map <- tabPanel(
  "Interactive map",
  div(
    class="outer",
    tags$head(includeCSS("styles.css")),
    tags$style(type = "text/css",".radio label {font-size: 11px;}"),

    leaflet::leafletOutput("map", width="100%", height="100%"),

    absolutePanel(
      id = "controls", class = "panel panel-default", fixed = TRUE,
      draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
      width = 500, height = "auto",

      h2("Set Specifications"),

      fluidRow(
        column(12,
               h3("Choose Portfolio"),
               selectInput(
                 "portfolios",
                 label = "Portfolio",
                 choices = c("", portfolios |> dplyr::distinct(fund_name) |> dplyr::pull(fund_name)),
                 multiple = FALSE
               ),
               h3("Filter ALD"),
               selectInput(
                 "ald_sector",
                 label = "Sector",
                 choices = ald |> sf::st_drop_geometry() |> dplyr::distinct(sector) |> dplyr::pull(sector),
                 multiple = TRUE
               ),
               selectInput(
                 "company_name",
                 label = "Company Name",
                 choices = ald |> sf::st_drop_geometry() |> dplyr::arrange(Entity.LegalName) |> dplyr::distinct(Entity.LegalName) |> dplyr::pull(Entity.LegalName),
                 multiple = TRUE
               ),

               selectInput(
                 "ald_country",
                 label = "Asset Location",
                 choices = ald |> sf::st_drop_geometry() |> dplyr::distinct(country) |> dplyr::pull(country),
                 multiple = TRUE
               ),

               sliderInput(
                 "ald_distance",
                 label = "Distance to next fire (km, 100km or more)",
                 min = round(as.numeric(min(ald |> sf::st_drop_geometry() |> dplyr::pull(dist), na.rm = T))/1000, 0),
                 max = 100, #round(as.numeric(max(ald |> sf::st_drop_geometry() |> dplyr::pull(dist), na.rm = T))/1000, 0),
                 value = c(
                   round(as.numeric(min(ald |> sf::st_drop_geometry() |> dplyr::pull(dist), na.rm = T))/1000, 0),
                   100
                   #round(as.numeric(max(ald |> sf::st_drop_geometry() |> dplyr::pull(dist), na.rm = T))/1000, 0)
                 )
               ),
               # sliderInput(
               #   "ald_frp",
               #   label = "Radiative Power (MW) of closest fire",
               #   min = round(min(ald |> sf::st_drop_geometry() |> dplyr::pull(frp), na.rm = T),0),
               #   max = round(max(ald |> sf::st_drop_geometry() |> dplyr::pull(frp), na.rm = T),0),
               #   value = c(
               #     round(min(ald |> sf::st_drop_geometry() |> dplyr::pull(frp), na.rm = T),0),
               #     round(max(ald |> sf::st_drop_geometry() |> dplyr::pull(frp), na.rm = T),0)
               #   )
               # ),

               # h3("Filter Fires"),
               # selectInput(
               #   "fire_country",
               #   label = "Fire Location",
               #   choices = spData::world |> sf::st_drop_geometry() |> dplyr::distinct(name_long) |> dplyr::pull(name_long),
               #   multiple = TRUE
               # ),
               # sliderInput(
               #   "fire_distance",
               #   label = "Distance to next ALD (km)",
               #   min = round(as.numeric(min(all_wildfires |> sf::st_drop_geometry() |> dplyr::pull(dist), na.rm = T))/1000, 0),
               #   max = 100, #round(as.numeric(max(all_wildfires |> sf::st_drop_geometry() |> pull(dist), na.rm = T))/1000, 0),
               #   value = c(
               #     round(as.numeric(min(all_wildfires |> sf::st_drop_geometry() |> dplyr::pull(dist), na.rm = T))/1000, 0),
               #     100
               #     #round(as.numeric(max(all_wildfires |> sf::st_drop_geometry() |> dplyr::pull(dist), na.rm = T))/1000, 0)
               #   )
               # ),
               # sliderInput(
               #   "fire_frp",
               #   label = "Fire Radiative Power (MW)",
               #   min = round(min(all_wildfires |> sf::st_drop_geometry() |> dplyr::pull(frp), na.rm = T),0),
               #   max = round(max(all_wildfires |> sf::st_drop_geometry() |> dplyr::pull(frp), na.rm = T),0),
               #   value = c(
               #     50,
               #     round(max(all_wildfires |> sf::st_drop_geometry() |> dplyr::pull(frp), na.rm = T),0)
               #   )
               # ),

               br(),
               h4("Histogram of risk distribution"),
               br(),
               plotOutput("plot", height = 400)

        )
      )
    ),

    tags$div(id="cite",'Portfolio Assessment Tool for Fires (Open-Source & Near-Real-Time)', tags$em('Prototype by Frederick Fabian'), '10/2021')

  )
)



data_explorer <- tabPanel(
  "Map filtered data explorer",
  DT::dataTableOutput("leafmaptable")
)

approach <- tabPanel(
  "Data sources / Approach",

  h3(strong("About")),
  h4(
    "This tool is a prototype that allows stakeholders to assess the risk of fires (especially wildfires) in their financial portfolio.
                    Stakeholders can select or upload their portfolio and identify which physical assets of the companies in their
                    portfolio are currently in the proximity of fires. The aim is to identify among thousands of physical assets in a financial portfolio those
                    that deserve special attention when analysing fire risk. This tool does not take into account the characteristics and vulnerability of an
                    asset and does not calculate/forecast material damage or financial costs. Furthermore, due to the combination of different
                    data sources, some information may be partially incorrect. Also, some of the fires could be under control, have an industrial origin
                    and therefore do not actually pose a risk to a property. The features and advantages of this prototype shown here are the use of granular,
                    near real-time and open-source data and being transparent in terms of data sources, assumptions and modeling. This tool has been developed independently and is not associated with any organisation."
  ),
  br(),

  h3(strong("Approach")),
  br(),
  h4(strong("Preparation of ALD, linkage to parents and assigning Legal Entity Identifiers")),
  h4(
    "The first step is to collect and clean asset-level data (ALD) from different sources. Currently, this tool covers three sectors for which open source ALD is
                    available, namely the energy, cement and steel/iron sectors. In general, each tangible asset is assigned at least one owner
                    (sometimes more than one). While some data sources already assign parent companies to the owners of a physical asset and even disclose the Legal
                    Entity Identifiers (LEI, find more information", a("here", href="https://www.gleif.org/en/about-lei/introducing-the-legal-entity-identifier-lei"), ") of the owner and/or parent,
                    e.g. in the data of the Spatial Finance Initiative, this is not the case for other data sources. Since company names vary across sources, consistent IDs
                    such as LEIs are extremely important to combine different data sources. Therefore, in a second step, a name matching algorithm is applied to match owners and parents
                    contained in the raw ALD dataset with the corresponding names in the Global Legal Identifier Foundation (GLEIF) Level 1 data. For this purpose, this tool builds
                    on the work of the 2° Investing Initiative and its package, ", a("r2dii.match", href="https://2degreesinvesting.github.io/r2dii.match/articles/r2dii-match.html"),
    ". As this tool makes no claim to absolute accuracy, a match is assumed to exist at a score above 95% for names with 8 or more letters and 99% for less than 8
                    letters. The matches can then be assigned the corresponding LEIs. In a third step, the LEIs can be used to loop through the ownership structures of the companies
                    (level 2 data of the GLEIF) and link the owners of physical assets to the actual listed company."
  ),
  br(),
  h4(strong("Preparation of fire data and overlaying ALD")),
  h4(
    "In a fourth step, fire data is downloaded from NASA every 24 hours, reflecting on-going fires spots. This tool only considers fires with a fire radiation power (FRP)
                    above 50 MW (for comparison, ResourceWatch considers fires above 100 MW to be large). This is due to computational limitations on the one hand
                    (displaying 200,000 fires would slow down the application), and on the other hand it helps to identify the risk of larger / more intense fires,
                    and not flag smaller, less important fires. In a fifth step, the nearest fire is assigned to each plant, for which the distance is also calculated."
  ),
  br(),
  h4(strong("Linking everything to a portfolio")),
  h4(
    "Portfolio data should contain an ISIN for each holding. Again, using data of the GLEIF, each ISIN can then be assigned a LEI. In a final step, only assets are considered
                      whose parent's LEI is found in a portfolio."
  ),
  br(),
  br(),
  h4(strong("Outlook")),
  h4(
    "Although this tool is still a prototype, some improvements and further functionalities are already planned. One of them is the addition of a temporal dimension to the fire data, which means that fire data
                      can be displayed for different points in time. This will help to understand the overall fire risk, because even if the risk is low in the last 24 hours due to a wetter / colder period, the overall average
                      risk can still be high. Furthermore, users should have the possibility to upload their portfolio. In addition, the functionality of the filters can be improved, e.g. re-calculating distances based on the chosen inputs.
                      And finally, more hazards will be integrated in the tool in the future."
  ),
  br(),
  h4("The underlying code can be found on", a("GitHub.", href = "https://github.com/FrederickFa/open-source-physical-risk-assessment-portfolio")),
  br(),
  h4("Please feel free to reach out to", a("frederick.fabian@aol.com", href="mailto:frederick.fabian@aol.com"), "for questions and feedback."),
  br(),
  br(),

  h3(strong("Data Sources")),
  h4(strong("For this tool, only the following open-source data was used:")),
  br(),
  tabsetPanel(
    type = "pills",
    tabPanel(
      h5(strong("Asset Level Data (ALD)")),
      br(),
      h5(strong("Cement ALD")),
      h5("McCarten, M., Bayaraa, M., Caldecott, B., Christiaen, C., Foster, P., Hickey, C., Kampmann, D., Layman, C., Rossi, C., Scott, K., Tang, K., Tkachenko, N., and Yoken, D., 2021. Global Database of Cement Production Assets. Spatial Finance Initiative. Available online", a("[https://spatialfinanceinitiative.com/geoasset-project/data/]", href="https://spatialfinanceinitiative.com/geoasset-project/data/")),
      br(),
      h5(strong("Steel ALD")),
      h5("McCarten, M., Bayaraa, M., Caldecott, B., Christiaen, C., Foster, P., Hickey, C., Kampmann, D., Layman, C., Rossi, C., Scott, K., Tang, K., Tkachenko, N., and Yoken, D., 2021. Global Database of Iron and Steel Production Assets. Spatial Finance Initiative. Available online", a("[https://spatialfinanceinitiative.com/geoasset-project/data/]", href="https://spatialfinanceinitiative.com/geoasset-project/data/")),
      br(),
      h5(strong("Power ALD")),
      h5("Global Energy Observatory, Google, KTH Royal Institute of Technology in Stockholm, Enipedia, World Resources Institute, 2019. Global Power Plant Database v1.3.0. Available online", a("[https://datasets.wri.org/dataset/globalpowerplantdatabase]", href="https://datasets.wri.org/dataset/globalpowerplantdatabase")),
      br()
    ),

    tabPanel(
      h5(strong("Fire Data")),
      h5("VIIRS 375m NRT (NOAA-20)	NRT VIIRS 375 m Active Fire product VJ114IMGTDL_NRT distributed from NASA FIRMS. Available online ", a("[https://earthdata.nasa.gov/firms]", href="https://earthdata.nasa.gov/firms"), ". doi: ", a("10.5067/FIRMS/VIIRS/VJ114IMGT_NRT.002", href="https://earthdata.nasa.gov/earth-observation-data/near-real-time/firms/vj114imgtdl-nrt")),
      h5("VIIRS 375m NRT (Suomi NPP)	NRT VIIRS 375 m Active Fire product VNP14IMGT distributed from NASA FIRMS. Available online ", a("[https://earthdata.nasa.gov/firms]", href="https://earthdata.nasa.gov/firms"), ". doi: ", a("10.5067/FIRMS/VIIRS/VNP14IMGT_NRT.002", href="https://earthdata.nasa.gov/earth-observation-data/near-real-time/firms/v1-vnp14imgt")),
      h5("MODIS Collection 61 NRT	MODIS Collection 61 NRT Hotspot / Active Fire Detections MCD14DL distributed from NASA FIRMS. Available online", a("[https://earthdata.nasa.gov/firms]", href="https://earthdata.nasa.gov/firms"), ". doi: ", a("10.5067/FIRMS/MODIS/MCD14DL.NRT.0061", href="https://earthdata.nasa.gov/earth-observation-data/near-real-time/firms/mcd14dl")),
      br(),
      h5("View fire data with NASA's", a("Global Fire Map", href="https://firms.modaps.eosdis.nasa.gov/map/"), "(differences may occur due to different time stamps and applied filters (especially for FRP))"),
      br(),
      br()
    ),

    tabPanel(
      h5(strong("Company & Financial Data")),
      br(),
      h5(strong("Company Data")),
      h5("Global Legal Entity Identifier Foundation (GLEIF), 2021. Level 1 Legal Entity Identifier (LEI) CDF. Available online " , a("https://www.gleif.org/en/lei-data/gleif-golden-copy/download-the-golden-copy#/]", href="https://www.gleif.org/en/lei-data/gleif-golden-copy/download-the-golden-copy#/")),
      br(),
      h5(strong("Ownership Data ALD")),
      h5("Global Legal Entity Identifier Foundation (GLEIF), 2021. Level 2 Relationship Record (RR) CDF. Available online " , a("https://www.gleif.org/en/lei-data/gleif-golden-copy/download-the-golden-copy#/]", href="https://www.gleif.org/en/lei-data/gleif-golden-copy/download-the-golden-copy#/")),
      br(),
      h5(strong("LEI ISIN Relationship")),
      h5("Global Legal Entity Identifier Foundation (GLEIF), 2021. ISIN-to-LEI Relationship. Available online " , a("https://www.gleif.org/en/lei-data/lei-mapping/download-isin-to-lei-relationship-files#]", href="https://www.gleif.org/en/lei-data/lei-mapping/download-isin-to-lei-relationship-files#")),
    ),

    tabPanel(
      h5(strong("Portfolio Data")),
      br(),
      h5(strong("Blackrock Portfolios")),
      h5("Blackrock, 2021. iSHARES FUNDS. Available online " , a("https://www.ishares.com/uk/individual/en/products/etf-investments]", href="https://www.ishares.com/uk/individual/en/products/etf-investments")),
    )
  )

)




ui <- navbarPage(
  div(style='font-size: 25px;', "Portfolio Assessment Tool for Fires (Open-Source & Near-Real-Time)"),
  windowTitle = "",
  id="nav",
  collapsible = TRUE,
  map,
  data_explorer,
  approach
)

