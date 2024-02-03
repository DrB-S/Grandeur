#!/usr/bin/env python

import shutil
from os.path import exists
import pandas as pd
import numpy as np

##########################################
# defining files                         #
##########################################

# input files
amrfinder_input         = 'amrfinderplus.txt'
amrfinder_output        = 'amrfinderplus_mqc.txt'
blobtools_input         = "blobtools_summary.txt"
blobtools_output        = 'blobtools_mqc.tsv'
core_genome_input       = 'core_genome_evaluation.csv'
core_genome_output      = 'core_genome_evaluation_mqc.csv' 
drprg_input             = 'replaceme.csv'
drprg_output            = 'replaceme.csv'
elgato_input            = 'replaceme.csv'
elgato_output           = 'replaceme.csv'
emmtyper_input          = 'replaceme.txt'
emmtyper_output         = 'replaceme.txt'
fastani_input           = 'fastani_summary.csv'
fastani_output          = 'fastani_mqc.csv'
heatcluster_input       = "heatcluster.png"
heatcluster_output      = 'heatcluster_mqc.png'
kleborate_input         = 'kleborate_results.tsv'
kleborate_output        = 'kleborate_mqc.tsv'
mash_input              = 'mash_summary.csv'
mash_output             = 'mash_mqc.csv'
mlst_input              = 'mlst_summary.tsv'
mlst_output             = 'mlst_mqc.tsv'
mykrobe_input           = "mykrobe_summary.csv"
mykrobe_output          = 'mykrobe_summary_mqc.csv'
pbp_input               = 'replaceme.txt'
pbp_output              = 'replaceme.txt'
phytreeviz_iqtr_input   = "iqtree_tree.png"
phytreeviz_iqtr_output  = 'phytreeviz_iqtree2_mqc.png' 
phytreeviz_mshtr_input  = "mashtree_tree.png"
phytreeviz_mshtr_output = 'phytreeviz_mashtree_mqc.png'
plasmidfinder_input     = 'plasmidfinder_result.tsv'
plasmidfinder_output    = 'plasmidfinder_mqc.tsv' 
seqsero2_input          = 'seqsero2_results.txt'
seqsero2_output         = 'seqsero2_mqc.txt'
serotypefinder_input    = 'serotypefinder_results.txt'
serotypefinder_output   = 'serotypefinder_mqc.txt'
shigatyper_input        = 'shigatyper_results.txt' 
shigatyper_output       = 'shigatyper_mqc.tsv'
snpdists_input          = "snp_matrix.txt"
snpdists_output         = 'snpdists_matrix_mqc.txt' 


##########################################
# getting ready for multiqc              #
##########################################

if exists(blobtools_input) :
    blobtools_df = pd.read_table(blobtools_input)
    #TODO:
    #   organisms=($(cut -f 2 blobtools_summary.txt | grep -v all  | grep -v name | sort | uniq ))
    #   samples=($(cut -f 1 blobtools_summary.txt | grep -v all | grep -v sample | sort | uniq ))

    #   echo \${organisms[@]} | tr ' ' '\t' | awk '{print "sample\t" \$0}' > blobtools_mqc.tsv

    #   for sample in \${samples[@]}
    #   do
    #     line="\$sample"

    #     for organism in \${organisms[@]}
    #     do
    #       num=\$(grep -w ^"\$sample" blobtools_summary.txt | grep -w "\$organism" | cut -f 13 )
    #       if [ -z "\$num" ] ; then num=0 ; fi
    #       line="\$line\t\$num"
    #     done
    #     echo -e \$line | sed 's/,//g' >>  blobtools_mqc.tsv
    #   done
    # fi
    blobtools_df.to_csv(blobtools_output, index=False, sep="\t")


if exists(mash_input) :
    mash_df = pd.read_csv(mash_input)
    samples = mash_df['sample'].drop_duplicates().tolist()
    organisms = sorted(mash_df['organism'].drop_duplicates().tolist())
    mash_result_df = pd.DataFrame(columns=["sample"] + organisms)

    for sample in samples:
        df_len = len(mash_result_df)
        mash_result_df.loc[df_len] = pd.Series()
        mash_result_df.at[df_len, "sample"] = sample
        sample_df = mash_df[mash_df['sample'] == sample].copy()

        for organism in organisms:
            mash_result_df.at[df_len, organism] = (sample_df['organism'] == organism).sum()
        #mash_result_df = mash_result_df.reset_index()

        # only worked in python 3.12 :(
        #sample_df = mash_df[mash_df['sample' ] == sample].copy()
        #counts_df = sample_df['organism'].value_counts().reset_index()
        #counts_df = counts_df.rename(columns={"index": "organism", 0: "count"}) 
        #counts_df = counts_df.set_index('organism')
        #counts_df.columns = sample
        #counts_df = counts_df.transpose()
        #mash_result_df = pd.concat([mash_result_df, counts_df], axis=0, join='outer')

    mash_result_df = mash_result_df.fillna(0)
    mash_result_df.to_csv(mash_output, index=False)

