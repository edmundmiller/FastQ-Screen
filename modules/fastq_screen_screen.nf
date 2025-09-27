process FASTQ_SCREEN_SCREEN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastq-screen:0.15.3--pl5321hdfd78af_0' :
        'biocontainers/fastq-screen:0.15.3--pl5321hdfd78af_0' }"

    input:
    tuple val(meta), path(reads)
    path config
    val aligner
    val threads
    val bisulfite
    val tag
    val nohits
    val illumina1_3
    val paired
    val bowtie_opts
    val bowtie2_opts
    val bismark_opts
    val bwa_opts
    val minimap2_opts
    val filter
    val pass
    val inverse

    output:
    tuple val(meta), path("*.txt")    , emit: results
    tuple val(meta), path("*.png"), optional: true, emit: png
    tuple val(meta), path("*.html"), optional: true, emit: html
    tuple val(meta), path("*.tagged.fastq*"), optional: true, emit: tagged
    tuple val(meta), path("*_filter.fastq*"), optional: true, emit: filtered
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def subset_arg = task.ext.subset ? "--subset ${task.ext.subset}" : ''
    def top_arg = task.ext.top ? "--top ${task.ext.top}" : ''
    
    // Build aligner-specific options
    def aligner_arg = "--aligner ${aligner}"
    def threads_arg = "--threads ${threads}"
    def bisulfite_arg = bisulfite ? "--bisulfite" : ""
    def tag_arg = tag ? "--tag" : ""
    def nohits_arg = nohits ? "--nohits" : ""
    def illumina_arg = illumina1_3 ? "--illumina1_3" : ""
    def paired_arg = paired ? "--paired" : ""
    def force_arg = "--force"  // Always force overwrite in pipeline
    
    def bowtie_opts_arg = bowtie_opts ? "--bowtie '${bowtie_opts}'" : ""
    def bowtie2_opts_arg = bowtie2_opts ? "--bowtie2 '${bowtie2_opts}'" : ""
    def bismark_opts_arg = bismark_opts ? "--bismark '${bismark_opts}'" : ""
    def bwa_opts_arg = bwa_opts ? "--bwa '${bwa_opts}'" : ""
    def minimap2_opts_arg = minimap2_opts ? "--minimap2 '${minimap2_opts}'" : ""
    def filter_arg = filter ? "--filter '${filter}'" : ""
    def pass_arg = (pass && pass > 0) ? "--pass ${pass}" : ""
    def inverse_arg = inverse ? "--inverse" : ""

    """
    # Use FastQ Screen directly from the container
    fastq_screen \\
        --conf ${config} \\
        ${aligner_arg} \\
        ${threads_arg} \\
        ${bisulfite_arg} \\
        ${tag_arg} \\
        ${nohits_arg} \\
        ${illumina_arg} \\
        ${paired_arg} \\
        ${force_arg} \\
        ${subset_arg} \\
        ${top_arg} \\
        ${bowtie_opts_arg} \\
        ${bowtie2_opts_arg} \\
        ${bismark_opts_arg} \\
        ${bwa_opts_arg} \\
        ${minimap2_opts_arg} \\
        ${filter_arg} \\
        ${pass_arg} \\
        ${inverse_arg} \\
        ${args} \\
        ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastq_screen: \$(fastq_screen --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_screen.txt
    touch ${prefix}_screen.png
    touch ${prefix}_screen.html
    touch ${prefix}.tagged.fastq
    touch ${prefix}_filter.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastq_screen: 0.16.0
    END_VERSIONS
    """
}