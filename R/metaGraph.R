###########################################################################################
#
# metaGraph.R
#
# functions for managing meta graph
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
    nodeDesc <- list("default")
  }
  
  return (list(nDesc = nodeDesc, eDesc =edgeDesc, pDesc = propDesc))
}

# the meta graph has to be
# from vizAspect to property, from property to label 
buildMetaGraph <- function (nodeDesc, edgeDesc, propDesc)
{
  mEdges <- data.frame()
  # take meta nodes: every existing label becomes a node in meta graph
  mNodes <- data.frame(id = nodeDesc, label = nodeDesc, group = "nodeType")
  # every existing property becomes a node in meta graph
  newFrame <- data.frame(id = unique(propDesc$key), label = unique(propDesc$key), group = "Properties")
  mNodes <- rbind(mNodes, newFrame)
  # add the basic  nodes
  newFrame <- data.frame(id = vizAspects, label = c("Label", "Title",  "Value"), group = "Labels")
  mNodes <- rbind(mNodes, newFrame)
  
  # print(mNodes)
  # now build edges: which properties exist in what node (selected by their label)
  idCount= 1;
  for (k in unique(propDesc$key))
  {
    toID = propDesc$label[propDesc$key==k]
    fromID = k
    a = idCount
    b = idCount + length(toID) -1
    newRow <- data.frame(id = c(a:b), from = fromID, to=toID)
    mEdges <- rbind(mEdges, newRow)
    idCount = idCount + length(toID)
  }
  return (list("metaNodes" = mNodes, "metaEdges" = mEdges))
}

#vizAspect is "vizLabel" or "vizValue" or "vizTitle"
findMappedProperty <- function (mNodes, mEdges, targetLabel, vizAspect)
{
  # thats because is.na() doesn't work for me, don't know why
  aProperty <- "NA"
  
  # all properties of node with label targetLabel
  for (p in mEdges$from[mEdges$to==targetLabel])
  { 
    # for propety to be mapped on label
    if (vizAspect  %in% mEdges$from[mEdges$to == p])
    { 
      aProperty <-  p
      break;
    }
  }
 
 return (aProperty)
}