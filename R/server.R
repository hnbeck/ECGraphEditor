###########################################################################################
#
# server.R
#
# Server component for getting graphs from Neo4j via RNeo4j, modify and store back
# please read metaGraph.R comment for understanding graphs and meta graphs
#
# (c) and author: Hans N. Beck
# version: 0.1
#
###########################################################################################

require(visNetwork)
require (stringr)
require(uuid)
require(jsonlite)
source("basis.R")
source("graphIO.R")
source ("metaGRaph.R")


# a data frame (interpreted as list) of graph change commands
commandList <<- NULL

# that are the aspects which can be visualized by visNetwork or vis.js, respectivly
# they are used as id of the meta graph nodes
vizAspects <<- list(label="vizLabel", title="vizTitle", value="vizValue")
# thats the possible nodes of the meta graph

constMetaLabel <<- "Label"
constMetaProperty <<- "Properties"
constMetaAspect <<- "Aspects"

# general remark: vis.js handle ids and labels
# the label will be mapped to one (selected) node property
# NOTE: on vis.js level, a node has a type, a label and ID
# this type is called "label" at neo4j level
# a neo4j node of a selected label as properties
propDesc <<- c(key=NA) # property description
listOfMetaNodes <<-list()
listOfMetaEdges <<-list()


shinyServer(function(input, output, session) {

  # init nodes data frame
  metaNodes <<- NULL
  # init edges date frame
  # thats for visNetwork don't throw an errow with empty data
  metaEdges <<- data.frame(id = "", from = "", to = "")
  lcc <- reactiveValues( invalidate = 0 , metaInvalidate = 0, msg = "")
  
  # load a graph from neo4j
  updateGraphData <- eventReactive(input$loadButton, {
    
    lcc$msg <- "Load Graph..."
    edgeTypesFilter <- input$selectEdgeTypes
    focusNode <- NULL
    
    if (!is.null(input$network_selected) && input$network_selected != "")
    {
      focusNode <- list(input$network_selected, myNodes$group[myNodes$id == input$network_selected])
    }
    
    data <- loadGraph(graph, metaNodes, metaEdges, edgeTypesFilter, focusNode, input$lonlyNodes)
    
    myNodes <<- data$n
    myEdges <<- data$e
    lcc$invalidate <<-lcc$invalidate +1
    lcc$msg <- "Graph loaded"
  
  })

  # apply all change commands (add, delete etc.) to neo4j
  observeEvent(input$updateButton, {

      if (!is.null(commandList))
      {
        # handle nodes first  because neo4j provides new IDs
        # this IDs are different from the one provided by vis.js
        # sort for priority
        commandList <<- commandList[order(commandList$prio),]
        # print (sortedCommands)
        # now I can do all other commands, IDs in commandlist and graph are now corrected
        for (i in  1:nrow(commandList))
        {
          c <- commandList[i,]

          if (c$cmd == "addNode")
          {
            data <- addNode(graph, c, myNodes, myEdges)
            myNodes <<- data$nodes
            myEdges <<-data$edges
          }
          if (c$cmd == "editNode")
          {
            data <- updateNode(graph, c, myNodes, myEdges, metaNodes, metaEdges)
            myNodes <<- data$nodes
            myEdges <<-data$edges
          }
          if (c$cmd == "addEdge")
          {
            data <- addEdge(graph, c, myNodes, myEdges)
            myNodes <<- data$nodes
            myEdges <<-data$edges
          }
          if (c$cmd == "deleteEdge")
          {
            data <- deleteEdge(graph, c, myNodes, myEdges)
            myNodes <<- data$nodes
            myEdges <<-data$edges
          }
          if (c$cmd == "deleteNode")
          {
            data <- deleteNode(graph, c, myNodes, myEdges)
            myNodes <<- data$nodes
            myEdges <<-data$edges
          }
        }

        lcc$msg <- "Graph saved"
        lcc$invalidate <- lcc$invalidate + 1
        commandList <<- NULL
      }
  })
  
  updateMetaGraphData <- eventReactive(input$metaLoadButton, {
    
      selectedE <- input$selectEdgeTypes
      selectedNewRelation <- input$newRelation
      # propMap <- input$labelPropertyMap
      data <- loadMetaGraph(graph)
      nodeDesc <- data$nDesc
      edgeDesc <- data$eDesc
      propDesc <<- data$pDesc
      
      data <- buildMetaGraph(nodeDesc, edgeDesc, propDesc)
      metaNodes <<- data$metaNodes
      metaEdges <<-  data$metaEdges
      
      print("Graph meta data loaded")
      updateSelectizeInput(session, "selectEdgeTypes", choices = edgeDesc, selected = selectedE)
      updateSelectizeInput(session, "newRelation", choices = edgeDesc, selected = selectedNewRelation)
      
      lcc$metaInvalidate <- 0
  })
  
  observeEvent(input$metaGraphList,{
    # store metagraph is list
    if (!is.null(input$metaGraphList) && (input$metaGraphList != ""))
    {
      print (names(listOfMetaNodes))
      if (input$metaGraphList %in% names(listOfMetaNodes))
      {
        print ("restore")
        print (listOfMetaNodes[input$metaGraphList])
        #known entry: restore
        metaNodes <<- fromJSON(listOfMetaNodes[[input$metaGraphList]])
        metaEdges <<- fromJSON(listOfMetaEdges[[input$metaGraphList]])
        lcc$metaInvalidate <- lcc$metaInvalidate + 1
      }
      else
      {
        # new entry: save
        listOfMetaNodes[input$metaGraphList] <<- toJSON(metaNodes)
        listOfMetaEdges[input$metaGraphList] <<- toJSON(metaEdges)
      }
      
    }
    
    print (input$metaGraphList)
  })
  
  # node type filter
  observeEvent(input$selectEdgeTypes, {
    edgeTypesFilter = input$selectEdgeTypes
    
    # it may be a single string, but a list is needed in any case
    if (!is.vector(edgeTypesFilter))
      edgeTypesFilter <- c(edgeTypesFilter)
    
    # set choices
    updateSelectInput(session, "newRelation", selected = edgeTypesFilter[1])
  
  })

  # handle change events of vis.js layer
  # every change will be stored as command in a data frame
  observeEvent(input$network_graphChange,{
    if (!is.null(input$network_graphChange))
    {
      if (input$network_graphChange$cmd =="addNode")
      {
          # metaNet_selected my be Null or "" -> nothing in meta graph selected
          tryCatch({
            
            selId <- input$network_graphChange$id
            selLabel <- input$network_graphChange$label
            aCmd <- input$network_graphChange
           
            if ((metaNodes$group[metaNodes$id == input$metaNet_selected]) == constMetaLabel)
            {
             
              aCmd$type <- metaNodes$label[metaNodes$id == input$metaNet_selected]
              aCmd$map <- findMappedProperty(metaNodes, metaEdges, aCmd$type, vizAspects$label)
              aGroup <- metaNodes$group[metaNodes$id == input$metaNet_selected]
             
              # repeat n times
              for (i  in 1:input$repeatCount)
              {
                # adjust command data if more than one note
                if (i > 1)
                {
                  aCmd$label <- paste(selLabel,i)
                  aCmd$id <- UUIDgenerate()
                }
                 
                newNode <- data.frame(id = aCmd$id, label = aCmd$label , title = "", group = aCmd$type, value = 1, orgValue = 1)
                myNodes <<- rbind(myNodes,newNode)
                aCmd$cmd <- "addNode"
                commandList <<-  appendCommand (commandList, aCmd)   
              }
              #g <- visNetworkProxy("network")
              #visSetData(g, myNodes, myEdges)
              lcc$msg <- "Save graph to reflect changes !"
              lcc$invalidate <- lcc$invalidate + 1
            }
          },
          error = function(e) {
            lcc$msg <- "Denied: Ensure that a meta node of type 'Labels' is selected"
            lcc$invalidate <- lcc$invalidate + 1
            print (e)
            
          })
        }
      
      if (input$network_graphChange$cmd =="editNode")
      {
        selId <- input$network_graphChange$id
        selLabel <- input$network_graphChange$label
        aCmd <- input$network_graphChange
        # print("changed node")
        aCmd$map <- ""
        aCmd$type <- ""
        myNodes$label[myNodes$id==selId] <<- selLabel
        commandList <<-  appendCommand (commandList, aCmd)
        #lcc$invalidate <- lcc$invalidate + 1
        lcc$msg <- "Save graph to reflect changes !"
      }

      if (input$network_graphChange$cmd == "addEdge")
      {
        print("Command add edge")
        selId <- input$network_graphChange$id
        selFrom <- input$network_graphChange$from
        selTo <- input$network_graphChange$to
        # create command
        aCmd <- input$network_graphChange
        aCmd$map <- NULL
        aCmd$type <- input$newRelation

        newEdge <- data.frame(id = selId, from= selFrom, to=selTo, label=aCmd$type)
        myEdges <<- rbind(myEdges,newEdge)
        # if redraw/reload necessary uncomment this
        # lcc$invalidate <- lcc$invalidate+1
        commandList <<- appendCommand(commandList, aCmd)
        lcc$msg <- "Save graph to reflect changes !"
      }
      if (input$network_graphChange$cmd == "deleteElements")
      {
        print("Command delete edge")
        # delete edges
        for (e in input$network_graphChange$edges)
        {
          if (e %in% myEdges$id)
          {
            aCmd <- list(cmd="deleteEdge", id=e)
            print (paste("To delete edge:", e))
            myEdges <<- myEdges[!myEdges$id == e,]
            # deletedEdges <<- c(deletedEdges, e)
            commandList <<- appendCommand(commandList, aCmd)
          }
        }

        # delete nodes
        for (n in input$network_graphChange$nodes)
        {
          if (n %in% myNodes$id)
          {
            aCmd <- list(cmd="deleteNode", id=n)
            print (paste("To delete node:", n))
            myNodes <<- myNodes[!myNodes$id == n,]
            #print (paste("deletedNodes is now ", deletedNodes))
            commandList <<- appendCommand(commandList, aCmd)
          }
        }
        lcc$msg <- "Save graph to reflect changes !"
      }
    }
  })
    
  # handle change events of vis.js layer for the meta graph
  observeEvent(input$metaNet_graphChange,{
    
    lcc$msg <- ""
    if (!is.null(input$metaNet_graphChange))
    {
      if (input$metaNet_graphChange$cmd =="addNode")
      {
        selId <- input$metaNet_graphChange$label
        selLabel <- input$metaNet_graphChange$label
        # the only nodes which can be added in the meta graph are property nodes
        newNode <- data.frame(id = selId, label = selLabel, group = input$metaNodeTypes)
        metaNodes <<- rbind(metaNodes,newNode)
        lcc$metaInvalidate <- lcc$metaInvalidate + 1
      }
      
      if (input$metaNet_graphChange$cmd =="editNode")
      {
        lcc$metaInvalidate <- lcc$metaInvalidate + 1
        lcc$msg <- "MetaNodes can not be edited"
      }
      
      if (input$metaNet_graphChange$cmd == "addEdge")
      {
        print("Command add edge")
        selId <- input$metaNet_graphChange$id
        selFrom <- input$metaNet_graphChange$from
        selTo <- input$metaNet_graphChange$to
      
        newEdge <- data.frame(id = selId, from= selFrom, to=selTo)
        metaEdges <<- rbind(metaEdges,newEdge)
        lcc$metaInvalidate <- lcc$metaInvalidate + 1
      }
      if (input$metaNet_graphChange$cmd == "deleteElements")
      {
        print("Command delete edge")
        
        for (e in input$metaNet_graphChange$edges)
        {
          if (e %in% metaEdges$id)
          {
            print (paste("To delete edge:", e))
            metaEdges <<- metaEdges[!metaEdges$id == e,]
          }
        }
    
        # delete nodes
        for (n in input$metaNet_graphChange$nodes)
        {
          if (n %in% metaNodes$id)
          {
            print (paste("To delete node:", n))
            metaNodes <<- metaNodes[!metaNodes$id == n,]
            
          }
        }
        
        lcc$metaInvalidate <- lcc$metaInvalidate + 1
      }
    }
  })

  
  output$network <- renderVisNetwork({

    updateGraphData()

    lcc$invalidate #for reactiveness, this invalidate will be incremented every time a redraw is necessary

    # apply scale facor from the slider to the value field
    # the value field will not be written back to data base 
    myNodes$value <- lapply(myNodes$orgValue, function(x) {if (is.numeric(x) && !is.na(x)) x*input$nodeSize else as.numeric(input$nodeSize)})
   
    visNetwork(myNodes, myEdges) %>%
      visIgraphLayout(layout="layout_as_tree")%>%
      visEdges(arrow="to") %>%
      visPhysics(stabilization = FALSE) %>%
      visInteraction(navigationButtons = TRUE) %>%
      visOptions(manipulation = TRUE,
                  nodesIdSelection = TRUE) %>%
      visLayout(improvedLayout = input$improvedLayout, randomSeed = 120) %>%
      visLegend(position="left")
     
  })
  
  output$metaNet <- renderVisNetwork({
      
      updateMetaGraphData()
    
      #for reactiveness
      lcc$metaInvalidate
      lcc$msg<-"Meta graph changed, reload of graph required"
      visNetwork(metaNodes, metaEdges) %>%
       
        visEdges(arrow="to") %>%
        visPhysics(stabilization = FALSE) %>%
        visInteraction(navigationButtons = TRUE) %>%
        visOptions(manipulation = TRUE,
                   nodesIdSelection = TRUE) %>%
        visLayout(improvedLayout = input$improvedLayout, randomSeed = 20) %>%
        visLegend(position="left") %>%
        visNodes (size=10)%>%
        visEdges (length=input$edgeLength)
    
  })
  
  
  output$warnings <- renderText({
    lcc$msg})

})
