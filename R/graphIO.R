###########################################################################################
#
# graphIO.R
#
# IO component for getting graphs from Neo4j via RNeo4j, modify and store back
#
# (c) and author: Hans N. Beck
# version: 0.1
#
###########################################################################################

# note: at this level, we talk about node labels and node properties
# this are terms on neo4j level
require(igraph)

# connection to neo4j database
graph = startGraph("http://localhost:7474/db/data")

loadGraph <- function (graph, mNodes, mEdges,edgeTypesFilter, filterID = NULL)
{
  nodes <- NULL
  propertyList <- list()
  print("Load graph")
 
  # for all required node labels
  for (nl in mNodes$label[mNodes$group == "nodeType"])
  {
      for (vA in vizAspects)
        propertyList[vA] <- findMappedProperty(mNodes, mEdges, nl, vA)
    
      queryDataNodes <- buildNodeQuery(c(nl), propertyList, filterID)
      nodesSet <- cypher(graph, queryDataNodes$nQuery)
      
      if (!is.null(nodesSet))
      {
        if (!is.null(nodes))
          nodes <- merge(x=nodes, y =nodesSet, all=TRUE)
        else
          nodes <- nodesSet
      }
  }

  
  # if no value column generate one with default 1, important for node size scaling
  if (! "value" %in% names(nodes))
    nodes$value <- 1.0
  
  # copy the column value
  nodes$orgValue = as.numeric(nodes$value)
  
  queryDataEdges <-buildEdgeQuery(edgeTypesFilter, mNodes$label)
  edges <- cypher(graph, queryDataEdges$eQuery)

  #print(nodes)

  # uncomment this for removing nodes without edges
  # nodeKeys = data.frame(id=unique(c(edges$from, edges$to)))
  # nodes <- nodes[nodes$id %in% nodeKeys$id,]
  # remove edges without nodes
  edges <- edges[edges$from %in% nodes$id,]
  edges <- edges[edges$to %in% nodes$id,]
 
  return (list( n = nodes, e = edges, numNodes = nrow(nodes), numEdges = nrow(edges)))
}


# add a node to neo4j
addNode <- function(graph, aCommand, nodes, edges, lcc)
{
  print("add node to db")
  aNodeID <- aCommand$id
  aNodeContent <- aCommand$label
  aProperty <- aCommand$map
  aNewNodeLabel <- aCommand$type

  aQuery = paste0("match (n) where id(n)=", -1, " return labels(n) as labels")

   # bestimme node type und ob der Knoten überhaupt existiert
  result <- cypher(graph, aQuery)

  # perform only if node doesn't exists already
  if (length(result) == 0)
  {
    # erzeuge knoten
    query = paste0("create (n:", aNewNodeLabel ,"{", aProperty, ": '", aNodeContent, "'}) return id(n) as id")
    print(query)
    result <- cypher(graph, query)
    # print (paste("reuslt ", result))
    
    # correct the id because neo4j has its own ids
    nodes$id[nodes$id==aNodeID] <- result$id
    # correct edges ids
    edges$from[edges$from==aNodeID] <- result$id
    edges$to[edges$to==aNodeID] <- result$id
    # perform id correction in all edge related commands
    # because this commands include the ids of vis.js at this time
    commandList$from[commandList$from == aNodeID] <<- result$id
    commandList$to[commandList$to== aNodeID] <<- result$id
  }

  return (list("nodes" = nodes, "edges"= edges))
}

# updates node data in database
updateNode <- function(graph, aCommand, nodes, edges, mNodes, mEdges)
{
  print("update node in db")
  aNodeID <- aCommand$id
  aNodeContent <- aCommand$label

  aQuery = paste0("match (n) where id(n)=", aNodeID, " return labels(n) as labels")
  # determine node label of selected node

  result <- cypher(graph, aQuery)
  targetLabel = result$labels[1] # assumption: only one label per node
  # only vizLabel can be changed by user in GUI
  aProperty <- findMappedProperty(mNodes, mEdges, targetLabel, "vizLabel")
  if (!aProperty=="NA")
  {
    query = paste0("match (n) where id(n)=", aNodeID, " set n.",aProperty, "='", aNodeContent, "'")
    # print (paste ("update query", query))
    
    # perform update
    result <- cypher(graph, query)
  }
 
  return (list("nodes" = nodes, "edges"= edges))
}

