/*
 * To change this license header, choose License Headers in Project Properties. To change this
 * template file, choose Tools | Templates and open the template in the editor.
 */

package com.whistlinglemons.toolkit;

import static com.whistlinglemons.toolkit.Utilities.quick;
import java.lang.reflect.Array;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

/**
 *
 * @author Andrew Pressel
 */
public class CountedSet<E> implements Set<E> {

  private final Map<E, Integer> summary;

  public CountedSet() {
    summary = new HashMap<E, Integer>();
  }

  @Override
  public int size() {
    return summary.size();
  }

  @Override
  public boolean isEmpty() {
    return summary.isEmpty();
  }

  @Override
  public boolean contains(Object obj) {
    return summary.containsKey((E) obj);
  }

  @Override
  public Iterator<E> iterator() {
    return summary.keySet().iterator();
  }

  @Override
  public Object[] toArray() {
    final Object[] retval = new Object[summary.size()];
    Iterator<E> it = summary.keySet().iterator();
    int i = 0;
    while (it.hasNext()) {
      retval[i++] = it.next();
    }

    return retval;
  }

  @Override
  public <T> T[] toArray(T[] a) {
    int sz = summary.size();
    if (a.length < sz) {
      T[] replacement = (T[]) Array.newInstance(a.getClass().getComponentType(), sz);
      a = replacement;
    }

    int i = 0;
    Iterator<E> it = summary.keySet().iterator();
    while (it.hasNext()) {
      a[i++] = (T) it.next();
    }
    return a;
  }

  @Override
  public boolean add(E e) {
    int count = 0;
    if (summary.containsKey(e)) {
      count = summary.get(e);
    }
    summary.put(e, count + 1);
    return count == 0;
  }

  @Override
  public boolean remove(Object obj) {
    if (!summary.containsKey(obj)) {
      return false;
    }
    int count = summary.get(obj);
    if (count <= 1) {
      summary.remove(obj);
      return true;
    }
    summary.put((E) obj, count - 1);
    return true;
  }

  @Override
  public boolean containsAll(Collection<?> c) {
    Iterator<?> it = c.iterator();
    while (it.hasNext()) {
      if (!summary.containsKey(it.next())) {
        return false;
      }
    }
    return true;
  }

  @Override
  public boolean addAll(Collection<? extends E> c) {
    boolean retval = false;
    Iterator<? extends E> it = c.iterator();
    while (it.hasNext()) {
      retval |= add(it.next());
    }
    return retval;
  }

  @Override
  public boolean retainAll(Collection<?> c) {
    boolean retval = false;
    Iterator<E> it = iterator();
    while (it.hasNext()) {
      E item = it.next();
      if (!c.contains(item)) {
        retval |= remove(item);
      }
    }
    return retval;
  }

  @Override
  public boolean removeAll(Collection<?> c) {
    boolean retval = false;
    Iterator<E> it = iterator();
    while (it.hasNext()) {
      retval |= remove(it.next());
    }
    return retval;
  }

  @Override
  public void clear() {
    summary.clear();
  }

  @Override
  public String toString() {
    return summary.toString();
  }

}
