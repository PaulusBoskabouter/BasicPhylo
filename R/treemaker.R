#imports
library(ggplot2)
library(ggtree)
library(cowplot)

#This code is called in nextflow like this; Rscript treemaker.R path_to_clusteredsamples.txt input_newickfile pdf_output_path
#Fetching commandline args parsed via NextFlow.
#args[6] is a file containing the clusters including samples.
#args[7] is a treefile from iqtree.
#args[8] is the output path for the pdf.

args <- commandArgs()
#read cluster table.
cluster <- read.table(file= args[6], sep="\t", stringsAsFactor=F)

#create color vector from cluster color column.
coloring <- c("Slow" = "white", "Rapid" = "gray14")
for (row in 1:nrow(cluster)) {
  
  #kleur <- cluster[row, "color"]
  coloring[cluster[row, "cluster"]] = cluster[row, "color"]
}


#initiate tree.
tree <- read.tree(file= args[7])
p <- ggtree(tree, branch.length = 'none')
# add organism names to tree.
p <- p + geom_tiplab(size=5)


# Start listener for PDF file, file height is variable for amount of samples.
pdf(file = args[8], width = 20, height = (nrow(cluster)/5))

# Kijk nog even naar kleuren variabel maken
# Create coloured labels and prints the tree.
print(gheatmap(p, cluster[,1:2], offset = 5, width=0.2, color="black") + 
  scale_fill_manual(values=coloring))
dev.off()


