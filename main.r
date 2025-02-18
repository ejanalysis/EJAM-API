# Based on https://github.com/petegordon/RCloudRun
library(plumber)

r <- plumb("rest_controller.r")
r$run(port=8080, host="0.0.0.0")