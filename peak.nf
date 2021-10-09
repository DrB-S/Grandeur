#!/usr/bin/env nextflow

println("Currently using the Peaks workflow for use with fastas or prokka-annotated contig files\n")
println("Author: Erin Young")
println("email: eriny@utah.gov")
println("Version: v.20211031")
println("")

// TODO : add ete3 or some tree building software

params.outdir = workflow.launchDir + '/peak'
println("The files and directory for results is " + params.outdir)

params.maxcpus = Runtime.runtime.availableProcessors()
println("The maximum number of CPUS used in this workflow is ${params.maxcpus}")

params.fastas = workflow.launchDir + '/fastas'
Channel
  .fromPath("${params.fastas}/*.{fa,fasta,fna}", type: 'file')
  .map { file -> tuple(file.baseName, file) }
  .view { "fasta file : ${it[1]}" }
  .set { contigs }

params.gff = workflow.launchDir + '/gff'
Channel.fromPath("${params.gff}/*.gff", type: 'file')
  .view { "gff file : $it" }
  .set {local_gffs}

params.kraken = false
params.kraken_db = 'kraken_db'
local_kraken = params.kraken
  ? Channel
    .fromPath(params.kraken_db, type:'dir')
    .view { "Local kraken database : $it" }
    .ifEmpty{
      println("No kraken database was found at ${params.kraken_db}")
      println("Set 'params.kraken_db' to directory with kraken database")
      exit 1
    }
  : Channel.empty()

params.prokka = true
params.prokka_options = ''
params.center = 'STAPHB'
params.mincontiglen = 500
process prokka {
  publishDir "${params.outdir}", mode: 'copy'
  tag "${sample}"
  cpus params.maxcpus
  container 'staphb/prokka:latest'

  when:
  params.prokka

  input:
  tuple val(sample), file(contigs) from contigs

  output:
  file("prokka/${sample}/${sample}.{err,faa,ffn,fna,fsa,gbk,log,sqn,tbl,tsv,txt}")
  file("prokka/${sample}/${sample}.gff") into prokka_gffs
  file("logs/${task.process}/${sample}.${workflow.sessionId}.{log,err}")

  shell:
  '''
    mkdir -p !{task.process} logs/!{task.process}
    log_file=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log
    err_file=logs/!{task.process}/!{sample}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    prokka -v >> $log_file

    prokka !{params.prokka_options} \
      --cpu !{task.cpus} \
      --compliant \
      --centre !{params.center} \
      --mincontiglen !{params.mincontiglen} \
      --outdir prokka/!{sample} \
      --locustag locus_tag \
      --prefix !{sample} \
      --force !{contigs} \
      2>> $err_file >> $log_file
  '''
}

prokka_gffs
  .concat(local_gffs)
  .ifEmpty{
    println("No gff files were found at ${params.gff}")
    println("No contig or fasta files ending with '.fa', '.fna', or '.fasta' were found at ${params.fastas}")
    println("Set 'params.gff' to directory with gff files")
    println("Set 'params.fastas' to directory with fastas")
    exit 1
  }
  .set { gffs }

params.roary = true
params.roary_options = ''
if (params.kraken) {
  process roary_kraken {
    publishDir "${params.outdir}", mode: 'copy'
    tag "Roary with Kraken QC"
    cpus params.maxcpus
    container 'staphb/roary:latest'

    when:
    params.roary

    input:
    file(contigs) from gffs.collect()
    path(local_kraken) from local_kraken

    output:
    file("roary/*")
    file("roary/fixed_input_files/*")
    file("roary/core_gene_alignment.aln") into roary_core_genome_iqtree, roary_core_genome_snp_dists
    file("logs/${task.process}/${task.process}.${workflow.sessionId}.{log,err}")

    shell:
    '''
      mkdir -p logs/!{task.process}
      log_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log
      err_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.err

      # time stamp + capturing tool versions
      date | tee -a $log_file $err_file > /dev/null
      roary -a >> $log_file

      roary !{params.roary_options} \
        -p !{task.cpus} \
        -f roary \
        -e -n \
        -qc -k !{local_kraken} \
        *.gff \
        2>> $err_file >> $log_file
    '''
  }
} else {
  process roary {
    publishDir "${params.outdir}", mode: 'copy'
    tag "Roary"
    cpus params.maxcpus
    container 'staphb/roary:latest'

    when:
    params.roary

    input:
    file(contigs) from gffs.collect()

    output:
    file("${task.process}/*")
    file("${task.process}/fixed_input_files/*")
    file("${task.process}/core_gene_alignment.aln") into roary_core_genome_iqtree, roary_core_genome_snp_dists
    file("logs/${task.process}/${task.process}.${workflow.sessionId}.{log,err}")

    shell:
    '''
      mkdir -p logs/!{task.process}
      log_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log
      err_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.err

      # time stamp + capturing tool versions
      date | tee -a $log_file $err_file > /dev/null
      roary -a >> $log_file

      roary !{params.roary_options} \
        -p !{task.cpus} \
        -f !{task.process} \
        -e -n \
        *.gff \
        2>> $err_file >> $log_file
    '''
  }
}

