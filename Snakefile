configfile: "RNASeq.yaml"

SAMPLES=sorted(glob_wildcards(config["SOURCE"]+"/{samples}"+config["EXT"]).samples)

SAMPLES_NF=[]
import re
for item in SAMPLES:
	var1=re.sub('_L00[1-2]_R[1-2]','',str(item))
	SAMPLES_NF.append(var1)

SAMPLES_SET = set(SAMPLES_NF)
SAMPLES_UNIQ = list(SAMPLES_SET)

rule all:
	input:
		config["DEST"]+"/5_featurecounts/combined_counts.txt",
		config["DEST"]+"/6_te/2_te_counts/combined_TE_counts.txt"

rule merge_forward_lanes:
	input:
		L1=config["SOURCE"]+"/{SAMPLES_UNIQ}_L001_R1"+config["EXT"],
		L2=config["SOURCE"]+"/{SAMPLES_UNIQ}_L002_R1"+config["EXT"]
	output:
		config["DEST"]+"/1_mergelane/{SAMPLES_UNIQ}_R1"+config["EXT"]
	resources: cpus=1, mem_mb=10000, time_min=1440
	shell:
		"""
		cat {input.L1} {input.L2} > {output}
		"""
rule merge_reverse_lanes:
	input:
		L1=config["SOURCE"]+"/{SAMPLES_UNIQ}_L001_R2"+config["EXT"],
		L2=config["SOURCE"]+"/{SAMPLES_UNIQ}_L002_R2"+config["EXT"]
	output:
		config["DEST"]+"/1_mergelane/{SAMPLES_UNIQ}_R2"+config["EXT"]
	resources: cpus=1, mem_mb=10000, time_min=1440
	shell:
		"""
		cat {input.L1} {input.L2} > {output}
		"""
rule qc:
	input:
		R1=config["DEST"]+"/1_mergelane/{SAMPLES_UNIQ}_R1"+config["EXT"],
		R2=config["DEST"]+"/1_mergelane/{SAMPLES_UNIQ}_R2"+config["EXT"]
	output:
		R1=config["DEST"]+"/2_qc/{SAMPLES_UNIQ}_R1"+config["EXT"],
		R2=config["DEST"]+"/2_qc/{SAMPLES_UNIQ}_R2"+config["EXT"],
		html=config["DEST"]+"/2_qc/{SAMPLES_UNIQ}.html",
		json=config["DEST"]+"/2_qc/{SAMPLES_UNIQ}.json"
	resources: cpus=4, mem_mb=20000, time_min=1440
	shell:
		"""
		module add fastp
		fastp \
		--thread 4 \
		-i {input.R1} \
		-I {input.R2} \
		-o {output.R1} \
		-O {output.R2} \
		-h {output.html} \
		-j {output.json}
		"""

rule bbduk:
	input:
		R1=config["DEST"]+"/2_qc/{SAMPLES_UNIQ}_R1"+config["EXT"],
		R2=config["DEST"]+"/2_qc/{SAMPLES_UNIQ}_R2"+config["EXT"]
	output:
		M1=config["DEST"]+"/3_bbduk/{SAMPLES_UNIQ}_R1.rRNA.fq",
		U1=config["DEST"]+"/3_bbduk/{SAMPLES_UNIQ}_R1.nonrRNA.fq",
		M2=config["DEST"]+"/3_bbduk/{SAMPLES_UNIQ}_R2.rRNA.fq",
		U2=config["DEST"]+"/3_bbduk/{SAMPLES_UNIQ}_R2.nonrRNA.fq"
	params:
		RNAREF=config["RNAREF"]
	resources: cpus=4, mem_mb=20000, time_min=1440
	shell:
		"""
		module load java_jdk/1.8.231
		module load bbmap/38.73
		bbduk.sh \
		in1={input.R1} \
		in2={input.R2} \
		outm1={output.M1} \
		outu1={output.U1} \
		outm2={output.M2} \
		outu2={output.U2} \
		k=31 \
		ref={params.RNAREF}
		"""

rule gsnap:
	input:
		U1=config["DEST"]+"/3_bbduk/{SAMPLES_UNIQ}_R1.nonrRNA.fq",
		U2=config["DEST"]+"/3_bbduk/{SAMPLES_UNIQ}_R2.nonrRNA.fq"
	output:
		RAWBAM=config["DEST"]+"/4_bam/1_rawbam/{SAMPLES_UNIQ}.bam"
	params:
		DBGSNAP=config["DBGSNAP"],
		DBGSNAPDIR=config["DBGSNAPDIR"]
	resources: cpus=8, mem_mb=40000, time_min=1440
	shell:
		"""
		module load gmap_gsnap/2019.09.12
		gsnap \
		--gunzip \
		-D {params.DBGSNAPDIR} \
		-d {params.DBGSNAP} \
		{input.U1} \
		{input.U2} \
		-t 8 \
		-N 1 \
		--orientation=RF \
		-A sam | \
		samtools view -Sb - \
		> {output.RAWBAM};
		"""

rule sort_bam:
	input:
		RAWBAM=config["DEST"]+"/4_bam/1_rawbam/{SAMPLES_UNIQ}.bam"
	output:
		SORTBAM=config["DEST"]+"/4_bam/2_sort/{SAMPLES_UNIQ}.bam"
	params:
		TMP=config["DEST"]+"/4_bam/1_rawbam/tmp_{SAMPLES_UNIQ}"
	resources: cpus=8, mem_mb=20000, time_min=1440
	shell:
		"""
		module add samtools/1.10
		samtools sort \
		-@ 8 \
		-T {params.TMP} \
		-o {output.SORTBAM} \
		{input.RAWBAM} ;
		"""

