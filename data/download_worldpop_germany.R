library(dplyr)
library(furrr)
library(purrr)
library(sf)
library(stars)
library(stringr)

plan(multisession, workers = 4)

worldpop_germany <- 
  download_worldpop(
    year = c(2000:2020),
    country = "DEU",
    indicator = "all",
    cellsize = 10000
  ) |>
  dplyr::mutate(
    gender_ratio = 
      rowSums(dplyr::across(dplyr::starts_with("f_")), na.rm = TRUE) /
      rowSums(dplyr::across(dplyr::starts_with("m_")), na.rm = TRUE),
    women_young = 
      (rowSums(
        dplyr::across(dplyr::matches("f_15|f_20|f_25|f_30|f_35|f_40|f_45")), 
        na.rm = TRUE) / population) * 100,
    older_population = 
      (rowSums(dplyr::across(dplyr::matches("60|65|70|75|80")), na.rm = TRUE) /
         population) * 100
  )

qs::qsave(worldpop_germany, "./data/worldpop_germany.qs")

stars::write_stars(
  worldpop_germany["population"], 
  "./data/population_germany.nc"
)

stars::write_stars(
  worldpop_germany["gender_ratio"] |> 
    dplyr::filter(year == "2000-01-01"), 
  "./data/gender_ratio_2000.tif"
)

stars::write_stars(
  worldpop_germany["gender_ratio"] |> 
    dplyr::filter(year == "2020-01-01"), 
  "./data/gender_ratio_2020.tif"
)

stars::write_stars(
  worldpop_germany["older_population"] |> 
    dplyr::filter(year == "2000-01-01"), 
  "./data/older_population_2000.tif"
)

stars::write_stars(
  worldpop_germany["older_population"] |> 
    dplyr::filter(year == "2020-01-01"), 
  "./data/older_population_2020.tif"
)
