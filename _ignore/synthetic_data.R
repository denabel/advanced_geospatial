synthetic_coordinates <- readRDS("../../data/synthetic_survey_coordinates.rds")

foreigners <- 
  z22_data(
    "foreigners",
    res = "1km",
    all_cells = TRUE,
    rasterize = TRUE
  )[[1]]

probs <- terra::values(foreigners) / 100

foreigners$sample <- rbinom(length(probs), size = 1, prob = probs + .1)

synthetic_coordinates$foreigner <- 
  terra::extract(foreigners$sample, synthetic_coordinates, ID = FALSE) |> 
  unlist()

synthetic_coordinates_4326 <- 
  synthetic_coordinates |> 
  dplyr::mutate(
    x = sf::st_coordinates(synthetic_coordinates)[,1],
    y = sf::st_coordinates(synthetic_coordinates)[,2],
    crs = 4326
  ) |> 
  sf::st_drop_geometry()

readr::write_csv(synthetic_coordinates_4326, "../../data/synthetic_coordinates.csv")

saveRDS(synthetic_coordinates, "../../data/synthetic_survey_coordinates.rds")






income_groups <- c(
  "< 1000 €", "1000-1500 €", "1500-2000 €", "2000-2500", "2500-3000 €",
  "< 1000 €", "1000-1500 €", "1500-2000 €", "2000-2500 €", "2500-3000 €",
  "3000-3500 €", "3500-4000 €", "4000-4500 €", "4500-5000 €", "> 5000 €"
)

income_groups <- ordered(income_groups, levels = income_groups, ID)

ownocc <- z22_data(
  "owner_occupier",
  res = "1km",
  all_cells = TRUE,
  rasterize = TRUE
)[[1]]

space <- z22_data(
  "inhabitant_space",
  res = "1km",
  all_cells = TRUE,
  rasterize = TRUE
)[[1]]

rent <- z22_data(
  "rent_avg",
  res = "1km",
  all_cells = TRUE,
  rasterize = TRUE
)[[1]]

comb <- c(ownocc, space, rent)

reg <- terra::regress(comb, seq_len(nlyr(comb)))["x"]

range01 <- function(x) {
  (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
}

# Compute log of the regression output to spread out the value distribution
reg[] <- range01(reg[])
reg_log <- log(reg["x"])
reg_log <- ifel(is.infinite(reg_log), NA, reg_log)

# Classify raster based on quantiles
quants <- values(reg_log) |>
  na.omit() |>
  as.vector() |>
  quantile(probs = seq(0, 1, length.out = length(income_groups) + 1))

cls <- classify(reg_log, quants, include.lowest = TRUE)

sample <- terra::extract(cls, synthetic_coordinates, xy = TRUE, method = "bilinear", ID = FALSE)

names(sample) <- c("val", "x", "y")
sample$val <- as.numeric(sample$val) + 1

# Add normally distributed noise
# Adjust `sd` to control how much noise is added
# sd = 3 results in Moran's ~ 0.16, sd = 1 in Moran's I ~ 0.3
sample$val_noise <- (sample$val + rnorm(length(sample$val), mean = 0, sd = 3)) |>
  scales::rescale(to = c(1, 10)) |>
  round()

sample$income <- income_groups[sample$val_noise]

# Generate fake IDs
income <- cbind(synthetic_coordinates, sample["income"])
  
  
  sample[c("id", "income", "x", "y")]
