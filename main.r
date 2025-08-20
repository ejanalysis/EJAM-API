# Based on https://github.com/petegordon/RCloudRun
library(plumber)

# r <- plumb("rest_controller.r")
r <- plumb("rest2.r")
r$run(port=8080, host="0.0.0.0")

# Examples
#
# Block Group in the Phoenix, AZ area with a 1 mile buffer: https://ejamapi-84652557241.us-central1.run.app/report?buffer=1&fips=040131109012
#
# A point in the Phoenix area with a 4 mile buffer: https://ejamapi-84652557241.us-central1.run.app/report?lat=33&lon=-112&buffer=4
#
# A rectangular area of interest in Phoenix, with no buffer: https://ejamapi-84652557241.us-central1.run.app/report?shape=%7B"type"%3A"FeatureCollection"%2C"features"%3A%5B%7B"type"%3A"Feature"%2C"properties"%3A%7B%7D%2C"geometry"%3A%7B"coordinates"%3A%5B%5B%5B-112.01991856401462%2C33.51124624304089%5D%2C%5B-112.01991856401462%2C33.47010908826502%5D%2C%5B-111.95488826248605%2C33.47010908826502%5D%2C%5B-111.95488826248605%2C33.51124624304089%5D%2C%5B-112.01991856401462%2C33.51124624304089%5D%5D%5D%2C"type"%3A"Polygon"%7D%7D%5D%7D&buffer=0

#
# fname_source <- "./rest2.R"
# library(EJAM)
# library(plumber)
# root <- pr(fname_source)
# pr_run(root)
