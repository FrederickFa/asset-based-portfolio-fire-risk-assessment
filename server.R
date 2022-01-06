
server <- function(input, output, session) {

  # Disclaimer
  observeEvent(
    input$show, {
      showModal(
        modalDialog(
          title = "About this application",
          h4(
            "This tool is a prototype that allows stakeholders to assess the risk of fires (especially wildfires) in their financial portfolio.
            Stakeholders can select or upload their portfolio and identify which physical assets of the companies in their portfolio are currently
            in the proximity of fires. The aim is to identify among thousands of physical assets in a financial portfolio those that deserve special
            attention when analysing fire risk. This tool does not take into account the characteristics and vulnerability of an asset and does not
            calculate/forecast material damage or financial costs. The features and advantages of this prototype shown here are the use of granular,
            near real-time and open-source data and being transparent in terms of data sources, assumptions and modeling. This tool has been developed
            independently and is not associated with any organisation."
          ),
          br(),
          h4(
            "This tool has three different sections. The main page features a map which visualises the underlying data, which can be downloaded in
            the second section. The third section explains the approach as well as discloses the different data sources."
          ),
          br(),
          h4("This version is still a prototype which will see further improvements in the next months.")
        )
      )
    },
    ignoreNULL = F
  )


  # reactive ald subset
  ald_sub <- reactive(
    {
      ald_sub <- ald

      # portfolio input
      if(isTruthy(input$portfolios) & input$portfolios != "") {
        print(paste0("Portfolio Input: ", input$portfolios))

        leis <- portfolios |> dplyr::filter(fund_name %in% input$portfolios) |> dplyr::pull(LEI)
        ald_sub <- ald_sub |> dplyr::filter(ultimate_lei %in% leis)
      }

      # ald sector input
      if(isTruthy(input$ald_sector)) {
        print(paste0("ALD Sector Input: ", input$ald_sector))

        ald_sub <- ald_sub |> dplyr::filter(sector == input$ald_sector)
      }

      # company name input
      if(isTruthy(input$company_name)) {
        print(paste0("Company Name Input: ", input$company_name))

        ald_sub <- ald_sub |> dplyr::filter(Entity.LegalName == input$company_name)
      }

      # ald country input
      if(isTruthy(input$ald_country)) {
        print(paste0("ALD Country Input: ", input$ald_country))

        ald_sub <- ald_sub |> dplyr::filter(country == input$ald_country)
      }

      # ald fire distance input
      if(isTruthy(input$ald_distance)) {
        print(paste0("ALD Distance Input: ", input$ald_distance))

        ald_sub <- ald_sub |> dplyr::filter(dplyr::between(dist/1000, input$ald_distance[1], dplyr::if_else(input$ald_distance[2] == 100, Inf, as.double(input$ald_distance[2]))))
      }

      # ald frp input
      if(isTruthy(input$ald_frp)) {
        print(paste0("ALD FRP Input: ", input$ald_frp))

        ald_sub <- ald_sub |> dplyr::filter(dplyr::between(frp, input$ald_frp[1], input$ald_frp[2]))
      }


      return(ald_sub)
    }
  )

  assets_within_bounds <- reactive({
    if (!is.null(input$map_bounds)) {

      bounds <- input$map_bounds
      latRng <- range(bounds$north, bounds$south)
      lngRng <- range(bounds$east, bounds$west)

      assets_within_bounds <- subset(ald_sub(),
                     lat >= latRng[1] & lat <= latRng[2] &
                       long >= lngRng[1] & long <= lngRng[2])

    } else (assets_within_bounds <- ald_sub())

    return(assets_within_bounds)

  })

  output$plot <- renderPlot({
    if (nrow(assets_within_bounds()) == 0)
      return(NULL)

    ggplot2::ggplot(assets_within_bounds()) +
      ggplot2::theme_minimal() +
      ggplot2::geom_bar(ggplot2::aes(x = distlevel)) +
      ggplot2::theme(
        axis.text = ggplot2::element_text(size = 12),
        axis.title = ggplot2::element_text(size = 16)
      ) +
      ggplot2::labs(
        x = "Distance to next fire",
        y = "Number of assets"
      ) +
      ggplot2::coord_flip()
  })

  # reactive fires subset
  wildfires <- reactive(
    {
      all_wildfires_sub <- all_wildfires

      # fire distance input
      if(isTruthy(input$fire_distance)) {
        print(paste0("Fire Distance Input: ", input$fire_distance))

        all_wildfires_sub <- all_wildfires_sub |> dplyr::filter(dplyr::between(dist/1000, input$fire_distance[1], dplyr::if_else(input$fire_distance[2] == 100, Inf, as.double(input$fire_distance[2]))))
      }

      # fire frp input
      if(isTruthy(input$fire_frp)) {
        print(paste0("Fire FRP Input: ", input$fire_frp))

        all_wildfires_sub <- all_wildfires_sub |> dplyr::filter(dplyr::between(frp, input$fire_frp[1], input$fire_frp[2]))
      }

      # fire country input
      if(isTruthy(input$ald_country)) {
        print(paste0("Fire Country Input: ", input$ald_country))

        all_wildfires_sub <- all_wildfires_sub |> dplyr::filter(name_long == input$ald_country)
      }

      return(all_wildfires_sub)
    }
  )

  # company name selectize
  updateSelectizeInput(
    session, "company_name",
    label = "Company Name",
    choices = ald |> sf::st_drop_geometry() |> dplyr::arrange(Entity.LegalName) |> dplyr::distinct(Entity.LegalName) |> dplyr::pull(Entity.LegalName),
    server = TRUE
  )

  # update available company names based on portfolio input
  observeEvent(
    input$portfolios, {
      updateSelectizeInput(
        session, "company_name",
        label = "Company Name",
        choices = ald_sub() |> sf::st_drop_geometry() |> dplyr::arrange(Entity.LegalName) |> dplyr::distinct(Entity.LegalName) |> dplyr::pull(Entity.LegalName)
      )
    }
  )

  # update available company names based on ald sector input
  observeEvent(
    input$ald_sector, {
      updateSelectizeInput(
        session, "company_name",
        label = "Company Name",
        choices = ald_sub() |> sf::st_drop_geometry() |> dplyr::arrange(Entity.LegalName) |> dplyr::distinct(Entity.LegalName) |> dplyr::pull(Entity.LegalName)
      )
    }
  )


  output$map <- leaflet::renderLeaflet({

    map <- leaflet::leaflet(ald_sub()) |>
      leaflet::addTiles(
        group = "OpenStreetMap", options = leaflet::providerTileOptions(
          updateWhenZooming = FALSE,
          updateWhenIdle = TRUE
        )
      ) |>
      leaflet.esri::addEsriBasemapLayer(
        leaflet.esri::esriBasemapLayers$Gray, group = "Grey", options = leaflet::providerTileOptions(
          updateWhenZooming = FALSE,
          updateWhenIdle = TRUE
        )
      ) |>
      leaflet::addProviderTiles(
        "Esri.WorldImagery", group = "Satellite", options = leaflet::providerTileOptions(
          updateWhenZooming = FALSE,
          updateWhenIdle = TRUE
        )
      ) |>
      # leaflet.extras2::addGIBS(
      #   layers = leaflet.extras2::gibs_layers$title[c(272)],
      #   dates = Sys.Date() - 20,
      #   group = "Night Lights"
      # ) |>
      leaflet::addLayersControl(
        baseGroups = c(
          "OpenStreetMap",
          "Satellite",
          "Grey"
          #"Night Lights"
        ),
        options = leaflet::layersControlOptions(collapsed = FALSE),
        position = "topleft"
      ) |>
      leaflet.extras::addHeatmap(data = wildfires(), radius = 5, gradient = c("darkred", "red", "orange", "yellow"), minOpacity = 1) |>
      leaflet::addCircles(
        data = ald_sub(),
        color = ~ palette(distlevel),
        opacity = 0.7,
        radius = 12,
        label = ~ sector,
        popup = ~paste0(
          "<br/><strong>Sector: </strong>", sector,
          "<br/><strong>Primary Technology: </strong>", primary_production_type,
          "<br/><strong>Direct Asset Owner: </strong>", owner_name,
          "<br/><strong>Owner Source: </strong>","<a href =\"",owner_source, '"\", target=\"_blank\">', owner_source, '</a>',
          "<br/><strong>Distance next fire: </strong>", round(dist/1000), " (km)",
          "<br/>",

          "<br/><strong>Direct Parent (Raw Data): </strong>", parent_name,
          "<br/><strong>Matched Direct Parent (from GLEIF): </strong>", lei_parent_name,
          "<br/><strong>Score of Match (if matched): </strong>", round(score,2),
          "<br/><strong>Source of LEI for Direct Parent: </strong>", lei_info,
          "<br/>",
          "<br/><strong>Ultimate Parent Company (through LEI ownership tree): </strong>", Entity.LegalName
        )
      ) |>
      leaflet::addLegend(
        position = "bottomleft",
        pal = palette,
        values = ~ distlevel,
        title = "Distance to next fire",
        opacity = 1
      )

    if(!isTruthy(input$ald_country)) {
      map <- map |>
        leaflet::setView(50, 34, 3)
    }

    return(map)
  })

  # adjust heat map when zooming
  observeEvent(
    eventExpr = input$map_zoom, {
      bounds <- input$map_bounds
      lat_mid <- round((bounds$north + bounds$south) / 2, 2)
      long_mid <- round((bounds$east + bounds$west) / 2, 2)

      print(paste0("Map Zoom: ", input$map_zoom))
      print(paste0("Map Coordinates Zoom: ", lat_mid, " (latitude) ", long_mid, " (longitude)"))

      leaflet::leafletProxy(
        mapId = "map",
        session = session
      ) |>
        leaflet.extras::clearHeatmap() |>
        leaflet.extras::addHeatmap(
          data = wildfires(),
          radius = input$map_zoom + 1,
          gradient = c("darkred", "red", "orange", "yellow"), minOpacity = 1)
    },
    ignoreNULL = F
  )

  # data table for exploration + downloading the data
  output$leafmaptable = DT::renderDataTable({

    DT::datatable(
      ald_sub() |>
        sf::st_drop_geometry() |>
        dplyr::mutate(
          dist = round(dist/1000,0),
          owner_source = ifelse(is.na(owner_source), NA, paste0("<a href='", owner_source,"' target='_blank'>", owner_source,"</a>")),
          capacity_source = ifelse(is.na(capacity_source), NA, paste0("<a href='", capacity_source,"' target='_blank'>", capacity_source,"</a>")),
          lei_info = ifelse(lei_info == "Original LEI", "Via Original LEI", lei_info)
        ) |>
        dplyr::arrange((Entity.LegalName)) |>

        dplyr::transmute(
          `Asset ID` = uid,
          Sector = sector,
          `Country (ISO3)` = iso3,
          Owner = owner_name,
          `Owner Source` = owner_source,
          `Direct Parent (Raw Data)` = parent_name,
          `Matched Direct Parent (from GLEIF)` = lei_parent_name,
          `Score of Match (if matched)` = round(score, 2),
          `Source of LEI for Direct Parent` = lei_info,
          `Ultimate Parent` = Entity.LegalName,
          `Ultimate Parent LEI` = ultimate_lei,
          `Capacity` = capacity,
          `Capacity Unit` = capacity_unit,
          `Capacity Source` = capacity_source,
          `Fire Radiative Power (MW)` = frp,
          `Distance to next fire (km)` = dist
        ),
      filter = "top",
      extensions = "Buttons",
      options = list(
        dom = "Bfrtlip",
        lengthMenu = list(
          c(10, 50, -1),
          c('10', '50','All')
        ),
        buttons = list(
          'copy',
          'csv',
          list(extend = 'excel', title = NULL),
          'pdf'
        )
      ),
      escape = F
    )

  })

}

