process EXTRACT_TARBALL {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastq-screen:0.15.3--pl5321hdfd78af_0' :
        'biocontainers/fastq-screen:0.15.3--pl5321hdfd78af_0' }"

    input:
    tuple val(meta), path(tarball)

    output:
    tuple val(meta), path("*.fastq*"), emit: fastq
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # Extract tarball
    tar -xzf ${tarball}
    
    # Find and organize extracted FASTQ files
    find . -name "*.fastq*" -maxdepth 2 | head -1 | xargs -I {} mv {} ${meta.id}_extracted.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version | head -n1 | sed 's/tar (GNU tar) //')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_extracted.fastq
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: 1.30
    END_VERSIONS
    """
}