package com.whistlinglemons.toolkit.test;

import static org.junit.Assert.*;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.util.ArrayList;
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
		fail("Not yet implemented");
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
		System.err.println(result);

		String checks[] = { "====>", "(Mon|Tue|Wed|Thur|Fri)", "(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)",
				"\\d{2}", "\\d{2}:\\d{2}:\\d{2}", "\\d{4}", "This is a message test" };
		
		for(String regex : checks){
			System.err.println(regex + " -- " + result.matches(".*" + regex + ".*"));
			assertTrue(result.matches(".*" + regex + ".*"));
		}
	}

	@Test
	public void testTrace() {
		fail("Not yet implemented");
	}

}
