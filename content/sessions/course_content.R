course_content <-
  tibble::tribble(
    ~Day, ~Time, ~Title,
    "April 28", "10:00-11:15", "Introduction",
    "April 28", "11:15-11:30", "Coffee Break",
    "April 28", "11:30-13:00", "Raster data in R",
    "April 28", "13:00-14:00", "Lunch Break",
    "April 28", "14:00-15:15", "Raster data processing",
    "April 28", "15:15-15:30", "Coffee Break",
    "April 28", "15:30-17:00", "Graphical display of raster data in maps",
    "April 29", "10:00-11:15", "Datacube processing I",
    "April 29", "11:15-11:30", "Coffee Break",
    "April 29", "11:30-13:00", "Datacube processing II & API access",
    "April 29", "13:00-14:00", "Lunch Break",
    "April 29", "14:00-15:15", "Data integration and linking (with survey data)",
    "April 29", "15:15-15:30", "Coffee Break",
    "April 29", "15:30-17:00", "Outlook and open session with own application"
  ) |>
  knitr::kable() |>
  kableExtra::kable_styling() |>
  kableExtra::column_spec(1, color = "gray") |>
  kableExtra::column_spec(2, color = "gray") |>
  kableExtra::column_spec(3, bold = TRUE) |>
  kableExtra::row_spec(2, color = "gray") |>
  kableExtra::row_spec(4, color = "gray") |>
  kableExtra::row_spec(6, color = "gray") |>
  kableExtra::row_spec(9, color = "gray") |>
  kableExtra::row_spec(11, color = "gray") |>
  kableExtra::row_spec(13, color = "gray") |>
  kableExtra::row_spec(5, extra_css = "border-bottom: 1px solid")
