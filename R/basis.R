###########################################################################################
#
# basis.R
#
# basis component for getting graphs from Neo4j via RNeo4j, modify and store back
#
# (c) and author: Hans N. Beck
# version: 0.1
#
###########################################################################################
library(igraph)
library(visNetwork)
library(RNeo4j)

# note: at this level, we talk about node labels and node properties
# this are terms on neo4j level

# help function to append element to list
appendList<-function(aList, element)
{
  if (is.null(aList))
    aList <- list(element)
  else
    aList <- list(aList, list(element))

  return (aList)
}

# append new command to command list
appendCommand <- function(aCommandList, aVisCmd)
{

  print(aVisCmd)
  if (aVisCmd$cmd =="addNode")
  {
    aNewFrame <- data.frame(cmd=aVisCmd$cmd,
                            id=aVisCmd$id,
                            label=aVisCmd$label,
                            map = aVisCmd$map,
                            type=aVisCmd$typ,
                            from=0,
                            to=0,
                            prio=1)
  }
  if (aVisCmd$cmd =="editNode")
  {
    aNewFrame <- data.frame(cmd=aVisCmd$cmd,
                            id=aVisCmd$id,
                            label=aVisCmd$label,
                            map = aVisCmd$map,
                            type=aVisCmd$typ,
                            from=0,
                            to=0,
                            prio=1)
  }

  if (aVisCmd$cmd =="addEdge")
  {
    aNewFrame <- data.frame(cmd=aVisCmd$cmd,
                            id= aVisCmd$id,
                            label= "",
                            map="",
                            type=aVisCmd$type,
                            from=aVisCmd$from,
                            to=aVisCmd$to,
                            prio=2)
  }
  if (aVisCmd$cmd =="deleteEdge")
  {
    aNewFrame <- data.frame(cmd=aVisCmd$cmd,
                            id=aVisCmd$id,
                            label="",
                            map = "",
                            type="",
                            from=0,
                            to=0,
                            prio=3)
  }
  if (aVisCmd$cmd =="deleteNode")
  {
    aNewFrame <- data.frame(cmd=aVisCmd$cmd,
                            id=aVisCmd$id,
                            label="",
                            map = "",
                            type="",
                            from=0,
                            to=0,
                            prio=4)
  }

  data <- rbind(aCommandList, aNewFrame)
  return(data)
}

# determine a new ID, take free ids available by deletions into account
fetchNewId <- function(aVectorofIds, aDataFrame)
{
  if (is.null(aDataFrame))
    newID = 1
  else
    newID <- nrow(aDataFrame) + 1

  if (length(aVectorofIds) > 0)
  {
    newID = aVectorofIds[length(aVectorofIds)]
    aVectorofIds <<- aVectorofIds[aVectorofIds != newID]
  }
  return(newID)
}

# create node clause for cypher to filter nodes by label
buildNodeLabelExpr <- function(nodeLabels)
{
  clauseExpr = ""
  if (!is.null(nodeLabels) && nodeLabels != "")
  {
    keyList = strsplit(nodeLabels, " ")
    conjunction = "where "
    for (i in keyList)
    {
      clauseExpr = paste0(clauseExpr, conjunction)
      clauseExpr = paste0(clauseExpr, "n:", i)
      conjunction = " OR "
    }
  }
  return (clauseExpr)
}

# create cypher expression to filter relations
buildRelationExpr <-function(edgeTypes)
{
  expr = ""
  if (!is.null(edgeTypes) && edgeTypes != "")
  {
    keyList = strsplit(edgeTypes, " ")
    conjunction = ""
    for (i in keyList)
    {
      expr = paste0(expr, conjunction)
      expr = paste0(expr,  ":",i)
      conjunction = "|"
    }
  }
  return(expr)
}

printGraphData <- function(nodes, edges)
{
  print (paste("n rows nodes: ", nrow(nodes)))
  print (paste("n rows edges: ", nrow(edges)))

}

