# ECGraphEditor
A small tool to connect to a Neo4j database, edit the network and write it back.

** This software is pre-alpha, if you want to use it do it at your own risk ! Your Neo4j database may be changed **
It is intended for non-commercial and non-productive use only.

## Libraries
This tool uses 

- **RNeo4j** from Nicole White [details here] (http://github.com/nicolewhite/RNeo4j)
- **visNetwork** from Benoit Thieurmel [details here] (http://dataknowledge.github.io/visNetwork/)
- **Neo4j** of course [details here] (http://neo4j.com/)

Thanks for this very useful packages !

## Usage
**Attention:** at this moment in time, this tool can be used only with my adaption of visNetwork
It is not clear when this changes will be adapted (if ever) by the mainstream visNetork. If not, 
my changes will be integrated in this repository

In general the workflow

- ECGraphEditor asks the database which labels, properties for nodes and which relationships exists
- you select which labels and relationships to use
- you select which property of the nodes are mapped to the "label" value of the vis.js library used by visNetwork
  (this is necessary because vis.js can handle only label, group and value per node)
- load graph, edit
- save graph back to Neo4J

More details to come.

## Licence and copyright
see licence file. Copyright of used libraries and packages as well as for Neo4j is hold by their owners.
Refer to the related web sites for details