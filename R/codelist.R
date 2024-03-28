source("R/00_libraries.R")
source("R/01_utils.R")

url <- "https://web.archive.org/web/20231201200525/https:/www.phpc.cam.ac.uk/pcu/research/research-groups/crmh/cprd_cam/codelists/v11/"

links <- obtain_links(url) |> 
  (\(x) x[grepl("zip$", x)])() |> 
  head(46) |> 
  (\(x) gsub("https://web.archive.org/web/20231201200525/", "", x))()

unzipped_files <- links |> 
  map(
    ~ download_unzip_files(
      zip_url = .x,
      directory = "data",
      zip_file_pattern = ".csv$"
    )
  )


description_files <- list.files(
  "data",
  pattern = "DESCRIPTION",
  full.names = TRUE
)

descriptions <- set_names(
  description_files,
  basename(description_files)
) |> 
  map_df(
    ~ read.csv(
      .x,
      fileEncoding = "Windows-1252"
    ),
    .id = "filename"
  )

prod_code_files <- list.files(
  "data",
  pattern = "PC",
  full.names = TRUE
) |>
  (\(x) x[!grepl("DESCRIPTION", x)])()


prod_codes <- set_names(
  prod_code_files,
  basename(prod_code_files)
) |> 
  map_df(
    ~ read.csv(
      .x,
      colClasses = c("character", "character", "character", "character")
    ),
    .id = "filename"
  ) |> 
  mutate(
    CONDITION.CODE = str_extract(
      filename,
      pattern = "[A-Z]{3}[0-9]{3}"
    ),
    CONDITION.CODE = gsub("[0-9]", "", CONDITION.CODE),
    .after = filename
  )

med_code_files <- list.files(
  "data",
  pattern = "MC",
  full.names = TRUE
) |>
  (\(x) x[!grepl("DESCRIPTION", x)])()

med_codes <- set_names(
  med_code_files,
  basename(med_code_files)
) |> 
  map_df(
    ~ read.csv(
      .x,
      colClasses = c("character", "character", "character", "character")
    ),
    .id = "filename"
  ) |> 
  mutate(
    CONDITION.CODE = str_extract(
      filename,
      pattern = "[A-Z]{3}[0-9]{3}"
    ),
    CONDITION.CODE = gsub("[0-9]", "", CONDITION.CODE),
    .after = filename
  )

med_codes_definition <- descriptions |> 
  filter(
    TYPE == "MEDCODES"
  ) |> 
  select(
    "CONDITION.CODE",
    "CONDITION.DESCRIPTION",
    "USAGE.DEFINITION"
  ) |> 
  distinct() |> 
  right_join(
    med_codes,
    by = join_by(
      CONDITION.CODE
    ),
    relationship = "one-to-many"
  ) |> 
  select(!c("filename"))

prod_codes_definition <- descriptions |> 
  filter(
    TYPE == "PRODCODES"
  ) |> 
  select(
    "CONDITION.CODE",
    "CONDITION.DESCRIPTION",
    "USAGE.DEFINITION"
  ) |> 
  distinct() |> 
  right_join(
    prod_codes,
    by = join_by(
      CONDITION.CODE
    ),
    relationship = "one-to-many"
  ) |> 
  select(!c("filename"))

# gemscript to dmd lkp
gemscript_lkp <- read.delim(
  "https://www.whatdotheyknow.com/request/gemscript_drug_code_to_snomed_dm/response/1609899/attach/2/gemscript%20dmd%202020%2007.txt?cookie_passthrough=1"
) |> 
  select(
    "gemscriptcode",
    "dmdcode"
  )

# apply lkp to prod code table
prod_codes_definition <- prod_codes_definition |> 
  left_join(
    gemscript_lkp,
    by = join_by(
      gemscriptcode
    )
  )

cover_sheet <- descriptions |> 
  select(c("CONDITION.CODE", 
           "CONDITION.DESCRIPTION",
           "USAGE.DEFINITION",
           "TYPE",
           "NUMBER.OF.CODES")) |> 
  distinct()

if (!isTRUE(file.info("outputs")$isdir)) 
  dir.create("outputs", recursive = TRUE)

writexl::write_xlsx(
  x = list(
    `cover sheet` = cover_sheet,
    medcodes = med_codes_definition,
    prodcodes = prod_codes_definition
  ),
  path = "outputs/data_specification.xlsx"
)

