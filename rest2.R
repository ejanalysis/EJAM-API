# Load necessary libraries
library(rlang)
library(plumber)
library(EJAM)
library(geojsonsf)
library(jsonlite)
library(sf)

# Centralized error handling function
handle_error <- function(message, type = "json") {
  if (type == "html") {
    return(paste0("<html><body><h3>Error</h3><p>", message, "</p></body></html>"))
  }
  return(list(error = message))
}
####################################################################################################### #

#* Serve static assets from the ./assets directory
#* @assets ./assets /
list()
####################################################################################################### #


#* Get EJAM analysis results table as JSON (on one site or the aggregate of multiple sites overall)
#* See ejanalysis.org/docs for more information about the ejamit() function
#* @param lat if provided, a vector of latitudes in decimal degrees
#* @param lon if provided, a vector of longitudes in decimal degrees
#* @param sitepoints data.table with columns lat, lon giving point locations of sites or facilities around which are circular buffers
#*
#* @param radius in miles, defining circular buffer around a site point, or buffer to add to polygon
#* @param radius_donut_lower_edge radius of lower edge of donut ring if analyzing a ring not circle
#* @param maxradius  do not use
#* @param avoidorphans do not use
#* @param quadtree do not use
#* @param fips optional FIPS code vector to provide if using FIPS instead of sitepoints to specify places to analyze,
#*  such as a list of US Counties or tracts. Passed to [getblocksnearby_from_fips()]
#*
#* @param shapefile optional. A sf shapefile object or path to .zip, .gdb, .json, .kml, etc., or folder that has a shapefiles, to analyze polygons.
#*  e.g., `out = ejamit(shapefile = testdata("portland.json", quiet = T), radius = 0)`
#*  If in RStudio you want it to interactively prompt you to pick a file,
#*  use shapefile=1 (otherwise it assumes you want to pick a latlon file).
#*
#* @param countcols character vector of names of variables to aggregate within a buffer using a sum of counts,
#*  like, for example, the number of people for whom a poverty ratio is known,
#*  the count of which is the exact denominator needed to correctly calculate percent low income.
#* @param wtdmeancols character vector of names of variables to aggregate within a buffer using population-weighted or other-weighted mean.
#* @param calculatedcols character vector of names of variables to aggregate within a buffer using formulas that have to be specified.
#* @param calctype_maxbg character vector of names of variables to aggregate within a buffer
#*  using max() of all blockgroup-level values.
#* @param calctype_minbg character vector of names of variables to aggregate within a buffer
#*  using min() of all blockgroup-level values.
#* @param subgroups_type Optional (uses default). Set this to "nh" for non-hispanic race subgroups
#*  as in Non-Hispanic White Alone, nhwa and others in names_d_subgroups_nh;
#*  "alone" for race subgroups like White Alone, wa and others in names_d_subgroups_alone;
#*  "both" for both versions. Possibly another option is "original" or "default"
#*  Alone means single race.
#* @param include_ejindexes whether to try to include EJ Indexes (assuming dataset is available) - passed to [doaggregate()]
#* @param calculate_ratios whether to calculate and return ratio of each indicator to US and State overall averages - passed to [doaggregate()]
#* @param extra_demog if should include more indicators from v2.2 report on language etc.
#* @param need_proximityscore whether to calculate proximity scores
#* @param infer_sitepoints set to TRUE to try to infer the lat,lon of each site around which the blocks in sites2blocks were found.
#*  lat,lon of each site will be approximated as average of nearby blocks,
#*  although a more accurate slower way would be to use reported distance of each of 3 of the furthest block points and triangulate
#* @param need_blockwt if fips parameter is used, passed to [getblocksnearby_from_fips()]
#* @param thresholds list of percentiles like list(80,90) passed to
#*  batch.summarize(), to be
#*  counted to report how many of each set of indicators exceed thresholds
#*  at each site. (see default)
#* @param threshnames list of groups of variable names (see default)
#* @param threshgroups list of text names of the groups (see default)
#* @param progress_all progress bar from app in R shiny to run
#* @param updateProgress progress bar function passed to [doaggregate()] in shiny app
#* @param updateProgress_getblocks progress bar function passed to [getblocksnearby()] in shiny app
#* @param in_shiny if fips parameter is used, passed to [getblocksnearby_from_fips()]
#* @param quiet Optional. passed to [getblocksnearby()] and [batch.summarize()]. set to TRUE to avoid message about using [getblocks_diagnostics()],
#*  which is relevant only if a user saved the output of this function.
#* @param silentinteractive to prevent long output showing in console in RStudio when in interactive mode,
#*  passed to [doaggregate()] also. app server sets this to TRUE when calling [doaggregate()] but
#*  [ejamit()] default is to set this to FALSE when calling [doaggregate()].
#* @param called_by_ejamit Set to TRUE by [ejamit()] to suppress some outputs even if ejamit(silentinteractive=F)
#* @param testing used while testing this function, passed to [doaggregate()]
#* @param showdrinkingwater T/F whether to include drinking water indicator values or display as NA. Defaults to TRUE.
#* @param showpctowned T/f whether to include percent owner-occupied units indicator values or display as NA. Defaults to TRUE.
#* @param download_city_fips_bounds passed to [area_sqmi()]
#* @param download_noncity_fips_bounds passed to [area_sqmi()]
#*
#* @param geometries A boolean to indicate whether to include geometries in the output
#* @param overall A boolean - TRUE means return only the overall results
#*   for all sites as a whole. FALSE means return a table of results, site by site
#*   (and if only 1 site was specified the site by site table has only 1 row)
#* @post /ejamit
function(
    # mostly the same arguments as ejamit() except lat,lon allowed, and geometries instead of ...
  lat = NULL,
  lon = NULL,
  sitepoints = NULL,
  radius = 3,
  radius_donut_lower_edge = 0,
  maxradius = 31.07,
  avoidorphans = FALSE,
  quadtree = NULL,
  fips = NULL,
  shapefile = NULL,
  countcols = NULL,
  wtdmeancols = NULL,
  calculatedcols = NULL,
  calctype_maxbg = NULL,
  calctype_minbg = NULL,
  subgroups_type = "nh",
  include_ejindexes = TRUE,
  calculate_ratios = TRUE,
  extra_demog = TRUE,
  need_proximityscore = FALSE,
  infer_sitepoints = FALSE,
  need_blockwt = TRUE,
  thresholds = list(80, 80),
  threshnames = list(c(names_ej_pctile, names_ej_state_pctile), c(names_ej_supp_pctile, names_ej_supp_state_pctile)),
  threshgroups = list("EJ-US-or-ST", "Supp-US-or-ST"),
  updateProgress = NULL,
  updateProgress_getblocks = NULL,
  progress_all = NULL,
  in_shiny = FALSE,
  quiet = TRUE,
  silentinteractive = FALSE,
  called_by_ejamit = TRUE,
  testing = FALSE,
  showdrinkingwater = TRUE,
  showpctowned = TRUE,
  download_city_fips_bounds = TRUE,
  download_noncity_fips_bounds = FALSE,

  geometries = TRUE,
  overall = FALSE
) {

  crs = 4326

  ## ejamit() does the error checking

  if (!missing(lat) && !is.null(lat) && !missing(lon) && !is.null(lon)) {
    sitepoints <- sitepoints_from_any(anything = lat, lon_if_used = lon)
  }

  result <- tryCatch(
    ejamit(
      sitepoints = sitepoints,
      radius,
      radius_donut_lower_edge,
      maxradius,
      avoidorphans,
      quadtree,
      fips,
      shapefile,
      countcols,
      wtdmeancols,
      calculatedcols,
      calctype_maxbg,
      calctype_minbg,
      subgroups_type,
      include_ejindexes,
      calculate_ratios,
      extra_demog,
      need_proximityscore,
      infer_sitepoints,
      need_blockwt,
      thresholds,
      threshnames,
      threshgroups,
      updateProgress,
      updateProgress_getblocks,
      progress_all,
      in_shiny,
      quiet,
      silentinteractive,
      called_by_ejamit,
      testing,
      showdrinkingwater,
      showpctowned,
      download_city_fips_bounds,
      download_noncity_fips_bounds
    ),
    error = function(e) {
      res$status <- 400
      handle_error(e$message)
    }
  )

  # If an error was returned from the interface, return it.
  if ("error" %in% names(result)) {
    return(result)
  }

  # Prepare the final JSON output.
  method <- result$sitetype
  if (geometries) {
    # since geo requested use results_bysite, not overall, since the bysite table has what they would want
    output_shape <- switch(method,
                           "latlon" = shape_buffered_from_shapefile_points(results$results_bysite, radius.miles = radius, crs = crs),
                           # sf::st_as_sf(results$results_bysite, coords = c("lon", "lat"), crs = 4326), # cleaned up table based on sitepoints input

                           "shp" = geojson_sf(shapefile_from_any(shapefile)), # not exactly the same as what ejamit() does

                           "fips" = shapes_from_fips(results_bysite$ejam_uniq_id) # fips gets cleaned up and returned as results_bysite$ejam_uniq_id
    )
    # Combine the analysis results with the geographic shapes.
    return(cbind(data.table::setDF(result$results_bysite), output_shape))
  } else {
    if (overall) {
      return(results$results_overall)
    } else {
      return(result$results_bysite)
    }
  }
}
####################################################################################################### #


