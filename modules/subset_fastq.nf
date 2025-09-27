process SUBSET_FASTQ {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqtk:1.3--h5bf99c6_3' :
        'biocontainers/seqtk:1.3--h5bf99c6_3' }"

    input:
    tuple val(meta), path(reads)
    val subset_count
    val top

    output:
    tuple val(meta), path("*_subset.fastq*"), emit: fastq
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_gzipped = reads.toString().endsWith('.gz')
    def output_ext = is_gzipped ? '.fastq.gz' : '.fastq'
    
    """
    # Handle subsetting using seqtk for efficiency
    # This replaces the Perl subsetting logic with a more standard tool
    
    if [[ "${subset_count}" != "0" && "${subset_count}" != "null" ]]; then
        # Subset to specific number of reads
        if [[ "${is_gzipped}" == "true" ]]; then
            seqtk sample ${reads} ${subset_count} | gzip > ${prefix}_subset${output_ext}
        else
            seqtk sample ${reads} ${subset_count} > ${prefix}_subset${output_ext}
        fi
    elif [[ "${top}" != "" && "${top}" != "null" ]]; then
        # Extract top N reads (head)
        if [[ "${is_gzipped}" == "true" ]]; then
            zcat ${reads} | head -n \$(( ${top} * 4 )) | gzip > ${prefix}_subset${output_ext}
        else
            head -n \$(( ${top} * 4 )) ${reads} > ${prefix}_subset${output_ext}
        fi
    else
        # No subsetting, just copy
        cp ${reads} ${prefix}_subset${output_ext}
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqtk: \$(seqtk 2>&1 | grep -E '^Version' | sed 's/Version: //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_gzipped = reads.toString().endsWith('.gz')
    def output_ext = is_gzipped ? '.fastq.gz' : '.fastq'
    """
    touch ${prefix}_subset${output_ext}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqtk: 1.3
    END_VERSIONS
    """
}