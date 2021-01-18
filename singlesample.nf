#!/usr/bin/env nextflow


// (Tool) params
params.reads                = "$baseDir/data/raw_input/20070846401-3_MB_R{1,2}.fastq.gz"
params.outDir               = "$baseDir"
// SKA Fastq
params.kmer                 = "15"
params.quality_score        = "20"
params.coverage             = "4"
// SKA Align
params.proportion           = "1.0"
// Iq Tree
params.bootstrap            = "1000"
params.contree              = "true"


// Parsing the input parameters
outDir                      = "$params.outDir"
kmer                        = "$params.kmer"
quality_score               = "$params.quality_score"
coverage                    = "$params.coverage"
proportion                  = "$params.proportion"
bootstrap                   = "$params.bootstrap"
contree                     = "$params.contree"


// Path prefixes
r_folder                    = "$baseDir/R/"
params.split_reference_set  = "$baseDir/data/reference_db/*"

// Tool paths
cluster_sample              = "$baseDir/R/clustering.py"
create_tree                 = "$baseDir/R/treemaker.R"
to_json                     = "$baseDir/python/finalize.py"

parameters = "${kmer},${quality_score},${coverage},${proportion},${bootstrap},${contree}"


Channel
    .fromFilePairs( params.reads )
    .ifEmpty{ "cannot find read pairs in path"}
    .set{ raw_reads }



// Pairs forward and reverse fastq files and puts them in to pairReads channel.
process pairReads {
	input:
	set pair_ID, file(reads) from raw_reads

	output:
	set file("${reads[0]}"), file("${reads[1]}") into pair_reads
	"""
	"""

}

// SKA Fastq
process splitKmerReads{
    conda 'bioconda::ska=1.0'
    publishDir outDir + "/results/single_sample/${filename}/ska/", mode: 'copy', pattern: "*.skf"
	input:
	set file(forward_read), file(reverse_read) from pair_reads

	output:
	file "${filename}.skf" into split_to_align, split_to_compare

	script:
	filename = "${forward_read.baseName.replace("_R1.fastq","")}"
	"""
	ska fastq -k ${kmer} -c ${coverage} -q ${quality_score} -o ${filename} $forward_read $reverse_read
	"""
}


// SKA Align
process alignSplitFile{
    conda 'bioconda::ska=1.0'
    publishDir outDir + "/results/single_sample/${filename}/ska/", mode: 'copy', pattern: "*.aln"
    input:
    file(split_kmer) from split_to_align

    output:
    file "${filename}_variants.aln" into alignment
    println("h")
    script:
    filename = split_kmer.baseName
    
    """
    ska align -v -p ${proportion} $baseDir/data/reference_db/* ${split_kmer} -o ${filename}
    """
}


process iqTree{
    conda 'bioconda::iqtree=2.0.3'
    publishDir outDir + "/results/single_sample/${filename}/iqtree/", mode: 'copy'
    input:
    file(alignment_file) from alignment

    output:
    file "${outfile}" into tree_file


    script:
    filename = alignment_file.baseName.replace("_variants", "")
    outfile = "${filename}.contree"
    """
    iqtree -s ${alignment_file} -st DNA -m GTR+G+ASC -T AUTO -bb 1000 -pre ${filename}
    """
}
process iqTree{
    conda 'bioconda::iqtree=2.0.3'
    publishDir outDir + "/results/single_sample/${filename}/iqtree/", mode: 'copy'
    input:
    file(alignment_file) from alignment

    output:
    file "${outfile}" into tree_file


    script:
    filename = alignment_file.baseName.replace("_variants", "")
    if (contree.equals("true")){
        outfile = "${alignment_file.baseName}.contree"
    }
    else{
	outfile = "${alignment_file.baseName}.treefile"
        if (bootstrap.toInteger() == 0){
            """
            iqtree -s ${alignment_file} -st DNA -m GTR+G+ASC -T AUTO -pre ${filename}
            """
        }  
    }


    // Adaptive iqtree command to prevent crashes.
    if (bootstrap.toInteger() < 1000){
        println("WARNING: cannot preform less than 1000 iterations")
        println("Setting number of iterations from ${bootstrap} to 1000 iterations")
        """
        iqtree -s ${alignment_file} -st DNA -m GTR+G+ASC -T AUTO -bb 1000 -pre ${filename}
        """
    }
    else{
        """
        iqtree -s ${alignment_file} -st DNA -m GTR+G+ASC -T AUTO -bb ${bootstrap} -pre ${filename}
        """
   }
}



process rCode{
    conda 'python=3.8.5 r::r-base=3.6.1 conda-forge::r-cowplot=1.1.0 bioconda::bioconductor-ggtree=1.8.2 r::r-ggplot2=3.1.1 bioconda::bioconductor-treeio=1.0.2'
    input:
    file(newick) from tree_file

    script:
    filename = newick.baseName
    pdf_output = outDir + "/results/single_sample/${filename}/${filename}.pdf"
    input = outDir + "/results/single_sample/${filename}/iqtree/${newick}"
    """
    python ${cluster_sample} ${filename} ${r_folder}
    Rscript "${r_folder}treemaker.R" "${r_folder}sample_cluster.txt" ${input} ${pdf_output}
    """
}


process skaCompare{
    conda 'bioconda::ska=1.0'
    publishDir outDir + "/results/single_sample/${split_kmer.baseName}/ska/", mode: 'copy', pattern: "*.tsv"
	input:
	file(split_kmer) from split_to_compare

	output:
	file "${split_kmer.baseName}.tsv" into split_distances

	script:
	"""
	ska compare ${params.split_reference_set} -q ${split_kmer} > ${split_kmer.baseName}.tsv
	"""
}



process jsonify{
    conda 'python=3.8.5 anaconda::pandas=1.1.3'
	input:
	file(distance_dataframe) from split_distances

	script:
	result_folder = "${outDir}/results/single_sample/${distance_dataframe.baseName}/"
	"""
	python ${to_json} ${distance_dataframe} ${result_folder} ${parameters}
	"""
}

