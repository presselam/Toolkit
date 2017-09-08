/*
 * To change this license header, choose License Headers in Project Properties. To change this
 * template file, choose Tools | Templates and open the template in the editor.
 */

package com.pressel.toolkit;

/**
 *
 * @author Andrew Pressel
 */
public class Wonder {

  private String format;

  private long startTime;
  private int tick;
  private int total;
  private int frequency;
  private int threshold;
  private String header;

  public Wonder(final int total) {
    this(total, 20);
  }

  public Wonder(final int total, final int frequency) {
    this.total = total;
    this.frequency = frequency;
    reset();
  }

  public void reset() {
    startTime = System.currentTimeMillis();
    tick = 1;
    int wide = String.valueOf(total).length();
    format = "%" + wide + "d  %" + wide + "d  %5.01f  %12s  %8.01f  %12s\n";
    header = String.format("%" + wide + "s  %" + wide + "s  %5s  %12s  %8s  %12s\n", "Done",
        "Total", "%", "Elapsed", "Rate/s", "Estimate");

  }

  public void tick() {
    tick++;
    if ((tick % ((total / frequency) + 1)) == 0 || (tick == total)) {
      banner();
    }
  }

  public void banner() {
    System.out.print(header);
    header = "";
    long now = System.currentTimeMillis();
    long delta = (now - startTime);
    float rate = ((float) tick / delta);
    long estimate = (long) ((total - tick) / rate);
    // quick(rate, tick, rate / tick, total - tick, estimate);
    String row = String.format(format, tick, total, ((float) tick / total) * 100, timeString(delta),
        (rate * 1000), timeString(estimate));
    System.out.print(row);
  }

  private String timeString(long millis) {
    int hr = (int) (millis / 3600000);
    millis = millis % 3600000;
    int mn = (int) (millis / 60000);
    millis %= 60000;
    int sc = (int) (millis / 1000);
    millis %= 1000;

    return String.format("%02d:%02d:%02d.%03d", hr, mn, sc, millis);
  }

}
