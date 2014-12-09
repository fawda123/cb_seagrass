library(rgeos)
centers <- gCentroid(segs, byid = T)
labs <- na.omit(data.frame(centers, segs = segs$CBPSEG))
labs <- aggregate(. ~ segs, labs, mean)
labs <- SpatialPointsDataFrame(labs[, c('x', 'y')], data = data.frame(segs = labs$segs))

