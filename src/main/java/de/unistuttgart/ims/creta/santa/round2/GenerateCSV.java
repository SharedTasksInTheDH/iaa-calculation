package de.unistuttgart.ims.creta.santa.round2;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.concurrent.ExecutionException;
import java.util.function.Consumer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.uima.fit.util.JCasUtil;
import org.apache.uima.jcas.JCas;

import com.lexicalscope.jewel.cli.CliFactory;
import com.lexicalscope.jewel.cli.Option;

import de.unistuttgart.ims.coref.annotator.api.v1.Mention;
import de.unistuttgart.ims.coref.annotator.plugins.DefaultIOPlugin;
import de.unistuttgart.ims.coref.annotator.worker.JCasLoader;

public class GenerateCSV {
	static Options options;

	public static void main(String[] args) throws InterruptedException, ExecutionException {
		options = CliFactory.parseArguments(Options.class, args);

		Pattern p = Pattern.compile("^(\\p{Digit}\\p{Digit}_.*)_(\\p{javaUpperCase}\\p{javaUpperCase}).xmi.gz$",
				Pattern.UNICODE_CHARACTER_CLASS);
		String annotatorId = options.getInput().getName();
		Matcher m = p.matcher(annotatorId);
		m.find();
		annotatorId = m.group(2);

		JCasLoader worker = new JCasLoader(options.getInput(), new DefaultIOPlugin(), options.getLanguage(),
				new ExportAsCSV(options.getOutput(), annotatorId), jcas -> {
					System.err.println("An error ocurrced");
				});
		worker.execute();

		// wait for thread to finish
		worker.get();
	}

	static class ExportAsCSV implements Consumer<JCas> {

		File outputFile;
		String annotatorId;

		public ExportAsCSV(File f, String annotatorId) {
			this.outputFile = f;
			this.annotatorId = annotatorId;
		}

		@Override
		public void accept(JCas jcas) {
			try (CSVPrinter p = new CSVPrinter(new FileWriter(outputFile), CSVFormat.DEFAULT)) {
				int i = 0;
				for (Mention m : JCasUtil.select(jcas, Mention.class)) {
					String key = this.annotatorId + String.valueOf(i++);
					p.printRecord(key, this.annotatorId, m.getEntity().getLabel(), null, m.getBegin(), m.getEnd());
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

	}

	static interface Options {

		@Option
		File getInput();

		@Option
		File getOutput();

		@Option(defaultValue = "de")
		String getLanguage();
	}

}
