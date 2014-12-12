# packages to use
library(maptools)
library(reshape2) 
library(plyr)
library(ggplot2)
library(scales)
library(RColorBrewer)
library(gridExtra)
library(sp)
library(bitops)
library(labeling)
library(dichromat)

# functions to use
source('funcs.r')

# load data
bounds <- readShapeSpatial('dat/cb_poly.shp')
segs <- readShapeSpatial('dat/sg_segs.shp')
sgbuff <- readShapeSpatial('dat/grid_polys.shp')
sgcover <- readShapeSpatial('dat/sg_cover.shp')
load('dat/sgpts.RData')
load('dat/labs.RData')

# set ggplot theme
theme_set(theme_bw())

# Define server logic required to generate and plot data
shinyServer(function(input, output) {
  
  # dynamic controls
  # pick test pt once pts are selected
  output$pts <- renderUI({
    
    segment <- input$seg
    seg_shp <- sgbuff[sgbuff$CBPSEG %in% segment, ]
    grid_spc <- input$grid_spc
    grid_seed <- input$grid_seed
    set.seed(grid_seed)
    pts <- grid_est(seg_shp, spacing = grid_spc) 
    
    selectInput(inputId = 'test_point',
                label = h3('Test point'),
                choices = 1:length(pts)
      )
     
    })
  
  output$segplot <- renderPlot({
    
    # plotting code
    
    # input from ui
    segment <- input$seg
    
    # get data from loaded shapefiles and input segment
    seg_leg <- segs[segs$CBPSEG %in% segment, ]
   
    pseg <- ggplot(bounds, aes(long, lat)) + 
        geom_polygon(fill = 'lightgrey', aes(group = piece)) +
        geom_polygon(
            data = seg_leg,
            aes(long, lat, group = piece, fill = 'Segment'),
          ) +
        geom_polygon(
              data = sgcover,
              aes(long, lat, group = piece, fill = 'Seagrass'),
            ) +
        geom_text(data = data.frame(labs), aes(x = x, y = y, label = segs), size = 3.5) +
        theme_classic() +
          coord_equal() +
          xlab('Longitude') +
      		ylab('Latitude') +
      scale_fill_manual('', values = c('lightgreen', 'lightblue')) +
      theme(legend.position = c(0, 1), legend.justification = c(0, 1), text = element_text(size=20))
    
    pseg
    
    },height = 900, width = 900)

  # second tab    
  output$simplot <- renderPlot({
    
    # plotting code
    
    # input from ui
    segment <- input$seg
    grid_spc <- input$grid_spc
    test_point <- input$test_point
    point_lab <- input$point_lab
    radius <- input$radius
    show_all <- input$show_all
    grid_seed <- input$grid_seed
    
    # get data from loaded shapefiles and input segment
    seg_shp <- sgbuff[sgbuff$CBPSEG %in% segment, ]
    seg_leg <- segs[segs$CBPSEG %in% segment, ]
    set.seed(grid_seed)
    pts <- grid_est(seg_shp, spacing = grid_spc)
    sgpts_sel <- sgpts[sgpts$CBPSEG %in% segment, ]
      
#     browser() # for debugging
   
    # point from random points for buffer
    test_pt <- pts[test_point, ]

    # get bathym points around test_pt
    # added try exception for reservecontrols
    buff_pts <- try({
      buff_ext(sgpts_sel, test_pt, buff = radius)
    }, silent = T)
    if('try-error' %in% class(buff_pts)) return()
    
    p1 <- ggplot(seg_leg, aes(long, lat)) + 
      geom_polygon(fill = 'lightblue', aes(group = piece)) +
      theme_classic() +
      coord_equal() +
  		xlab('Longitude') +
  		ylab('Latitude') +
      geom_point(
        data = data.frame(buff_pts),
        aes(coords.x1, coords.x2), 
        colour = 'red', 
        size = 0.3, 
        alpha = 0.7
      ) + 
      theme(text = element_text(size=20))
    
    # plot points wiht point labels if true
    if(point_lab) {
      pts <- data.frame(pts, labs = row.names(pts))
      p1 <- p1 + geom_text(
        data = pts,
        aes(Var1, Var2, label = labs),
        size = 3
      )
    } else { 
      p1 <- p1 + geom_point(
        data = data.frame(pts), 
        aes(Var1, Var2), 
        size = 3,
        pch = 1
      )}
    
  	##
   	# get data used to estimate depth of col for plotting
		est_pts <- data.frame(buff_pts)
    
#     browser() 
    
		# data
		dat <- doc_est(est_pts)
		to_plo <- dat$data
    
    # base plot if no estimate is available
    p2 <- ggplot(to_plo, aes(x = Depth, y = sg_prp)) +
      geom_point(pch = 16, size = 4, colour = 'black', alpha = 0.5) +
      theme(text = element_text(size=20)) +
      ylab('Proportion of points with seagrass') +
      xlab('Depth (m)')

    # get y value from est_fun for sg_max and doc_med
    yends <- try({
      with(dat, est_fun(c(sg_max, doc_med)))
      })
    
    # add to baseplot if estimate is available
    if(!'try-error' %in% class(yends)){
    
      ##
			# simple plot of points by depth, all pts and those with seagrass
      to_plo2 <- dat$preds
      to_plo3 <- dat$est_fun
      to_plo4 <- data.frame(
        Depth = with(dat, c(sg_max, doc_med, doc_max)), 
        yvals = rep(0, 3)
      )
      
      # some formatting crap
      x_lims <- max(1.1 * max(na.omit(to_plo)$Depth), 1.1 * dat$doc)
      pt_cols <- brewer.pal(nrow(to_plo4), 'Blues')
      leg_lab <- paste0(
        c('SG max (', 'DOC med (', 'DOC max ('),
        round(to_plo4$Depth, 2), 
        rep(')', 3)
      )
    
      # the plot
      p2 <- p2 +
        geom_line(data = to_plo2, 
          aes(x = Depth, y = sg_prp)
          ) +
        scale_y_continuous(limits = c(0, 1.1 * max(to_plo2$sg_prp))) + 
        scale_x_continuous(limits = c(min(to_plo$Depth), 1.1 * x_lims)) + 
        stat_function(fun = to_plo3, colour = 'lightgreen', size = 1.5, 
          alpha = 0.6) +
        geom_segment(x = dat$sg_max, y = 0, xend = dat$sg_max, 
          yend = yends[1], linetype = 'dashed', colour = 'lightgreen',
          size = 1.5, alpha = 0.6) +
        geom_segment(x = dat$doc_med, y = 0, xend = dat$doc_med, 
          yend = yends[2], linetype = 'dashed', colour = 'lightgreen',
          size = 1.5, alpha = 0.6) +
        geom_point(data = to_plo4, 
          aes(x = Depth, y = yvals, fill = factor(Depth)), 
          size = 6, pch = 21) +
        scale_fill_brewer('Depth estimate (m)', 
          labels = leg_lab,
          palette = 'Blues'
          ) +
        theme(legend.position = c(1, 1),
          legend.justification = c(1, 1)) 
      
    }
    
#       browser()
    
    p3 <- ggplot(bounds, aes(long, lat)) + 
      geom_polygon(fill = 'grey', aes(group = piece)) +
      theme_classic() +
        coord_equal() +
        xlab('Longitude') +
    		ylab('Latitude') +
      geom_polygon(
        data = seg_leg,
        aes(long, lat, group = piece), 
        fill = 'lightblue'
      ) +
    theme(text = element_text(size=20))
  
    # arrange as grobs
		grid.arrange(
      arrangeGrob(p3, p1, ncol = 2), 
			arrangeGrob(p2, ncol = 1), 
			ncol = 1, heights = c(1.5, 1.5)
		)    
    
    },height = 900, width = 900)

    })