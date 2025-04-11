# Based on https://github.com/petegordon/RCloudRun

library(EJAM)
library(geojsonsf)
# install.packages("pagedown")
# library(pagedown)

#* Generate a report
#* @param lat The input sites lat
#* @param lon The input sites long
#* @param shape The input sites geojson
#* @param buffer The input sites buffer
#* @get /report
#* @serializer html
function(lat = NULL,
         lon = NULL,
         shape = NULL,
         fips = NULL,
         buffer = 3,
         format = 'html') {
  html <<- ""
  error <<- "<html><body><h3>Error</h3>" # default error template
  buffer <- as.numeric(buffer)
  # test if buffer is too big
  flag <<- 0
  if (buffer > 15) {
    html <- paste(error,
                  "Please select a buffer 15 miles in radius or less</body></html>",
                  sep = " ")
    flag <<- 1
  } else if (is.character(lat) &
             is.character(lon)) {
    
    method <- "latlon"
    # test if point input
    lat <- as.numeric(lat)
    lon <- as.numeric(lon)
    sites <- data.frame(lat, lon)
    tryCatch(
      latlon_from_anything(sites),
      error = function(e) {
        flag <<- 1
      },
      warning = function(w) {
        flag <<- 1
      }
    )
    tryCatch(
      x <- ejamit(sites, radius = buffer),
      error = function(e) {
        flag <<- 1
      },
      warning = function(w) {
        flag <<- 1
      }
    )
    if (flag == 1) {
      html <<- paste(
        error,
        "There seems to be an issue with the coordinates you provided.</body></html>",
        sep = " "
      )
    }
  } else if (is.character(shape)) {
    method <- "SHP"
    # test if shape input
    # try to convert to sf https://stackoverflow.com/questions/66457617/trycatch-in-r-programming
    tryCatch(
      shape <- geojson_sf(shape),
      error = function(e) {
        flag <<- 1
      }
    )
    if (flag == 1) {
      html <<- paste(error,
                     "There seems to be an issue with the shape you provided.</body></html>",
                     sep = " ")
    } else {
      x <- ejamit(radius = buffer, shapefile = shape)
    }
  } else if (is.character(fips)) {
    method <- "FIPS"
    tryCatch(
      x <- ejamit(radius = buffer, fips = fips),
      error = function(e) {
        flag <<- 1
      }
    )
    if (flag == 1) {
      html <<- paste(
        error,
        "There seems to be an issue with the Census FIPS code provided.</body></html>",
        sep = " "
      )
    }
  } else{
    # No points, shape, or FIPS. EJAM produces a dummy report by default, but we won't do that
    flag <<- 1
    html <<- paste(
      error,
      "You need to provide valid points, a shape, or a Census FIPS code.</body></html>",
      sep = " "
    )
  }
  if (flag == 1) {
    html <<- html # return error message
  } else {
    tryCatch(
      html <<- ejam2report(x, sitenumber = 1, return_html = TRUE, launch_browser = FALSE, submitted_upload_method = method),
      error = function(e) {
        flag <<- 1
      }
    )
    if (flag == 1) {
      html <<- paste(error, "There seems to be an issue producing the report.</body></html>", sep = " ")
    } else { # no error making html, now try converting to PDF if requested
      if (format == 'pdf'){
        tryCatch(
          html <<- ejam2report(x, sitenumber = 1, return_html = FALSE, launch_browser = FALSE, submitted_upload_method = method),
          error = function(e) {
            flag <<- 1
          }
        )
        if (flag == 1) {
          html <<- paste(error, "There seems to be an issue making the PDF.</body></html>", sep = " ")
        }
      }
    }
  }
  return(html)
}

#* @assets ./assets /
list()