if exists(fastani_input):
    fastani_df = pd.read_csv(fastani_input)
    fastani_df.to_csv(fastani_output)

if exists(shigatyper_input):
    shigatyper_df = pd.read_table(shigatyper_input)
    shigatyper_df = shigatyper_df.drop(shigatyper_df.columns[1], axis=1)
    shigatyper_df = shigatyper_df.iloc[:, :2]
    shigatyper_df.to_csv(shigatyper_output, sep="\t")
    #if [ -f 'shigatyper_results.txt' ]     ; then awk '{print \$1 "_" \$2 "\t" \$3}' shigatyper_results.txt > shigatyper_mqc.tsv ; fi

if exists(amrfinder_input):
    amrfinder_df = pd.read_table(amrfinder_input)
    amrfinder_df = amrfinder_df.replace(' ', '_', regex=True)
    amrfinder_df.to_csv(amrfinder_output, sep="\t")

if exists(kleborate_input):
    kleborate_df = pd.read_table(kleborate_input)
    kleborate_df = kleborate_df.iloc[:, [1] + list(range(2, 12))]
    kleborate_df.to_csv(kleborate_output, index=False, sep="\t")
    #if [ -f 'kleborate_results.tsv' ]      ; then cut -f 1,3-12 kleborate_results.tsv > kleborate_mqc.tsv       ; fi

if exists(mlst_input):
    mlst_df = pd.read_table(mlst_input)
    mlst_df = mlst_df.replace(' ', '_', regex=True)
    mlst_df = mlst_df.loc[:, ['sample', 'matching PubMLST scheme', 'ST']] 
    mlst_df.to_csv(mlst_output, index=False, sep="\t")

if exists(plasmidfinder_input):
    plasmidfinder_df = pd.read_table(plasmidfinder_input)
    plasmidfinder_df = plasmidfinder_df.iloc[:, :5]
    plasmidfinder_df.to_csv(plasmidfinder_output, sep="\t")
    #if [ -f 'plasmidfinder_result.tsv' ]   ; then awk '{ print \$1 "_" NR "\t" \$2 "\t" \$3 "\t" \$4 "\t" \$5 }' plasmidfinder_result.tsv > plasmidfinder_mqc.tsv   ; fi

if exists(seqsero2_input):
    seqsero2_df = pd.read_table(seqsero2_input)
    seqsero2_df = seqsero2_df.iloc[:, [0] + list(range(3, 10))]
    seqsero2_df.to_csv(seqsero2_output, index=False, sep="\t")
    #if [ -f 'seqsero2_results.txt' ]       ; then cut -f 1,4-10 seqsero2_results.txt > seqsero2_mqc.txt ; fi

if exists(serotypefinder_input):
    # TODO type error
    serotypefinder_df = pd.read_table(serotypefinder_input)
    serotypefinder_df = serotypefinder_df.iloc[:, :6]
    serotypefinder_df = serotypefinder_df.replace(to_replace=' ', value='', regex=True)
    serotypefinder_df.columns = serotypefinder_df.columns.str.replace(' ', '')
    serotypefinder_df.to_csv(serotypefinder_output, index=True, sep="\t")
    #if [ -f 'serotypefinder_results.txt' ] ; then cut -f 1-6 serotypefinder_results.txt > serotypefinder_mqc.txt  ; fi
   
if exists(core_genome_input):
    core_genome_df = pd.read_csv(core_genome_input)
    core_genome_df = core_genome_df.loc[:, ['sample', 'core', 'soft', 'shell', 'cloud']]
    core_genome_df.to_csv(core_genome_output, index=False)

if exists(heatcluster_input):
    shutil.copyfile(heatcluster_input, heatcluster_output)

if exists(snpdists_input):
    shutil.copyfile(snpdists_input, snpdists_output)

if exists(phytreeviz_iqtr_input):
    shutil.copyfile(phytreeviz_iqtr_input, phytreeviz_iqtr_output)

if exists(phytreeviz_mshtr_input):
    shutil.copyfile(phytreeviz_mshtr_input, phytreeviz_mshtr_output)

if exists(mykrobe_input):
    shutil.copyfile(mykrobe_input, mykrobe_output)