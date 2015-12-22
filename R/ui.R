###########################################################################################
#
# Server.R
#
# UI component for getting graphs from Neo4j via RNeo4j, modify and store back
#
# (c) and author: Hans N. Beck
# version: 0.1
#
###########################################################################################

library(shinydashboard)
require(visNetwork)


dashboardPage(
  dashboardHeader(title = "EC Graph Editor"),
  dashboardSidebar(
    selectizeInput("selectEdgeTypes", "Select edge types from DB",
                            choices = NULL, multiple = TRUE),
    selectizeInput("newRelation", "Relationship for new edges",
             choices = list("newRelation", selected = "newRelation"),multiple = FALSE, options = list(create = TRUE)),
    checkboxInput("improvedLayout", "Use improved layout", value=FALSE),
    sliderInput("nodeSize", "Node scale factor:", min=2, max = 20, value = 10, step = 1),
    sliderInput("edgeLength", "Edge length factor:", min=2, max = 20, value = 6, step = 1)
  ),
  
  dashboardBody(
    fluidRow(
      column(width = 7,
             box(width = NULL, 
                 #tabPanel("Graph",
                 tags$div(class="netOutput", id="std",
                   visNetworkOutput("network", height=700)
                   ),
                 tags$div(class="buttons", 
                          actionButton("loadButton", "Load graph"),
                          actionButton("updateButton", "Save graph")), 
                 tags$style(type='text/css','.buttons {margin: 10pt; align:center;}')
             )
             
      ),
      
      column(width = 5,
        box(width= NULL, 
          #tabPanel("Meta Graph",
              tags$div(class="netOutput", id="meta",
              visNetworkOutput("metaNet", height=600)
              ),
              actionButton("metaLoadButton", "Load meta graph")
              )
          )
      ),
      fluidRow(
              box(width = NULL, 
                  verbatimTextOutput("warnings"),
                  tags$style(type='text/css','#warnings {color: red; font-size: 12pt; font-weight: bold;}')
              )
          ),
      tags$style(type='text/css','.netOutput {max-height:600px;}')
          
      )
  )


