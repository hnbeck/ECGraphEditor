###########################################################################################
#
# Sertver.R
#
# UI component for getting graphs from Neo4j via RNeo4j, modify and store back
#
# (c) and author: Hans N. Beck
# version: 0.1
#
###########################################################################################

require(shiny)
require(visNetwork)

shinyUI(fluidPage(

     titlePanel("EC Graph Editor"),

     sidebarLayout(
       sidebarPanel(
         selectizeInput("selectEdgeTypes", "Select edge types from DB",
                        choices = NULL, multiple = TRUE),
         selectizeInput("newRelation", "Relationship applied for new edges",
                        choices = list("newRelation", selected = "newRelation"),multiple = FALSE, options = list(create = TRUE)),
         verbatimTextOutput("modSteps"),
         checkboxInput("improvedLayout", "Use improved layout", value=FALSE),
         actionButton("loadButton", "Load graph"),
         actionButton("updateButton", "Save graph"),
         actionButton("metaLoadButton", "Load meta graph"),
         sliderInput("nodeSize", "Node size:", min=5, max = 30, value = 15, step = 1), width = 3
       ),
       mainPanel(
         tags$style(type='text/css','#warnings {color: red; font-size: 14pt;}'),
         verbatimTextOutput("warnings"),
         tabsetPanel(
           tabPanel("Graph", visNetworkOutput("network", width = "100%", height="100%")),
           tabPanel("Meta Graph", visNetworkOutput("metaNet", width="100%", height="100%")
           )          
         )
       )
     )
) )