#add edge
addEdge <- function(graph, aCommand, nodes, edges)
{
  print("add new edge in db")
  aFromID <- aCommand$from
  aToID <- aCommand$to
  aType <- aCommand$type
  aID <- aCommand$id

  # check if edge exists already
  aQuery = paste0("match (n)-[r:", aType, "]-(m) where id(n)=", aFromID, " and id(m) = ", aToID, " return id(r) as id")
  #print(aQuery)
  result <- cypher(graph, aQuery)
  if (length(result) == 0)
  {
    aQuery = paste0("match (n), (m) where id(n)=", aFromID, " and id(m) = ", aToID, " CREATE (n)-[r:", aType, "]->(m) return id(r) as id")
    # print(aQuery)
    result <- cypher(graph, aQuery)
    # print(result)

    #correct ids, because database provides new ones
    edges$id[edges$id==aID] <- result$id
  }

  return (list("nodes" = nodes, "edges"= edges))
}

#add edge
deleteEdge <- function(graph, aCommand, nodes, edges)
{
  print("delete edge in db")
  aID <- aCommand$id

  # for neo4j no problem if egde doesn't exist
  aQuery = paste0("match (n)-[r]-(m) where id(r)=", aID, " delete r")
  # print(aQuery)
  result <- cypher(graph, aQuery)
  # print(result)

  return (list("nodes" = nodes, "edges"= edges))
}

#add edge
deleteNode <- function(graph, aCommand, nodes, edges)
{
  print("delete node in db")
  aID <- aCommand$id

  # for neo4j no problem if egde doesn't exist
  aQuery = paste0("match (n) where id(n)=", aID, " delete n")
  # print(aQuery)
  try({result <- cypher(graph, aQuery)})
  # print(result)

  return (list("nodes" = nodes, "edges"= edges))
}


# create cyhper query for reading nodes
buildNodeQuery <- function(nodeLabel="", aPropList, focusNode = NULL)
{
  nodeExpr = "match (n)"
  clauseExpr = buildNodeLabelExpr(nodeLabel)
  
  if (!is.null(focusNode) && nodeLabel == focusNode[2])
  {
    clauseExpr <- paste("where id(n)=", focusNode[1], " ")
  }
  query = paste(nodeExpr, clauseExpr ," return id(n) as id, labels(n) as group" )
  
  if (!aPropList["vizLabel"]=="NA")
      query = paste0(query, ", n.", aPropList["vizLabel"], " as label")
  
  if (!aPropList["vizTitle"]=="NA")
      query = paste0(query, ", n.", aPropList["vizTitle"], " as title")
  
  if (!aPropList["vizValue"]=="NA")
    query = paste0(query, ", n.", aPropList["vizValue"], " as value")

  print (paste("nodequery", query))

  return (list("nQuery"= query, "clauseExpr" = clauseExpr))
}

# create cypher edge query for reading
buildEdgeQuery <- function(edgeTypes, nodeLabels="")
{
  edgeExpr = "match (n)-[r?]->(m) "
  # taking selected node labels into account
  clauseExpr = buildNodeLabelExpr(nodeLabels)
  subExpr = buildRelationExpr(edgeTypes)
  edgeExpr = gsub("?", subExpr, edgeExpr, fixed=TRUE)
  query = paste(edgeExpr, clauseExpr,  "return id(r) as id, id(n) as from, id(m) as to, type(r) as label")
 
  print (paste("edge", query))

  return (list("eQuery"= query, "edgeExpr" = subExpr))
}

createIGraph <- function(nodes, edges)
{
   e  <- edges[,!colnames(edges) == "id"]
  aGraph <- graph_from_data_frame(e, TRUE, nodes)
  return (aGraph)
}
