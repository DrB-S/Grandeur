process drprg {
  tag           "$meta.id"
  label         "process_medium"
  stageInMode   "copy"
  publishDir    path: params.outdir, mode: 'copy'
  container     'staphb/drprg:0.1.1'
  maxForks      10
  //#UPHLICA errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  //#UPHLICA pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  //#UPHLICA memory 1.GB
  //#UPHLICA cpus 3
  //#UPHLICA time '24h'

  when:
  flag =~ 'found'

  input:
  tuple val(meta), file(contigs), val(flag)

  output:
  tuple val(meta), val("drprg"), file("drprg/${prefix}/${prefix}.drprg.json"), emit: collect
  path "drprg/${prefix}/*"
  path "logs/${task.process}/${prefix}.${workflow.sessionId}.log"              , emit: log
path  "versions.yml"                          , emit: versions

  when:
  task.ext.when == null || task.ext.when

  shell:
      def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
  """
    mkdir -p drprg logs/${task.process}
    log_file=logs/${task.process}/${prefix}.${workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log_file
    echo "container : ${task.container}" >> $log_file
    drprg --version >> $log_file
    echo "Nextflow command : " >> $log_file
    cat .command.sh >> $log_file
    
    drprg predict ${params.drprg_options} \
      -x /drprg/mtb/mtb \
      -i ${contigs} \
      -o drprg/${prefix} \
      --sample ${prefix} \
      | tee =a $log_file
  """
}