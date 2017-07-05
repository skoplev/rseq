#BSUB -J assemble
#BSUB -P acc_STARNET
#BSUB -q alloc
#BSUB -W 12:00
#BSUB -R "rusage[mem=4000]"
#BSUB -M 8000
#BSUB -n 4
#BSUB -e logs/error.%J
#BSUB -o logs/output.%J


module load stringtie

mkdir assembl

for file_path in *.bam; do
	# get base name including extension
	base=$(basename $file_path)

	# sample id, without extension
	sample=${base%.*}

	echo "Assembling $file_path"
	stringtie -p 6 \
		-G $annot \
		-o assembl/$sample.gtf \
		-l $sample \
		$file_path
done

mkdir merged
ls assembl/*.gtf > merged/mergelist.txt

# Merge transcripts from all samples
echo "Merging"
stringtie --merge -p 6 \
	-G $annot \
	-o merged/stringtie_merged.gtf \
	merged/mergelist.txt

# Estimate transcript abundances for each sample with respect to merged list of transcripts
mkdir merged/counts
for file_path in align/bam/*.bam; do
	echo "Counting " $file_path
	base=$(basename $file_path)
	sample=${base%.*}

	mkdir merged/counts/$sample

	stringtie -e -B \
		-p 8 \
		-G merged/stringtie_merged.gtf \
		-o merged/counts/$sample/$sample.gtf \
		$file_path
done

# Extract transcript counts and write to .csv files
# prepDE.py can be found at https://ccb.jhu.edu/software/stringtie/index.shtml?t=manual#deseq
# cd merged
mkdir results
prepDE.py -i counts \
	-g results/gene_count_matrix.csv \
	-t results/transcript_count_matrix.csv
