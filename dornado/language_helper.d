/*
# Copyright 2010 Matthew Brennan Jones
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
*/

private import tango.text.Util;
private import tango.text.Ascii;
private import tango.text.convert.Integer;
private import tango.text.convert.Float;
private import tango.math.Math;


public alias char[] string;

public double pow(double x, int n) {
	return tango.math.Math.pow(cast(real) x, n);
}

public int pow(int x, int n) {
	return cast(int) tango.math.Math.pow(cast(real) x, n);
}

public int pow(int x, uint n) {
	return cast(int) tango.math.Math.pow(cast(real) x, n);
}

public static size_t index(string value, string match) {
	return tango.text.Util.index!(char)(value, match);
}

public static bool contains(string value, string match) {
	return tango.text.Util.containsPattern!(char)(value, match);
}

public static string[] split_lines(string value) {
	return tango.text.Util.split(value, "\r\n");
}

public static string[] split(string value, string separator) {
	return tango.text.Util.split(value, separator);
}

public static string trim(string value) {
	return tango.text.Util.trim(value);
}

public static string strip(char[] value, char[] match) {
	string retval = value;
	retval = tango.text.Util.chopl!(char)(retval, match);
	retval = tango.text.Util.chopr!(char)(retval, match);
	return retval;
}

public static string join(string[] values, string separator) {
	return tango.text.Util.join(values, separator);
}

public static bool starts_with(string value, string match) {
	if(value is null || match is null)
		return false;

	if(value.length < match.length)
		return false;

	return value[0 .. match.length] == match;
}

public static bool ends_with(string value, string match) {
	if(value is null || match is null)
		return false;

	if(value.length < match.length)
		return false;

	return value[length-match.length .. length] == match;
}

public static string between(string value, string before, string after) {
	return split(split(value, before)[1], after)[0];
}

public static string before(string value, string separator) {
	string[] sections = split(value, separator);
	if(sections.length > 0)
		return sections[0];
	else
		return "";
}

public static string after(string value, string separator) {
	string[] sections = split(value, separator);
	if(sections.length > 1)
		return sections[1];
	else
		return "";
}

public static string after_last(string value, string separator) {
	string[] sections = split(value, separator);
	if(sections.length > 1)
		return sections[length-1];
	else
		return "";
}

public string rjust(string value, uint width, string pad_char=" ") {
	string[] padding;
	if(width > value.length) {
		for(size_t i=0; i<width-value.length; i++) {
			padding ~= pad_char;
		}
	}
	return tango.text.Util.join(padding, "") ~ value;
}

public string ljust(string value, uint width, string pad_char=" ") {
	string[] padding;
	if(width > value.length) {
		for(size_t i=0; i<width-value.length; i++) {
			padding ~= pad_char;
		}
	}
	return value ~ tango.text.Util.join(padding, "");
}

// Add a to_s function for basic types
public static string to_s(short value) {
	return tango.text.convert.Integer.toString(value);
}

public static string to_s(ushort value) {
	return tango.text.convert.Integer.toString(value);
}

public static string to_s(int value) {
	return tango.text.convert.Integer.toString(value);
}

public static string to_s(uint value) {
	return tango.text.convert.Integer.toString(value);
}

public static string to_s(long value) {
	return tango.text.convert.Integer.toString(value);
}

public static string to_s(ulong value) {
	char[66] tmp = void;
	return tango.text.convert.Integer.format(tmp, value, "u").dup;
}

public static string to_s(float value) {
	return tango.text.convert.Float.toString(value);
}

public static string to_s(double value) {
	return tango.text.convert.Float.toString(value);
}

public static string to_s(real value) {
	return tango.text.convert.Float.toString(value);
}

public static string to_s(bool value) {
	return value ? "true" : "false";
}

public static string to_s(string value) {
	return tango.text.Util.repeat(value, 1);
}

public static string to_s(char value) {
	string new_value;
	new_value ~= value;
	return new_value;
}

// Add a to_# function for strings
public static int to_int(string value) {
	return tango.text.convert.Integer.toInt(value);
}

public static uint to_uint(string value) {
	return cast(uint) tango.text.convert.Integer.convert(value);
}

public static long to_long(string value) {
	return tango.text.convert.Integer.toLong(value);
}

