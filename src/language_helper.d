/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.text.Util;
private import tango.text.Ascii;
private import tango.text.convert.Integer;
private import tango.text.convert.Float;


public alias char[] string;

public static string between(string value, string before, string after) {
	return split(split(value, before)[1], after)[0];
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

public static bool to_bool(string value) {
	return value == "true";
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
	public void opCatAssign(bool value) { _value ~= to_s(value); }
	public void opCatAssign(char value) { _value ~= to_s(value); }
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
	// Remove an item from the array
	void remove(ref T array, size_t i) {
		// Get the length
		size_t len = array.length;

		// If we are not removing from the end, move 
		// the last element to the location of the removed.
		if(i != len - 1)
			array[i] = array[len - 1];

		// Decrease the length by one
		array = array[0 .. len - 1];
	}
}

