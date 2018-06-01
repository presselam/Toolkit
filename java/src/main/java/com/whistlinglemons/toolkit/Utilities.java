package com.whistlinglemons.toolkit;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.StringJoiner;

/**
 * My debugging utility library.
 *
 * @author Andrew Pressel
 */
public final class Utilities {

  /**
   * Hiding default constructor.
   */
  private Utilities() {
  }

  /**
   * ANSI Color Reset Code.
   */
  public static final String ANSI_RESET = "\u001B[0m";
  /**
   * ANSI Color Black Code.
   */
  public static final String ANSI_BLACK = "\u001B[30m";
  /**
   * ANSI Color Red Code.
   */
  public static final String ANSI_RED = "\u001B[31m";
  /**
   * ANSI Color Green Code.
   */
  public static final String ANSI_GREEN = "\u001B[32m";
  /**
   * ANSI Color Yellow Code.
   */
  public static final String ANSI_YELLOW = "\u001B[33m";
  /**
   * ANSI Color Blue Code.
   */
  public static final String ANSI_BLUE = "\u001B[34m";
  /**
   * ANSI Color Purple Code.
   */
  public static final String ANSI_PURPLE = "\u001B[35m";
  /**
   * ANSI Color Cyan Code.
   */
  public static final String ANSI_CYAN = "\u001B[36m";
  /**
   * ANSI Color White Code.
   */
  public static final String ANSI_WHITE = "\u001B[37m";

  /**
   * Utility to dump a table of data into a nicely formatted display.
   *
   * @param table -- A List of Lists of thingies.
   */
  public static void dumpTable(final List<List> table) {
    int[] widths = null;
    for (List row : table) {
      if (widths == null) {
        widths = new int[row.size()];
      }
      for (int i = 0; i < row.size(); i++) {
        int wide = row.get(i).toString().length();
        if (wide > widths[i]) {
          widths[i] = wide;
        }
      }
    }

    if (widths == null) {
      widths = new int[1];
      widths[0] = 0;
    }

    StringJoiner hdr = new StringJoiner("-+-");
    for (int i = 0; i < widths.length; i++) {
      hdr.add(String.join("", Collections.nCopies(widths[i], "-")));
    }
    System.out.println("+-" + hdr + "-+");

    boolean isData = false;
    for (List<String> row : table) {
      StringJoiner line = new StringJoiner("| ");
      for (int i = 0; i < widths.length; i++) {
        line.add(String.format("%-" + (widths[i] + 1) + "s", row.get(i)));
      }
      System.out.println("| " + line + "|");
      if (!isData) {
        System.out.println("+-" + hdr + "-+");
        isData = true;
      }
    }

    System.out.println("+-" + hdr + "-+");
  }

  /**
   * quick debugging utility.
   *
   * @param <T> - any object
   * @param list -- list of thingies to print
   */
  public static <T> void quick(final T... list) {
    StringBuilder sb = new StringBuilder();
    for (T list1 : list) {
      sb.append("[").append(list1).append("]");
    }
    System.out.println(ANSI_GREEN + sb.toString() + ANSI_RESET);
  }

  /**
   * timestamp debugging information.
   *
   * @param <T> - any object
   * @param list - list of thingies to display
   */
  public static <T> void message(final T... list) {
    String format = "E MMM dd HH:mm:ss yyyy";
    DateTimeFormatter dtf = DateTimeFormatter.ofPattern(format);

    System.out.println("====> " + LocalDateTime.now().format(dtf));
    StringBuilder sb = new StringBuilder();
    for (T item : list) {
      sb.append(item).append("\n");
    }

    System.out.print(sb.toString());
  }

  public static <T> void trace(final T... list) {

	final StackTraceElement[] trace = Thread.currentThread().getStackTrace();
    StackTraceElement ste = trace[2];
    String[] qualName = ste.getClassName().split("\\.");
    String cname = qualName[qualName.length - 1];
    System.out.print("\u001B[32m[TRACE][" + cname + "::" + ste.getMethodName() + "(");

    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < list.length; i++) {
      sb.append(list[i]);
      if (i < list.length - 1) {
        sb.append(",");
      }
    }
    System.out.print(sb.toString());

    System.out.println(")]\u001B[0m");
  }

}