public static ulong to_ulong(string value) {
	return tango.text.convert.Integer.convert(value);
}

public static float to_float(string value) {
	return tango.text.convert.Float.toFloat(value);
}

public static double to_double(string value) {
	return tango.text.convert.Float.parse(value);
}

public static real to_real(string value) {
	return tango.text.convert.Float.parse(value);
}

public static bool to_bool(string value) {
	return value=="true" || value=="1";
}

// Add alternate named methods
public static int to_integer(string value) { return to_int(value); }
public static int to_boolean(string value) { return to_bool(value); }
public static string to_string(short value) { return to_s(value); }
public static string to_string(ushort value) { return to_s(value); }
public static string to_string(int value) { return to_s(value); }
public static string to_string(uint value) { return to_s(value); }
public static string to_string(long value) { return to_s(value); }
public static string to_string(ulong value) { return to_s(value); }
public static string to_string(float value) { return to_s(value); }
public static string to_string(double value) { return to_s(value); }
public static string to_string(real value) { return to_s(value); }
public static string to_string(bool value) { return to_s(value); }
public static string to_string(string value) { return to_s(value); }
public static string to_string(char value) { return to_s(value); }


// Can collect strings by auto converting any type you try to add
public class AutoStringArray {
	private string[] _value;
	public string[] value() { return _value; }
	public void opCatAssign(string value) { _value ~= value; }
	public void opCatAssign(int value) { _value ~= to_s(value); }
	public void opCatAssign(uint value) { _value ~= to_s(value); }
	public void opCatAssign(long value) { _value ~= to_s(value); }
	public void opCatAssign(ulong value) { _value ~= to_s(value); }
	public void opCatAssign(float value) { _value ~= to_s(value); }
	public void opCatAssign(double value) { _value ~= to_s(value); }
	public void opCatAssign(real value) { _value ~= to_s(value); }
	public void opCatAssign(bool value) { _value ~= to_s(value); }
	public void opCatAssign(char value) { _value ~= to_s(value); }
}

public class Dictionary {
	public string value = null;
	public Dictionary[string] named_items = null;
	public Dictionary[size_t] array_items = null;

	public Dictionary opIndex(string key) {
		if((key in this.named_items) == null)
			this.named_items[key] = new Dictionary();
		return this.named_items[key];
	}

	public Dictionary opIndex(size_t i) {
		if((i in this.array_items) == null)
			this.array_items[i] = new Dictionary();
		return this.array_items[i];
	}

	public bool has_key(string key) {
		return(this.named_items != null && (key in this.named_items) != null);
	}

	public bool has_key(string[] keys) {
		Dictionary[string] curr_items = this.named_items;
		foreach(string key ; keys) {
			if((key in curr_items) == null) {
				return false;
			} else {
				curr_items = curr_items[key].named_items;
			}
		}
		return true;
	}
}

// Add string helpers
public string capitalize(string value) {
	if(value.length == 0) return value;

	string first = value[0 .. 1].dup;
	toUpper(first);
	return first ~ value[1 .. length];
}

// Add array helpers
template Array(T) {
	// Remove an item at the index
	void remove(ref T[] array, size_t i) {
		// Get the length
		size_t len = array.length;

		// If we are not removing from the end, move 
		// the last element to the location of the removed.
		if(i != len - 1)
			array[i] = array[len - 1];

		// Decrease the length by one
		array = array[0 .. len - 1];
	}

	// Remove an item
	void remove_item(ref T[] array, T item) {
		// Find the index of the item
		for(size_t i=0; i<array.length; i++) {
			if(array[i] == item) {
				remove(array, i);
				return;
			}
		}
	}

	// Return true if the item is in the array
	bool contains(ref T[] array, ref T item) {
		// Return true if the item is in it
		foreach(T entry; array)
			if(entry == item)
				return true;

		// Return false if not found
		return false;
	}

	// Remove the item at the index and return it
	T pop(ref T[] array, size_t i) {
		// Get the item
		T item = array[i];

		// Remove the item
		remove(array, i);

		return item;
	}

	// Remove the item and return it
	T pop_item(ref T[] array, ref T item) {
		for(size_t i=0; i<array.length; i++)
			if(array[i] == item)
				return pop(array, i);

		throw new Exception("No item to pop.");
	}
}

//void main(){}
