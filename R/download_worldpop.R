#' Download and Process WorldPop Population Raster Data
#'
#' This function downloads and processes population or age-sex structure raster layers 
#' from the WorldPop database for specified countries and years.
#'
#' @param year Integer or vector of years to download data for (e.g., 2010:2020).
#' @param country Character vector of country ISO3 codes (e.g., "KEN", "UGA").
#' @param indicator Character; one of "population", "f_*", "m_*", or "all".
#'        Use "f_*" and "m_*" for age-sex breakdowns (e.g., "f_0", "m_5"), 
#'        or "all" to download all available population and  age-sex layers.
#' @param cellsize Numeric; cell size in meters for raster aggregation (default = 5000).
#' @param progress Logical; whether to display progress bars during download (default = TRUE).
#'
#' @return A multi-dimensional `stars` object containing rasterized population or demographic data.
#' @export
#'
#' @examples
#' \dontrun{
#'   download_worldpop(
#'     year = 2020, 
#'     country = "KEN", 
#'     indicator = "all", 
#'     cellsize = 10000
#'    )
#' }

download_worldpop <- 
  function (
    year,
    country,
    indicator = c("population", "f_*", "m_*", "all"),
    cellsize = 5000,
    progress = TRUE
  ) {
    
    # If indicator is "all", create a full list of age-sex breakdowns and total population
    if(indicator == "all") {
      indicator = c(
        "population", 
        paste0("f_", seq(0, 80, by = 5)),
        paste0("m_", seq(0, 80, by = 5))
      )
    }
    
    # Create a grid of combinations of year, country, and indicator
    request_grid <- tidyr::expand_grid(year, country, indicator)
    
    # Helper function to download and process one layer of data
    download_wrangle <- function(year, country, indicator) {
      
      # Construct URL for total population
      if(indicator == "population") {
        request_url <-
          glue::glue(
            "https://data.worldpop.org/GIS/Population/",
            "Global_2000_2020_1km/{year}/{country}/",
            "{tolower(country)}_ppp_{year}_1km_Aggregated.tif"
          )
      }
      
      # Construct URL for age-sex structured data
      if(grepl("f_", indicator) | grepl("m_", indicator)) {
        request_url <-
          glue::glue(
            "https://data.worldpop.org/GIS/AgeSex_structures/",
            "Global_2000_2020_1km/unconstrained/{year}/{country}/",
            "{tolower(country)}_{indicator}_{year}_1km.tif"
          )
      }
      
      # Download and preprocess the raster data
      download_worldpop_layer <- function(year){
        tmp_layer <- 
          terra::rast(request_url) |> 
          terra::aggregate(fact = cellsize / 1000) |>    # Aggregate to desired resolution
          terra::as.points(na.rm = TRUE) |>              # Convert to points, removing NAs
          sf::st_as_sf() |>                              # Convert to sf object
          sf::st_transform(3035) |>                      # Transform to EPSG:3035 (Europe Equal Area)
          dplyr::mutate(year = year) |> 
          dplyr::select(!!indicator := 1, year)          # Rename value column to indicator
      }
      
      # Download and convert raster to stars object
      raster_layer <- 
        purrr::pmap_dfr(list(year), download_worldpop_layer) |> 
        dplyr::group_split(year) |> 
        purrr::map(~{
          stars::st_rasterize(.x, dx = cellsize, dy = cellsize)
        })
      
      # Combine yearly rasters into one stars object with a time dimension
      raster_layer <- do.call(c, c(raster_layer, along = "year"))
      
      # Set time dimension from years
      times <- 
        paste0(year, "-01-01") |> 
        as.Date()
      
      raster_layer$year <- NULL
      
      stars::st_dimensions(raster_layer)$year <- 
        stars:::create_dimension(values = times)
      
      raster_layer
    }
    
    # Apply download function across all indicator/country/year combinations
    raster_layer <-
      request_grid |> 
      dplyr::mutate(
        layer = 
          furrr::future_pmap(
            request_grid, download_wrangle, .progress = progress
          )
      ) |> 
      dplyr::group_split(indicator) |> 
      purrr::map(~{.x$layer |> purrr::reduce(c, along = "year")}) |> 
      purrr::reduce(c)
  }
