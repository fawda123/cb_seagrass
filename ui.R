library(shiny)

# Define UI for application
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Chesapeake Bay 2012 seagrass depth limits"),
  
  # Sidebar with a slider input for number of observations
  sidebarPanel(
    
    selectInput(inputId = 'seg',
                label = h3('Pick segment'),
                choices = c("BIGMH", "BOHOH", "BSHOH", "CB1TF", "CB2OH", "CB3MH", "CB5MH", "CB6PH", "CB7PH", "CB8PH", "CHKOH", "CHOMH1", "CHOMH2", "CHSMH","CRRMH", "EASMH", "ELKOH", "FSBMH", "GUNOH", "HNGMH", "JMSOH", "JMSPH", "JMSTF", "LCHMH", "MANMH", "MATTF", "MIDOH", "MOBPH", "MPNTF", "NORTF", "PAXMH", "PAXOH", "PAXTF", "PIAMH", "PISTF", "PMKTF", "POCMH", "POTMH", "POTOH", "POTTF", "RPPMH", "RPPOH", "RPPTF", "SASOH", "SEVMH", "SOUMH", "TANMH", "WBRTF", "YRKPH"), 
                selected = 'POCMH'),
      
    uiOutput("pts"), 
    
    numericInput("grid_spc", 
                 label = h3("Grid spacing (dec. deg.)"), 
                 min=0.005, 
                 max=0.1, 
                 value=0.01, step = 0.001),

    checkboxInput("point_lab", 
                  label = "Label points as numbers",
                  value = F),
    
    numericInput("radius", 
                 label = h3('Radius (dec. deg.)'), 
                 min=0, 
                 max=2, 
                 value=0.06, step = 0.01),
    
    numericInput("grid_seed", 
             label = h3("Grid seed"), 
             min=1, 
             max=5000, 
             value=1234, step = 1),

    submitButton("Submit"), 
    
    width = 3
    
  ),
  
  # output tabs
  mainPanel(
    tabsetPanel(
      tabPanel("Segment identification", plotOutput("segplot", height = "110%")),
      tabPanel("Depth estimates", plotOutput("simplot", height = "110%"))
#       tabPanel("Summary tables", h3('Summary of metabolism estimates'), tableOutput("tablemet"), h3('Correlations with tidal change'), tableOutput('tablecorr'))
      ), width = 9
    )
  
))