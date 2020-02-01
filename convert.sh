#!/bin/bash

# step 0: Compile java code (uncomment if needed)
mvn package
mv target/round2-0.0.1-SNAPSHOT-full.jar code.jar


ODIR=/Users/reiterns/Documents/Projects/SharedTasks/phase-1-round-2-test-corpus


# step 1: Convert all files from UIMA XMI to CSV
for S in SANTA1 SANTA2 SANTA4 SANTA5 SANTA6 SANTA7 SANTA8
do
	echo "Converting $S"
	for i in $(ls $ODIR/$S)
	do
		echo "  File: $i"
		mkdir -p target/d/$S
		java -Djava.awt.headless=true -Djava.util.logging.config.file=src/main/resources/Logger.properties -cp code.jar de.unistuttgart.ims.creta.santa.round2.GenerateCSV --input $ODIR/$S/$i --outputDirectory target/d/$S
	done
done



