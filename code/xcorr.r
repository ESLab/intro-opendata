library("rmongodb")
library("rgeos")
library("plyr")
library("gisfin")
library("gridExtra")
library("ggplot2")
library("gridSVG")
library("rjson")
library("corrgram")

source("region_plot.R")
source("statfi.r")

# Connect to database
mongo = mongo.create(host="trafi_db:27017", username="opendata", password="LEDImpTO", db="trafi")

if (mongo.is.connected(mongo)) {
    print("Connected to MongoDB")
    #Setting up our database query
  
    #First stage: Filter out all vehicles of class "M1", and limit results to sane values, i.e. filter out mistakes that skew statistics, such as cars with 10+ liter engines, and 3000+kW of power...
    stage_1 = mongo.bson.from.JSON(
      paste(readLines('stage1.js'), collapse="")
      )
    
    #Second stage: Group vehicles according to area code (first three numbers in postcode), and average the Co2 emissions, and other interesting parameters for each area
    stage_2 = mongo.bson.from.JSON(
      paste(readLines('stage2.js'), collapse="")
    )

    # Create the command pipeline for MongoDB
    cmd_list = list(stage_1, stage_2)

    # Get result from database
    bson = mongo.aggregation(mongo, "trafi.vehicles", cmd_list)

    # Disconnect from database, we have everything we need now
    mongo.destroy(mongo)

    # Convert data
    raw_list = mongo.bson.to.list(bson)
    trafi = ldply(raw_list[[1]], data.frame)

    # Area codes in the Trafi database contain only the first three numbers of the postcode.
    #  Since postcodes in finland are typically 5 digits, we multiply by 100, 
    # ... and add zeroes to the left if necessary 
    # (for example, the postcode is 00100, not 100)
    trafi$area = sprintf("%03d", trafi$area)
    
    # Get some statistics on population, income, etc. from Tilastokeskus's open database:
    stats = get_stats_by_area()
    
    # merge the statistics with Trafi data
    stats = merge(trafi, stats, by = "area", all=FALSE)

    # Registration date in the database is a number of the form YYYYMMDD (Y=Year, M=Month, D=Day), so
    # we simply approximate the year of registration by dividing this number by 10000 :-)
    stats$year = stats$year/10000
    # Cylinder volume divided by 1000, to give the volume in liters
    stats$vol = stats$vol/1000
    
    # Make a correlogram, which shows correlation between the statistics gathered from Trafi and Tilastokeskus
    corrgram(stats[-1])
} else {
    print("Connection to MongoDB failed!")
}


