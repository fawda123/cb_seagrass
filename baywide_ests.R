# packages to use
library(maptools)
library(reshape2) 
library(plyr)
library(ggplot2)
library(scales)
library(RColorBrewer)
library(gridExtra)
library(sp)

# functions to use
source('funcs.r')

# load data
bounds <- readShapeSpatial('dat/cb_poly.shp')
segs <- readShapeSpatial('dat/sg_segs.shp')
sgbuff <- readShapeSpatial('dat/grid_polys.shp')
# load('dat/sgpts.RData')

# # get all bay estimates
# grid_spc <- 0.01
# radius <- 0.1
# grid_seed <- 1234
# set.seed(grid_seed)
#
# pts <- grid_est(sgbuff, spacing = grid_spc) 
# tmp <- doc_est_grd(pts, sgpts, trace = T)
# sg_ests <- tmp
# save(sg_ests, file = 'dat/sg_ests.RData')

load(file = 'dat/sg_ests.RData')
sg_ests <- data.frame(sg_ests)
filt_val <- quantile(sg_ests$doc_med, 0.9)
sg_ests <- sg_ests[sg_ests$doc_med <= filt_val, ]

p1 <- ggplot(bounds, aes(long, lat)) + 
  geom_polygon(fill = 'grey', aes(group = piece)) +
  theme_classic() +
  coord_equal() +
  xlab('Longitude') +
	ylab('Latitude') +
  geom_point(
    data = data.frame(sg_ests),
    aes(x = Var1, y = Var2, colour = doc_med, size = doc_med), 
  ) +
  scale_colour_gradientn(colours = brewer.pal(9, 'BuGn')) +
  scale_size_continuous(range = c(1, 10)) +
  theme(
    text = element_text(size=20), 
    legend.position = c(0, 1),
    legend.justification = c(0, 1)
    ) +
  labs(colour = 'Depth (m)', size = 'Depth (m)') + 
  guides(colour = guide_legend(), size = guide_legend())

load(file = 'dat/sg_ests.RData')
segs <- readShapeSpatial('dat/sg_segs.shp')
tmp <- over(segs, sg_ests, fn = function(x) mean(x, na.rm = T))
sg_ests <- na.omit(data.frame(CBPSEG = segs@data$CBPSEG, tmp))
sg_ests <- aggregate(. ~ CBPSEG, sg_ests, function(x) mean(x, na.rm = T))
sg_ests <- sp::merge(segs, sg_ests, by = 'CBPSEG', all.x = T)

segs_plo <- fortify(sg_ests)
segs_plo <- na.omit(cbind(segs_plo, sg_ests@data[segs_plo$id, ]))

p2 <- ggplot(bounds, aes(long, lat, group = piece)) + 
  geom_polygon(fill = 'grey') +
  geom_polygon(data = segs_plo, aes(long, lat, fill = doc_med, group = group)) +
  theme_classic() +
  coord_equal() +
  xlab('Longitude') +
  ylab('Latitude') +
  scale_fill_gradientn(colours = brewer.pal(9, 'BuGn')) +
  theme(
    text = element_text(size=20), 
    legend.position = c(0, 1),
    legend.justification = c(0, 1)
    ) +
  labs(fill = 'Depth (m)') 

grid.arrange(p1, p2, ncol = 2)
