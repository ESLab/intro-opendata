library("rmongodb")
library("rgeos")
library("plyr")
library("gisfin")
library("gridExtra")
library("ggplot2")
library("gridSVG")

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

    #Now let's get some data on postcode areas in Finland, using the GISFin R library
    pcodes.sp = get_postalcode_areas()
    pcodes.sp$pnro_short = substr(pcodes.sp$pnro, 0, 3) # First three numers of postcode
    pcodes.sp$label = substr(pcodes.sp$pnro, 0, 2) # Generate text labels for the map

    # If we don't want statistics for all of Finland, we can specify sub-areas here 
    # (put a comment mark (#) before all but one "pcodes.subarea.sp = ..." line:

    # Turku area, excluding Åland: 
    #pcodes.subarea.sp = pcodes.sp[(substr(pcodes.sp$pnro, 1, 2) %in% c("20","21","23","24","25","26","27","28","29")), ]

    # Finland, excluding Åland
    pcodes.subarea.sp = pcodes.sp[(!substr(pcodes.sp$pnro, 1, 2) %in% c("22")), ]

    # Ostrobothnia, i.e. postcodes beginning with a 6
    #pcodes.subarea.sp = pcodes.sp[(substr(pcodes.sp$pnro, 1, 1) %in% c("6")), ]


    # Here we merge together the data from Trafi's database, and the map data for postcode regions in Finland
    trafi.sp = merge(pcodes.subarea.sp, trafi, by.x="pnro_short", by.y="area", all = FALSE)
    
    # Get some statistics on population, income, etc. from Tilastokeskus's open database:
    stats = get_stats_by_area()
    # merge the statistics with Trafi data
    trafi.sp = merge(trafi.sp, stats, by="pnro_short", all=FALSE)

    # Registration date in the database is a number of the form YYYYMMDD (Y=Year, M=Month, D=Day), so
    # we simply approximate the year of registration by dividing this number by 10000 :-)
    trafi.sp$year = trafi.sp$year/10000
    # Cylinder volume divided by 1000, to give the volume in liters
    trafi.sp$vol = trafi.sp$vol/1000
    

    # Now we can create maps showing various statistics from the Trafi database, such as average CO2 emissions, average power, and so on...
    plt.co2 = region_plot2(trafi.sp, region="pnro", color="co2", by=5, main="Average CO2 emissions (g/km)", trim=0.01)
    plt.pwr = region_plot2(trafi.sp, region="pnro", color="pwr", by=5, main="Average power (kW)", trim=0.01)
    plt.year = region_plot2(trafi.sp, region="pnro", color="year", by=1, main="Date of first registration", trim=0.01)
    plt.vol = region_plot2(trafi.sp, region="pnro", color="vol", by=0.05, main="Displacement (l)", trim=0.01)

    # Maps of data from Tilastokeskus, i.e. population and income data per area
    plt.income = region_plot2(trafi.sp, region="pnro", color="income", by=1000, main="Income", trim=0.01)
    plt.pop = region_plot2(trafi.sp, region="pnro", color="pop", by=100, main="Population", trim=0.05)
   
	
    # We want to show all our maps in a grid on the screen
    # ncol=2, means the maps will be arranged in a grid two columns wide
    grid.arrange(plt.co2, plt.year, plt.pwr, plt.vol, plt.income, plt.pop, ncol=3)
    #grid.export(name="Abo.svg")  
} else {
    print("Connection to MongoDB failed!")
}


