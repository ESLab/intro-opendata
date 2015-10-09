get_stats_by_area <- function() {
# Get municipality population data from Statistics Finland
# using the pxweb package
library(pxweb)

mydata <- get_pxweb_data(url = "http://pxwebapi2.stat.fi/PXWeb/api/v1/fi/Postinumeroalueittainen_avoin_tieto/2015/paavo_9_koko_2015.px",
             dims = list(Postinumeroalue = c('*'),
                         Tiedot = c('Hr_ktu', 'He_vakiy')),
             clean = FALSE)

print(head(mydata))
# Pick municipality ID from the text field
mydata$pnro <- sapply(strsplit(as.character(mydata$Postinumeroalue), " "), function (x) x[[1]])
mydata$area = substr(mydata$pnro, 0, 3)
mydata$income = as.numeric(mydata$"Asukkaiden keskitulot, 2012 (HR)")
mydata$pop = as.numeric(mydata$"Asukkaat yhteensä, 2013 (HE)")

aggdata = aggregate(mydata, by=list(mydata$area),
  FUN=mean, na.rm=TRUE)

data = aggdata[c("Group.1", "income", "pop")]
colnames(data) <- c("area", "income", "pop")

return(data)
}

