# Based on https://github.com/petegordon/RCloudRun

library(EJAM)
library(geojsonsf)

#' Generate a report
#' @param lat The input sites lat
#' @param lon The input sites long
#' @param shape The input sites geojson
#' @param buffer The input sites buffer
#' @post /report
#' @serializer html
function(lat=NULL,lon=NULL,shape=NULL,fips=NULL,buffer=3){
  buffer=as.numeric(buffer)
  if (is.character(lat) & is.character(lon)){ 
    lat <- as.numeric(lat)
    lon <- as.numeric(lon)
    sites <- data.frame(lat, lon)
    x<-ejamit(sites, radius=buffer)
    } else if (is.character(shape)){
      # convert to sf
      shape<-geojson_sf(shape)
      x<-ejamit(radius=buffer, shapefile = shape)
      } else if (is.character(fips)){
        x<-ejamit(radius=buffer,fips = fips)
        }
        html<-ejam2report(x, return_html=TRUE, launch_browser=FALSE)
        return(html)
        }