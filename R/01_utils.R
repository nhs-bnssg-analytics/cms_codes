obtain_links <- function(url, include_link_text = FALSE) {
  url_html <- xml2::read_html(url)
  
  links <- url_html |> 
    rvest::html_nodes("a") |> 
    rvest::html_attr("href")
  
  if (include_link_text) {
    link_text <- url_html |> 
      rvest::html_nodes("a") %>%
      rvest::html_text() |> 
      str_squish()
    
    links <- set_names(
      links,
      nm = link_text
    )
  }
  
  return(links)
}


download_unzip_files <- function(zip_url, directory, zip_file_pattern) {
  if (!isTRUE(file.info(directory)$isdir)) 
    dir.create(directory, recursive = TRUE)
  
  temp <- tempfile()
  
  download.file(zip_url,
                temp)
  
  zipped_files <- unzip(
    zipfile = temp, 
    list = TRUE
  ) |> 
    filter(
      grepl(zip_file_pattern, Name)
    ) |> 
    pull(Name)
  
  # remove files that already exist in the directory and are in the zip file
  list.files(directory, full.names = TRUE) |> 
    dplyr::intersect(zipped_files) |> 
    file.remove() |> 
    invisible()
  
  
  zipped_files <- unzip(
    zipfile = temp,
    files = zipped_files,
    exdir = directory
  )
  
  unlink(temp)
  
  return(zipped_files)
}