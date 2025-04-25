library(haven) # For working with SPSS datafiles
library(sjlabelled) # To remove labels from STATA datafiles
library(tidyverse) # For so much

issp <- 
  haven::read_dta("./data/ZA8793_v1-0-0.dta") |> 
  sjlabelled::remove_all_labels() |> 
  dplyr::select(
    year, 
    country, 
    concern = v42
  ) |> 
  dplyr::mutate(
    country = 
      factor(
        country, 
        levels = c(
          36, 40, 100, 124, 152, 158, 191, 203, 208, 246, 250, 276, 348, 352, 
          372, 376, 380, 392, 410, 428, 440, 484, 528, 554, 578, 608, 620, 643, 
          703, 705, 710, 724, 752, 756, 826, 840, 82602
        ), 
        labels = c(
          "Australia", "Austria", "Bulgaria", "Canada", "Chile", "Taiwan", 
          "Croatia", "Czechia", "Denmark", "Finland", "France", "Germany",
          "Hungary", "Iceland", "Ireland", "Israel", "Italy", "Japan", 
          "South Korea", "Latvia", "Lithuania", "Mexico", "Netherlands",
          "New Zealand", "Norway", "Philippines", "Portugal", "Russia", 
          "Slovakia", "Slovenia", "South Africa", "Spain", "Sweden", 
          "Switzerland", "Great Britain", "USA", "Northern Ireland"
        )
      ),
    country = dplyr::case_when(
      country == "Great Britain" | country == "Northern Ireland" ~ 
        "United Kingdom",
      TRUE ~ country
    ),
    concern = dplyr::case_match(
      concern,
      1 ~ 5,
      2 ~ 4,
      3 ~ 3,
      4 ~ 2,
      5 ~ 1
    )
  )

# Define Likert-theme
likert_theme <- theme_gray() +
  theme(text = element_text(size = 12, face = "bold"),
        plot.title = element_text(size = 13, face = "bold",
                                  margin = margin(10, 0, 10, 0)), 
        plot.margin = unit(c(.4,0,.4,.4), "cm"),
        plot.subtitle = element_text(face = "italic"),
        legend.title = element_blank(),
        legend.key.size = unit(1, "line"),
        legend.background = element_rect(fill = "grey90"),
        panel.grid = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        panel.background = element_blank(),
        strip.text = element_text(size = 12, face = "bold"))

# Let's look at 2020 only
issp_2020 <- 
  issp |> 
  dplyr::filter(year == "2020")

# Plot
likert_plot_2020 <-
  issp_2020 |>
  filter(!is.na(concern)) |>
  mutate(country = forcats::fct_reorder(country, concern, 
                                            .fun=mean, .desc=FALSE)) |> 
  arrange(country) |>
  group_by(country, concern) |>
  summarize(count = n()) |>
  group_by(country) |> 
  mutate(prop_value = count / sum(count)) |>
  ggplot() +
  geom_bar(mapping = aes(x = country,
                         y = prop_value,
                         fill = forcats::fct_rev(factor(concern))),
           position = "fill",
           stat = "identity")+
  geom_text(aes(x = country, y = prop_value, label = round(100*prop_value)), 
            position = position_stack(vjust = 0.5), 
            fontface = "bold") +
  scale_fill_brewer(type = "div", palette = "PRGn", direction = -1,
                    labels = c("5 - High concern", "4", "3", "2", "1 - No concern")) +
  coord_flip() +
  likert_theme +
  theme(legend.position = "bottom") +
  guides(fill = guide_legend(reverse = TRUE, nrow =1))
