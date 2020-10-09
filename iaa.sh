#!/bin/bash

VARIANT=$1

STDIR=$HOME/Documents/Projects/SharedTasks

GAMMADIR=$STDIR/santa-annotations/gamma
GAMMAJAR=$GAMMADIR/Gamma.jar
TARGETDIR="target"
SOURCEDIR=$STDIR/phase-1-round-2-test-corpus/csv
TEMPDIR=$TARGETDIR/temp

rm -rf $TEMPDIR
mkdir -p $TEMPDIR

TEXTS="01_Buechner 02_Carroll_shortened 03_Salsbury 04_Mansfield 05_Twain 06_Boccaccio 07_Twain 08_Bierce 09_Melville_shortened 10_Kafka 11_Anderson 12_Wilde 13_Bierce"

SANTAS="SANTA1 SANTA2 SANTA4 SANTA5 SANTA6 SANTA7 SANTA8"

# step 2: Merge all files into the target directory
for S in $SANTAS
do
	echo "Merging $S"
	for i in $TEXTS
	do
		cat target/d/$S/$i* > $SOURCEDIR/$S/$i.csv
	done
done

echo "Filtering"
# filtering relevant annotations
for S in $SANTAS
do
	if [[ -ne $TEMPDIR/$S ]]
	then
		mkdir -p $TEMPDIR/$S
	fi
	
	echo "  $S"
	if [ -e filters/$S ]
	then
		FILTER_EXPRESSION=$(cat filters/$S)
		echo "  EXPRESSION: @@$FILTER_EXPRESSION@@"
		for i in $TEXTS
		do
			echo "    $i"
			grep -E "$FILTER_EXPRESSION" $SOURCEDIR/$S/$i.csv > $TEMPDIR/$S/$i.csv
		done
	else
		for i in $TEXTS
		do
			echo "    $i"
			cp $SOURCEDIR/$S/$i.csv $TEMPDIR/$S/$i.csv
		done
	fi
done

echo "Running Gamma"
for s in $SANTAS
do
	echo "  $s"
	if [[ -ne $TARGETDIR/$s ]]
	then
		mkdir -p $TARGETDIR/$s
	fi
	for t in $TEXTS
	do
		echo "    $t"
		java -Djava.library.path=$GAMMADIR -jar $GAMMAJAR -f $TEMPDIR/$s/$t.csv -d > $TARGETDIR/$s/$t.gamma.txt
	done
done

echo "Summarising"
for s in $SANTAS
do
	echo "  $s"
	TSCORE=0
	NUM=0
	for t in $TEXTS
	do
		echo -n "    $t"
		SCORE=$(head -n 1 $TARGETDIR/$s/$t.gamma.txt | perl -e 'printf("%.8f", <STDIN>)')
		echo ": $SCORE"
		NUM=$(bc <<< "$NUM + 1")
		if [[ "$SCORE" != "NaN" && "$SCORE" != "" ]]
		then
			TSCORE=$(bc <<< "$TSCORE + $SCORE")
		fi
	done
	echo -n "    mean: "
	echo $(bc <<< "scale=5; $TSCORE / $NUM")
done