params.iqtree2 = true
params.iqtree2_options = '-t RANDOM -m GTR+F+I -bb 1000 -alrt 1000'
params.outgroup = ''
process iqtree2 {
  publishDir "${params.outdir}", mode: 'copy'
  tag "Pylogenetic Tree"
  cpus params.maxcpus
  container 'staphb/iqtree2:latest'

  when:
  params.iqtree2

  input:
  file(msa) from roary_core_genome_iqtree

  output:
  file("${task.process}/iqtree{.ckp.gz,.treefile,.iqtree,.log,.splits.nex}")
  file("${task.process}/iqtree.contree") into treefile
  file("logs/${task.process}/${task.process}.${workflow.sessionId}.{log,err}")

  shell:
  '''
    mkdir -p !{task.process} logs/!{task.process}
    log_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log
    err_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    iqtree2 -v >> $log_file

    outgroup=''
    if [ -n "!{params.outgroup}" ] ; then outgroup="-o !{params.outgroup}" ; fi

    iqtree2 !{params.iqtree2_options} \
      -s !{msa} \
      -pre !{task.process}/iqtree \
      -nt AUTO \
      -ntmax !{task.cpus} \
      $outgroup \
      2>> $err_file >> $log_file
  '''
}

// // WARNING : THIS CONTAINER DOESN'T EXIST
// params.ete3 = false
// params.ete3_options = ''
// process ete3 {
//   publishDir "${params.outdir}", mode: 'copy'
//   tag "Tree Visualization"
//   cpus 1
//   //container 'staphb/ete3:latest'
//   //container 'docker://quay.io/biocontainers/ete3:3.1.2'
//
//   when:
//   params.ete3
//
//   input:
//   file(newick) from treefile
//
//   output:
//   file("${task.process}/tree.svg")
//   file("logs/${task.process}/${task.process}.${workflow.sessionId}.{log,err}")
//
//   shell:
//   '''
//     mkdir -p !{task.process} logs/!{task.process}
//     log_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log
//     err_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.err
//
//     # time stamp + capturing tool versions
//     date | tee -a $log_file $err_file > /dev/null
//     echo "ETE3 version : $(ete3 version | head -n 1 )" | tee -a $log_file
//
//     ete3 view --image !{task.process}/tree.svg -t !{newick}
//   '''
// }

params.snp_dists = true
params.snp_dists_options = ''
process snp_dists {
  publishDir "${params.outdir}", mode: 'copy'
  tag "SNP matrix"
  cpus 1
  container 'staphb/snp-dists:latest'

  when:
  params.snp_dists

  input:
  file(contigs) from roary_core_genome_snp_dists

  output:
  file("${task.process}/snp_matrix.txt")
  file("logs/${task.process}/${task.process}.${workflow.sessionId}.{log,err}")

  shell:
  '''
    mkdir -p !{task.process} logs/!{task.process}
    log_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log
    err_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    snp-dists -v >> $log_file

    snp-dists !{params.snp_dists_options} \
      !{contigs} \
      2>> $err_file \
      > !{task.process}/snp_matrix.txt
  '''
}

workflow.onComplete {
    println("Pipeline completed at: $workflow.complete")
    println("Execution status: ${ workflow.success ? 'OK' : 'failed' }")
}
