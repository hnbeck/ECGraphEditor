###########################################################################################
#
# Sertver.R
#
# UI component for getting graphs from Neo4j via RNeo4j, modify and store back
#
# author: Hans N. Beck
# version: alpha
#
###########################################################################################

require(shiny)
require(visNetwork)

shinyUI(fluidPage(

     titlePanel("EC Graph Editor"),

     sidebarLayout(
       sidebarPanel(
         selectizeInput("selectNodeTypes", "Select node types from DB",
         choices = list("Label", "Title", selected = "Label"), multiple = TRUE),
         selectizeInput("selectEdgeTypes", "Select edge types from DB",
                        choices = NULL, multiple = TRUE),
         selectizeInput("labelPropertyMap", "Mapping node properties to label",
                        choices = list("", selected = "name"),multiple = TRUE,options = list(create = TRUE)),
         selectizeInput("newType", "Node type (=label in Neo4j) applied for new nodes",
                        choices = list("newLabel", selected = "newLabel"),multiple = FALSE, options = list(create = TRUE)),
         selectizeInput("newRelation", "Relationship applied for new edges",
                        choices = list("newRelation", selected = "newRelation"),multiple = FALSE, options = list(create = TRUE)),
         h5("Current label property mapping"),
         verbatimTextOutput("labelMapping"),
         verbatimTextOutput("modSteps"),
         checkboxInput("improvedLayout", "Use improved layout", value=FALSE),
         actionButton("loadButton", "Load graph"),
         actionButton("updateButton", "Save graph"), width="3"
       ),
       mainPanel(
         visNetworkOutput("network", width = "100%", height="100%")
       )
     )
) )
