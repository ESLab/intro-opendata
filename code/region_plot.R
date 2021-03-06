#' Fast wrapper for visualizing regions on a map
#' 
#' @param sp \link{SpatialPolygonsDataFrame} object
#' @param color Colour variable for filling
#' @param region Grouping variable (the desired regions)
#' @param palette Colour palette
#' @param by Interval for colors
#' @param main Plot title
#' 
#' @return \link{ggplot2} object
#'
#' @export
#' @importFrom ggplot2 theme_set
#' @importFrom ggplot2 ggplot
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 geom_polygon
#' @importFrom ggplot2 scale_fill_gradientn
#' @importFrom ggplot2 ggtitle
#' @author Leo Lahti \email{louhos@@googlegroups.com}
#' @references See citation("gisfin") 
#' @examples sp <- get_municipality_map("MML"); region_plot(sp, color = "Kieli_ni1", region = "kuntakoodi") 
library("scales")

getLabelPoint <-
 function(county) {c(mean(county[["lat"]]),mean(county[["long"]]))}
#function(county) {Polygon(county[c('long', 'lat')])@labpt}

region_plot2 <- function (sp, color, region, palette = c("darkblue", "blue", "white", "red", "darkred"), by = 20, main = "", trim=0) {

  # Avoid warnings in build
  fill <- group <- long <- lat <- NULL

  # Get data frame
  df <- sp2df(sp)

  # Define the grouping variable
  df$group <- df[[region]]
  df$fill <- df[[color]]
  if (is.factor(df$fill)) {
    df$fill <- as.numeric(df$fill)
  }

  centroids = print(by(df, df$label, getLabelPoint))
  centroids <- do.call("rbind.data.frame", centroids)

  names(centroids) <- c('lat', 'long')

  # Set map theme
  theme_set(get_theme_map())

  # Plot regions, add labels using the points data
  p <- ggplot(df, aes(x=long, y=lat)) + 
    geom_polygon(aes(fill=fill, group=group)) 

  # Add custom color scale
  brks = seq(from = min(df$fill), to = max(df$fill), by = by)
  full_range = range(df$fill)
  q_range = full_range
  if (trim > 0 && trim < 1) {
	q_range = quantile(df$fill, probs=c(trim, 1.0-trim), names=FALSE)
        #print(q_range)
	#brks = seq(from=rnge[1], to=rnge[2], by=by)
  }
  #print(full_range)
  #print(c (0, seq (full_range[1]/q_range[1], q_range[2]/full_range[2], length.out = 18),1))
  p <- p + scale_fill_gradientn(color,
	colours = colorRampPalette (c ("darkblue", "white", "darkred")) (20),
        values = rescale(c (full_range[1], seq (q_range[1], q_range[2], length.out = 18), full_range[2])))

  p <- p + ggtitle(main)
  p <- p + geom_text(data=centroids, label=row.names(centroids), size=3)
  
  p
}
