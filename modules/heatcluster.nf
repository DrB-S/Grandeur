process heatcluster {
  tag           "HeatCluster"
  publishDir    params.outdir, mode: 'copy'
  container     'quay.io/uphl/heatcluster:0.4.12-2023-11-15'
  maxForks      10
  //#UPHLICA errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  //#UPHLICA pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  //#UPHLICA memory 1.GB
  //#UPHLICA cpus 3
  //#UPHLICA time '10m'

  input:
  tuple file(snp_matrix)

  output:
  path "sheatcluster/heatcluster*"      , optional : true
  path "heatcluster/heatcluster_mqc.png", optional : true         , emit: for_multiqc
  path "logs/${task.process}/snp_matrix.${workflow.sessionId}.log", emit: log_files

  shell:
  '''
    mkdir -p snp-dists logs/!{task.process}
    log_file=logs/!{task.process}/snp_matrix.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log_file
    HeatCluster.py -v >> $log_file
    echo "container : !{task.container}" >> $log_file
    echo "Nextflow command : " >> $log_file
    cat .command.sh >> $log_file

    HeatCluster.py !{heatcluster_options} \
        -i !{matrix} \
        -o heatcluster/heatcluster \
        | tee -a $log_file


    if [ -f "heatcluster/heatcluster.png" ] ; then cp heatcluster/heatcluster.png heatcluster/heatcluster_mqc.png ; fi
  '''
}