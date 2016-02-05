###########################################################################################
#
# metaGraph.R
#
# functions for managing meta graph
#
# visNetwork and the underlying vis.js render "label" as the one value for nodes and
# "title" for the popup at a node. "value" can be used for sizing nodes at rendering
# Neo4j can handle any number of properties, so a mapping must be definded
# the meta graph visualizes this mapping of neo4j properties to "label", "title" and "value"
#
# the meta graph is defined as
# from node group "vizAspect" to group "property", from "property" to group "label" 
# (visAspect)-->(property)-->(label)
#
# (c) and author: Hans N. Beck
# version: 0.1
#
###########################################################################################

# load meta data (labels in database, properties of node with selected label)
loadMetaGraph <- function(graph)
{
  nQuery = "match (n) return distinct labels(n) as labels"
  eQuery = "match (n)-[r]->(m) return distinct type(r) as types"
  propQuery = "match (n:?) return distinct keys(n) as keys"
 
  result <- cypher(graph, nQuery)
  nodeDesc <- result$labels
  result <- cypher(graph, eQuery)
  edgeDesc <-  result$types
  propDesc <- data.frame()

  # for every node label
  if (length(unlist(nodeDesc)>0))
  {
    propDesc <- vector(length = length(nodeDesc))
    names(propDesc) <- nodeDesc
    for (l in nodeDesc)
    {
      aQuery <-gsub("?", l, propQuery, fixed = TRUE)
      result <- cypher(graph, aQuery)
      for (e in unique(unlist(result$keys)) )
      {
        newRow <- data.frame(label = l, key = e)
        propDesc <- rbind(propDesc, newRow)
      }
    }
  }
  else
  {
    aQuery = "match (n) return distinct keys(n) as keys"
    result <- cypher(graph, aQuery)
    for (e in unlist(result$keys) )
    {
      newRow <- data.frame(label = "default", key = e)
      propDesc <- rbind(propDesc, newRow)
    }
    nodeDesc <- c("default")
  }
  
  return (list(nDesc = nodeDesc, eDesc =edgeDesc, pDesc = propDesc))
}


buildMetaGraph <- function (nodeDesc, edgeDesc, propDesc)
{
  metaEdges <- data.frame(id = "", from = "", to = "")
  
  # build the basic meta nodes
  metaNodes <- data.frame(id = toVector(vizAspects), label = c("Label", "Title",  "Value"), group = constMetaAspect)
  # take meta nodes: every existing label becomes a node in meta graph
  newFrame <- data.frame(id = nodeDesc, label = nodeDesc, group = constMetaLabel)
  metaNodes <- rbind(metaNodes, newFrame)
 
  # every existing property becomes a node in meta graph
  if (!is.na(propDesc["key"]) && length(unlist(propDesc$key))>0)
  {
    newFrame <- data.frame(id = unique(propDesc$key), label = unique(propDesc$key), group = constMetaProperty)
    metaNodes <- rbind(metaNodes, newFrame)
    idCount= 1;
    # now build edges: which properties exist in what node (selected by their label)
    for (k in unique(propDesc$key))
    {
      toID = propDesc$label[propDesc$key==k]
      fromID = k
      a = idCount
      b = idCount + length(toID) -1
      newRow <- data.frame(id = c(a:b), from = fromID, to=toID)
      metaEdges <- rbind(metaEdges, newRow)
      idCount = idCount + length(toID)
    }
  }
  
  # print(metaNodes)
  
  return (list("metaNodes" = metaNodes, "metaEdges" = metaEdges))
}

#vizAspect: see server.R for possible values
findMappedProperty <- function (metaNodes, metaEdges, targetNeo4jLabel, vizAspect)
{
  # thats because is.na() doesn't work for me, don't know why
  aProperty <- "NA"
  
  # for all properties linked to meta node "label"
  for (p in metaEdges$from[metaEdges$to==targetNeo4jLabel])
  { 
    # find property which is linked to meta node "vizAspect" => thats the propertie to be shown in graph
    if (vizAspect  %in% metaEdges$from[metaEdges$to == p])
    { 
      aProperty <-  p
      break;
    }
  }
 
 return (aProperty)
}