#* Get EJAM analysis results report as HTML (on one site or the aggregate of multiple sites overall)
#* See ejanalysis.org/docs for more information about the ejamit() and ejam2report() functions
#* @param sitenumber if provided, reports on specified row in results table of sites,
#*   instead of on overall aggregate of all sites analyzed (default)
#*
#* @param lat if provided, a vector of latitudes in decimal degrees
#* @param lon if provided, a vector of longitudes in decimal degrees
#* @param sitepoints data.table with columns lat, lon giving point locations of sites or facilities around which are circular buffers
#*
#* @param radius in miles, defining circular buffer around a site point, or buffer to add to polygon
#* @param radius_donut_lower_edge radius of lower edge of donut ring if analyzing a ring not circle
#* @param maxradius  do not use
#* @param avoidorphans do not use
#* @param quadtree do not use
#* #* @param fips optional FIPS code vector to provide if using FIPS instead of sitepoints to specify places to analyze,
#*  such as a list of US Counties or tracts. Passed to [getblocksnearby_from_fips()]
#*
#* @param shapefile optional. A sf shapefile object or path to .zip, .gdb, .json, .kml, etc., or folder that has a shapefiles, to analyze polygons.
#*  e.g., `out = ejamit(shapefile = testdata("portland.json", quiet = T), radius = 0)`
#*  If in RStudio you want it to interactively prompt you to pick a file,
#*  use shapefile=1 (otherwise it assumes you want to pick a latlon file).
#*
#* @param countcols character vector of names of variables to aggregate within a buffer using a sum of counts,
#*  like, for example, the number of people for whom a poverty ratio is known,
#*  the count of which is the exact denominator needed to correctly calculate percent low income.
#* @param wtdmeancols character vector of names of variables to aggregate within a buffer using population-weighted or other-weighted mean.
#* @param calculatedcols character vector of names of variables to aggregate within a buffer using formulas that have to be specified.
#* @param calctype_maxbg character vector of names of variables to aggregate within a buffer
#*  using max() of all blockgroup-level values.
#* @param calctype_minbg character vector of names of variables to aggregate within a buffer
#*  using min() of all blockgroup-level values.
#* @param subgroups_type Optional (uses default). Set this to "nh" for non-hispanic race subgroups
#*  as in Non-Hispanic White Alone, nhwa and others in names_d_subgroups_nh;
#*  "alone" for race subgroups like White Alone, wa and others in names_d_subgroups_alone;
#*  "both" for both versions. Possibly another option is "original" or "default"
#*  Alone means single race.
#* @param include_ejindexes whether to try to include EJ Indexes (assuming dataset is available) - passed to [doaggregate()]
#* @param calculate_ratios whether to calculate and return ratio of each indicator to US and State overall averages - passed to [doaggregate()]
#* @param extra_demog if should include more indicators from v2.2 report on language etc.
#* @param need_proximityscore whether to calculate proximity scores
#* @param infer_sitepoints set to TRUE to try to infer the lat,lon of each site around which the blocks in sites2blocks were found.
#*  lat,lon of each site will be approximated as average of nearby blocks,
#*  although a more accurate slower way would be to use reported distance of each of 3 of the furthest block points and triangulate
#* @param need_blockwt if fips parameter is used, passed to [getblocksnearby_from_fips()]
#* @param thresholds list of percentiles like list(80,90) passed to
#*  batch.summarize(), to be
#*  counted to report how many of each set of indicators exceed thresholds
#*  at each site. (see default)
#* @param threshnames list of groups of variable names (see default)
#* @param threshgroups list of text names of the groups (see default)
#* @param progress_all progress bar from app in R shiny to run
#* @param updateProgress progress bar function passed to [doaggregate()] in shiny app
#* @param updateProgress_getblocks progress bar function passed to [getblocksnearby()] in shiny app
#* @param in_shiny if fips parameter is used, passed to [getblocksnearby_from_fips()]
#* @param quiet Optional. passed to [getblocksnearby()] and [batch.summarize()]. set to TRUE to avoid message about using [getblocks_diagnostics()],
#*  which is relevant only if a user saved the output of this function.
#* @param silentinteractive to prevent long output showing in console in RStudio when in interactive mode,
#*  passed to [doaggregate()] also. app server sets this to TRUE when calling [doaggregate()] but
#*  [ejamit()] default is to set this to FALSE when calling [doaggregate()].
#* @param called_by_ejamit Set to TRUE by [ejamit()] to suppress some outputs even if ejamit(silentinteractive=F)
#* @param testing used while testing this function, passed to [doaggregate()]
#* @param showdrinkingwater T/F whether to include drinking water indicator values or display as NA. Defaults to TRUE.
#* @param showpctowned T/f whether to include percent owner-occupied units indicator values or display as NA. Defaults to TRUE.
#* @param download_city_fips_bounds passed to [area_sqmi()]
#* @param download_noncity_fips_bounds passed to [area_sqmi()]
#*
#* @get /report
#* @serializer html
function(
    sitenumber = NULL,
    # mosty the same arguments as ejamit() except lat,lon allowed,sitenumber allowed, and no ...
    lat = NULL,
    lon = NULL,
    sitepoints = NULL,
    radius = 3,
    radius_donut_lower_edge = 0,
    maxradius = 31.07,
    avoidorphans = FALSE,
    quadtree = NULL,
    fips = NULL,
    shapefile = NULL,
    countcols = NULL,
    wtdmeancols = NULL,
    calculatedcols = NULL,
    calctype_maxbg = NULL,
    calctype_minbg = NULL,
    subgroups_type = "nh",
    include_ejindexes = TRUE,
    calculate_ratios = TRUE,
    extra_demog = TRUE,
    need_proximityscore = FALSE,
    infer_sitepoints = FALSE,
    need_blockwt = TRUE,
    thresholds = list(80, 80),
    threshnames = list(c(names_ej_pctile, names_ej_state_pctile), c(names_ej_supp_pctile, names_ej_supp_state_pctile)),
    threshgroups = list("EJ-US-or-ST", "Supp-US-or-ST"),
    updateProgress = NULL,
    updateProgress_getblocks = NULL,
    progress_all = NULL,
    in_shiny = FALSE,
    quiet = TRUE,
    silentinteractive = FALSE,
    called_by_ejamit = TRUE,
    testing = FALSE,
    showdrinkingwater = TRUE,
    showpctowned = TRUE,
    download_city_fips_bounds = TRUE,
    download_noncity_fips_bounds = FALSE
) {

  crs = 4326

  ## ejamit() does error checking

  if (!missing(lat) && !is.null(lat) && !missing(lon) && !is.null(lon)) {
    sitepoints <- sitepoints_from_any(anything = lat, lon_if_used = lon)
  }

  ## we could avoid running analysis of all sites if many are submitted but
  ## only one is going to be reported on (ie sitenumber was specified)
  ## BUT we would need to NOT provide sitenumber param to ejam2report() if this is done
  # if (!is.null(sitenumber)) {
  #   sitenumber <- as.numeric(sitenumber)
  #   if (!missing(shapefile) && !is.null(shapefile)) {
  #     shapefile = shapefile[sitenumber, ]
  #   } else {
  #     if (!missing(fips) && !is.null(fips)) {
  #       fips = fips[sitenumber]
  #     } else {
  #       if (!missing(sitepoints) && !is.null(sitepoints)) {
  #         sitepoints <- sitepoints[sitenumber, ]
  #       }
  #     }
  #   }
  # }

  result <- tryCatch(
    ejamit(
      sitepoints,
      radius,
      radius_donut_lower_edge,
      maxradius,
      avoidorphans,
      quadtree,
      fips,
      shapefile,
      countcols,
      wtdmeancols,
      calculatedcols,
      calctype_maxbg,
      calctype_minbg,
      subgroups_type,
      include_ejindexes,
      calculate_ratios,
      extra_demog,
      need_proximityscore,
      infer_sitepoints,
      need_blockwt,
      thresholds,
      threshnames,
      threshgroups,
      updateProgress,
      updateProgress_getblocks,
      progress_all,
      in_shiny,
      quiet,
      silentinteractive,
      called_by_ejamit,
      testing,
      showdrinkingwater,
      showpctowned,
      download_city_fips_bounds,
      download_noncity_fips_bounds
    ),
    error = function(e) {
      res$status <- 400
      handle_error(e$message)
    }
  )

  # If an error was returned from the interface, return it.
  if ("error" %in% names(result)) {
    return(result)
  }

  # Prepare the final JSON output.
  # Generate and return the HTML report.
  ejam2report(result,
              sitenumber = sitenumber, #############
              return_html = TRUE,
              launch_browser = FALSE)
}
####################################################################################################### #
