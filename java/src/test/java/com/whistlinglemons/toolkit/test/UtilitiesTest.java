package com.whistlinglemons.toolkit.test;

import static org.junit.Assert.*;

import java.util.List;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import com.whistlinglemons.toolkit.Utilities;

public class UtilitiesTest {

	private static ByteArrayOutputStream mBaos;
	
	@BeforeClass
	public static void setUpBeforeClass() throws Exception {
	 mBaos = new ByteArrayOutputStream();
		System.setOut(new PrintStream(mBaos));
	}

	@AfterClass
	public static void tearDownAfterClass() throws Exception {
	}

	@Before
	public void setUp() throws Exception {
		mBaos.reset();
	}

	@After
	public void tearDown() throws Exception {
	}

	@Test
	public void testDumpTable() {
		
		ArrayList<List> table = new ArrayList<List>();
		table.add((List) Arrays.asList("City","Latitude", "Longitude"	));
		table.add((List) Arrays.asList("Dayton","9.759444", "-84.191667"	));
		table.add((List) Arrays.asList("Las Vegas","36.175", "-115.136389"));
		table.add((List) Arrays.asList("Pressel", "51.578989", "12.704314"));
		
		Utilities.dumpTable(table);
		String result = mBaos.toString();
		
		String checks[] = { 
				"\\+\\-{11}\\+\\-{11}\\+\\-{13}\\+",
				"\\| City      \\| Latitude  \\| Longitude   \\|",
				"\\| Dayton    \\| 9.759444  \\| -84.191667  \\|",
				"\\| Las Vegas \\| 36.175    \\| -115.136389 \\|",
				"\\| Pressel   \\| 51.578989 \\| 12.704314   \\|"
		};
		
		for(String regex : checks){
			Pattern pat = Pattern.compile(regex);
			Matcher mat = pat.matcher(result);
			assertTrue(mat.find());
		}
	}

	@Test
	public void testQuick() {
		
		Utilities.quick(1,3.14159,"astring", new Object());
		
		String result = mBaos.toString();
		
		Pattern regex = Pattern.compile("\\[1\\]\\[3\\.14159\\]\\[astring\\]\\[java\\.lang\\.Object\\@[0-9a-fA-F]+\\]");
		Matcher match = regex.matcher(result);
		assertTrue(match.find());
	}

	@Test
	public void testMessage() {
		
		Utilities.message("This is a message test");
		String result = mBaos.toString();

		String checks[] = { "====>", "(Mon|Tue|Wed|Thu|Fri|Sat|Sun)", "(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)",
				"\\d{2}", "\\d{2}:\\d{2}:\\d{2}", "\\d{4}", "This is a message test" };
		
		for(String regex : checks){
			Pattern pat = Pattern.compile(regex);
			Matcher mat = pat.matcher(result);
			assertTrue(mat.find());
		}
	}

	@Test
	public void testTrace() {
		
		Utilities.trace(1,3.14159,"astring", new Object());
		String result = mBaos.toString();
		
		String checks[] = { "\\[TRACE\\]", "UtilitiesTest::testTrace",
				"\\(1,3.14159,astring,java.lang.Object@[0-9a-fA-F]+\\)"
		};
		
		for(String regex : checks){
			Pattern pat = Pattern.compile(regex);
			Matcher mat = pat.matcher(result);
			assertTrue(mat.find());
		}
	}

}
