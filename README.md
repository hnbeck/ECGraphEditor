# ECGraphEditor
A small tool to connect to a Neo4j database, edit the network and write it back.

**currently under development.**
**This software is pre-alpha, if you want to use it do it at your own risk ! Your Neo4j database may be changed**
It is intended for non-commercial and non-productive use only.

## Libraries
This tool uses and requires

- **RNeo4j** from Nicole White [details here] (http://github.com/nicolewhite/RNeo4j)
- **visNetwork** 0.2.0 (not released yet) from Benoit Thieurmel [details here] (http://dataknowledge.github.io/visNetwork/)
- **shinyDashboard** 0.5.1 from Winston Chang (http://github.com/rstudio/shinydaahboard.git)

This tool needs a running

- **Neo4j** [details here] (http://neo4j.com/)

Thanks for this very useful packages !

## Usage
**Attention:** at this moment in time, this tool can be used only with my adaption of visNetwork
It is not clear when this changes will be adapted (if ever) by the mainstream visNetwork. If not, 
my changes will be integrated in this repository.

My fork of visNetwork is available at  [hnbeck/visNetwork](https://github.com/hnbeck/visNetwork.git)

In general the workflow

- run a Neo4j database
- open the server.R and ui.R file in **RStudio** and so "Run Application" to start the Shiny application
- ECGraphEditor connects to the current Neo4J db 
- you see two panels: a meta graph and the graph itself
- decide which kind of nodes and properties to load from db for the graph:
	+ delete nodes of kind "nodeType" in meta graph if you do not want to load nodes with such label
	+ add edges from "labels" nodes to "properties" nodes to decide which properties has to be shown
		as node label, used as value field and used as popup title. Only one edge from a selected
		"labels" node to a "properties" node is possible ! 
	+ only "properties" nodes can be added for meta graph. If required, reload the meta graph for corrections. 
	+ please note that only node labels can be edited in the graph. Therefore by the meta graph mapping, you
	   also decide which properties to edit and save.
- load graph, edit
- save graph back to Neo4J
- node / edge IDs will be generated by Neo4j when added nodes are saved to database

If you click on a node and then press "Load" button, the following happens:
assume you have multiple nodes with label "A", "B", "C" and some relationships between them.
You click on a "A" node (=select it) and press "Load", then all "B" and "C" nodes will be re-loaded, but all
"A" nodes except the one you selected will be ignored. 

More details to come.

## Known issues

As of pre alpha, there are bugs ;) 
But this is important to note:
- the Neo4j database shall have at least one node, empty databases cannot be handled
- all nodes shall have exactly one label and at least one property per node kind
- edge properties will be ignored so far

## License and copyright
Please refer to the "LICENSE" file in this directory. 
Copyright of used libraries and packages as well as for Neo4j is hold by their owners.
Refer to the related web sites for details