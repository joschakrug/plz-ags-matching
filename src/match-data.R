here::i_am("src/match-data.R")

library(dplyr)
library(sf)
library(here)
library(ggplot2)

# A Load PLZ and municipality shapefiles ---------------------------------------

plz <- st_read(here("data-raw", "nrw-postleitzahlen")) |>
  select(
    PLZ = plz_code,
    PLZNAM = plz_name,
    PLZKRS = krs_code,
    geometry
  )

municipalities <- st_read(
    here("data-raw", "Gemeindegrenzen_2022_4404002117365728056")
  ) |>
  select(
    AGS,
    ORTNAM = GEN,
    ORTTYP = BEZ,
    ORTSTAT = BEM,
    geometry
  ) |>
  st_transform(crs = 4326)

# B Intersect PLZ and municipality areas ---------------------------------------

# do not use the s2 library for spherical geometry - this does not handle the
# underlying problem well

sf_use_s2(FALSE)

# only consider matches where the _interiors_ of PLZ area and municipality area
# polygons overlap, not the borders (this significantly cuts down computational
# time)

plzmun <- st_intersection(plz, municipalities, model = "closed")

# example plot for visual inspection and to generate the example figure used in
# the README file

ggplot() +
  geom_sf(
    data = filter(plzmun, stringr::str_sub(AGS, start = 1, end = 2) == "05"),
    fill = "white"
  ) +
  geom_sf(
    data = filter(municipalities, stringr::str_sub(AGS, start = 1, end = 2) == "05"),
    fill = NA, linewidth = 0.5, colour = alpha("red", 0.7)
  ) +
  geom_sf(
    data = filter(plz, stringr::str_sub(PLZKRS, start = 1, end = 2) == "05"),
    fill = NA, linewidth = 0.16, colour = alpha("blue", 1)
  ) +
  theme(
    axis.text = element_text(size = 4)
  )
  
ggplot2::ggsave(
  here("output", "figures", "plz-ags-map_NRW.png"),
  width = 300, height = 300, units = "px", scale = 2
)

plzmun <- select(plzmun, -PLZKRS)

# C Store the results ----------------------------------------------------------

dir.create(here("output", "data", "plz-ags"), showWarnings = FALSE)

st_write(
  plzmun,
  here("output", "data", "plz-ags", "plz-ags.shp"),
  append = FALSE
)

plzmun |>
  select(-geometry) |>
  write.csv(
    here("output", "data", "plz-ags-mapping.csv"),
    row.names = FALSE
  )
