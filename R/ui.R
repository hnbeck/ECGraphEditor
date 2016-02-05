###########################################################################################
#
# Server.R
#
# UI component for loading graphs from Neo4j via RNeo4j, modify and store back
#
# (c) and author: Hans N. Beck
# version: 0.1
#
###########################################################################################

require(shinydashboard)
require(visNetwork)

constMetaLabel <<- "Label"
constMetaProperty <<- "Properties"
constMetaAspect <<- "Aspects"

dashboardPage(
  dashboardHeader(title = "EC Graph Editor"),
  dashboardSidebar(
    selectizeInput("selectEdgeTypes", "Select edge types from DB",
                            choices = NULL, multiple = TRUE),
    selectizeInput("newRelation", "Relationship for new edges",
             choices = list("newRelation", selected = "newRelation"),multiple = FALSE, options = list(create = TRUE)),
    checkboxInput("improvedLayout", "Use improved layout", value=FALSE),
    checkboxInput("lonlyNodes", "Show unconnected nodes", value=TRUE),
    sliderInput("nodeSize", "Node scale factor:", min=2, max = 15, value = 10, step = 1),
    sliderInput("edgeLength", "Edge length factor:", min=2, max = 15, value = 6, step = 1),
    sliderInput("repeatCount", "Node multiply factor:", min=1, max = 10, value = 1, step = 1)
  ),
  
  dashboardBody(
    fluidRow(
      tabBox(width=12, 
               tabPanel(title = "Graph",  status="primary",  width = "100%", 
                   tags$div(class="netOutput", id="std", visNetworkOutput("network", height=600)),
                   tags$div(class="buttons", 
                            actionButton("loadButton", "Load graph"),
                            actionButton("updateButton", "Save graph")), 
                   tags$style(type='text/css','.buttons {margin: 10pt; align:center;}')
            
               ),
        
              tabPanel(title= "Meta graph",  status="primary",  width= "100%", 
                    tags$div(class="netOutput", id="meta", visNetworkOutput("metaNet", height=600)),
                    tags$table(class="metaButtons", width=400,
                               tags$tr(
                                 tags$td(id="button1", actionButton("metaLoadButton", "Load meta graph") ),
                                 tags$td(id="button2", selectizeInput("metaNodeTypes", NULL,
                                                         choices = list(Labels=constMetaLabel, Properties= constMetaProperty), selected = constMetaProperty,
                                                         multiple = FALSE, options = list(create = FALSE)), width="50%")
                               )
                     
                      ),
                    tags$style(type='text/css','.metaButtons { margin: 0pt; align:center; width=100%; border:0px;}'),
                    tags$style(type='text/css','#button1 { border:0px; vertical-align:center;}'),
                    tags$style(type='text/css','#button2 {  border:0px;padding-top: 11pt; padding-left:2pt; vertical-align:center;}')
                 )
          )
      ),
      fluidRow(
              box(width = NULL, 
                  verbatimTextOutput("warnings"),
                  tags$style(type='text/css','#warnings {color: red; font-size: 10pt; font-weight: bold;}')
              )
          ),
      tags$style(type='text/css','.netOutput {max-height:600px;}'),
      # this is a hack, there should be a better way over options in visNetwork in future
      tags$style(type='text/css','#node-label {background-color:light-grey; width:300px }'),
      tags$style(type='text/css','#node-id {background-color:light-grey; width:300px }'),
      tags$style(type='text/css','#network-popUp { margin:20px; width:400px;}')
      )
  )


