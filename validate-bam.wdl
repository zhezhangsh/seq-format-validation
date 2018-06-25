## Copyright Broad Institute, 2017
## 
## This WDL performs format validation on SAM/BAM files in a list
##
## Requirements/expectations :
## - One or more SAM or BAM files to validate
## - Explicit request of either SUMMARY or VERBOSE mode in inputs.json
##
## Outputs:
## - Set of .txt files containing the validation reports, one per input file
##
## Cromwell version support 
## - Successfully tested on v30
## - Does not work on versions < v23 due to output syntax
##
## Runtime parameters are optimized for Broad's Google Cloud Platform implementation. 
## For program versions, see docker containers. 
##
## LICENSING : 
## This script is released under the WDL source code license (BSD-3) (see LICENSE in 
## https://github.com/broadinstitute/wdl). Note however that the programs it calls may 
## be subject to different licenses. Users are responsible for checking that they are
## authorized to run all programs before running this script. Please see the docker 
## page at https://hub.docker.com/r/broadinstitute/genomes-in-the-cloud/ for detailed
## licensing information pertaining to the included programs.

# WORKFLOW DEFINITION
workflow ValidateBamsWf {
  Array[File] bam_array 
  String? gatk_docker
  String gatk_image = select_first([gatk_docker, "broadinstitute/gatk:latest"])
  String? gatk_path
  String gatk_launch_path = select_first([gatk_path, "/gatk/gatk"])

  # Process the input files in parallel
  scatter (input_bam in bam_array) {

    # Get the basename, i.e. strip the filepath and the extension
    String bam_basename = basename(input_bam, ".bam")

    # Run the validation 
    call ValidateBAM {
      input:
        bam_file = input_bam,
        output_basename = bam_basename + ".validation",
        docker = gatk_image,
        gatk_path = gatk_launch_path
    }
  }

  # Outputs that will be retained when execution is complete
  output {
    Array[File] validation_reports = ValidateBAM.validation_report
  }
}

# TASK DEFINITIONS

# Validate a SAM or BAM using Picard ValidateSamFile
task ValidateBAM {
  File bam_file
  String output_basename
  String validation_mode
  String gatk_path
  
  Int disk_size
  String mem_size
  String docker

  String output_name = "${output_basename}_${validation_mode}.txt"

  command {
    ${gatk_path} \
      ValidateSamFile \
      --INPUT ${bam_file} \
      --OUTPUT ${output_name} \
      --MODE ${validation_mode}
  }
  runtime {
    docker: docker
    memory: mem_size
    cpu: "1"
    disks: "local-disk " + disk_size + " HDD"
  }
  output {
    File validation_report = "${output_name}"
  }
}