rule index_bam:
	input:
		SORTBAM=config["DEST"]+"/4_bam/2_sort/{SAMPLES_UNIQ}.bam"
	output:
		INDEXBAM=config["DEST"]+"/4_bam/2_sort/{SAMPLES_UNIQ}.bam.bai"
	resources: cpus=8, mem_mb=20000, time_min=1440
	shell:
		"""
		module add samtools/1.10
		samtools index \
		-@ 8 \
		{input.SORTBAM} \
		{output.INDEXBAM} ;
		"""

rule featurecounts:
	input:
		SORTBAM=config["DEST"]+"/4_bam/2_sort/{SAMPLES_UNIQ}.bam"
	output:
		COUNTS=config["DEST"]+"/5_featurecounts/{SAMPLES_UNIQ}_counts.txt"
	params:
		GTFGSNAP=config["GTFGSNAP"]
	resources: cpus=8, mem_mb=20000, time_min=1440
	shell:
		"""
		module load subread/1.6.4
		featureCounts \
		-a {params.GTFGSNAP} \
		-t exon \
		-F GTF \
		-g gene_id \
		-T 40 \
		-s 0 \
		-p \
		-D 1200 \
		-o {output.COUNTS} \
		{input.SORTBAM}
		"""
rule aggregate:
	input:
		list=expand(config["DEST"]+"/5_featurecounts/{SAMPLES_UNIQ}_counts.txt",SAMPLES_UNIQ=SAMPLES_UNIQ)
	params:
		config["DEST"]+"/4_bam/2_sort/"
	output:
		config["DEST"]+"/5_featurecounts/combined_counts.txt"
	resources: cpus=2, mem_mb=10000, time_min=1440
	run:
		import pandas as pd
		list = input.list
		out1 = []
		for f in list:
		    df = pd.read_csv(f,sep='\t',header=[1])
		    out1.append(df.iloc[:,6])
		df = pd.concat(out1,axis=1)
		S_1 = pd.read_csv(list[1],sep='\t',header=[1])
		df.insert(0,'Geneid', S_1.iloc[:,0])
		df.insert(1,'length',S_1.iloc[:,5])
		df.columns = df.columns.str.replace(params[0],'')
		df.to_csv(output[0],index=False,header=True,sep="\t",encoding='utf-8')

rule create_sym_links:
	input:
		U1=config["DEST"]+"/3_bbduk/{SAMPLES_UNIQ}_R1.nonrRNA.fq",
		U2=config["DEST"]+"/3_bbduk/{SAMPLES_UNIQ}_R2.nonrRNA.fq"
	output:
		K1=config["DEST"]+"/6_te/1_fastq_symlinks/{SAMPLES_UNIQ}_L001_R1.fastq",
		K2=config["DEST"]+"/6_te/1_fastq_symlinks/{SAMPLES_UNIQ}_L001_R2.fastq"
	resources: cpus=1, mem_mb=10000, time_min=1440
	shell:
		"""
		ln -s {input.U1} {output.K1}
		ln -s {input.U2} {output.K2}
		"""

rule salmon_te:
	input:
		K1=config["DEST"]+"/6_te/1_fastq_symlinks/{SAMPLES_UNIQ}_L001_R1.fastq",
		K2=config["DEST"]+"/6_te/1_fastq_symlinks/{SAMPLES_UNIQ}_L001_R2.fastq"
	output:
		COUNTS=config["DEST"]+"/6_te/2_te_counts/{SAMPLES_UNIQ}_TE_counts.txt"
	params:
		DIR1=config["DEST"]+"/6_te/2_te_counts/{SAMPLES_UNIQ}/",
		DIR2="{SAMPLES_UNIQ}_L001"
	resources: cpus=5, mem_mb=20000, time_min=1440
	shell:
		"""
		source /opt/ohpc/pub/Software/anaconda3/etc/profile.d/conda.sh
		conda activate salmon_te
		/data/software/SalmonTE/SalmonTE.py \
		quant \
		--reference=dm \
		--exprtype=count \
		--outpath={params.DIR1} \
		{input.K1} \
		{input.K2}
		cp {params.DIR1}/{params.DIR2}/quant.sf {output.COUNTS}
		"""

rule aggregate_te:
	input:
		list=expand(config["DEST"]+"/6_te/2_te_counts/{SAMPLES_UNIQ}_TE_counts.txt",SAMPLES_UNIQ=SAMPLES_UNIQ)
	output:
		config["DEST"]+"/6_te/2_te_counts/combined_TE_counts.txt"
	params:
		config["DEST"]+"/6_te/2_te_counts/"
	resources: cpus=1, mem_mb=10000, time_min=1440
	run:
		import pandas as pd
		list = input.list
		out1 = []
		for f in list:
		    df = pd.read_csv(f,sep='\t',header=[0])
		    out1.append(df.iloc[:,4])
		df = pd.concat(out1,axis=1)
		S_1 = pd.read_csv(list[1],sep='\t',header=[0])
		df.columns = list
		df.columns = df.columns.str.replace(params[0],'')
		df.insert(0,'Geneid', S_1.iloc[:,0])
		df.insert(1,'length',S_1.iloc[:,1])
		df.to_csv(output[0],index=False,header=True,sep="\t",encoding='utf-8')
