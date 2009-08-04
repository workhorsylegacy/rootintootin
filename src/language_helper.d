
import tango.text.Util;
import tango.text.Ascii;
import tango.text.convert.Integer;
import tango.text.convert.Float;


public static char[] between(char[] value, char[] before, char[] after) {
	return split(split(value, before)[1], after)[0];
}

// Add a to_s function for basic types
public static char[] to_s(short value) {
	return tango.text.convert.Integer.toString(value);
}

public static char[] to_s(ushort value) {
	return tango.text.convert.Integer.toString(value);
}

public static char[] to_s(int value) {
	return tango.text.convert.Integer.toString(value);
}

public static char[] to_s(uint value) {
	return tango.text.convert.Integer.toString(value);
}

public static char[] to_s(long value) {
	return tango.text.convert.Integer.toString(value);
}

public static char[] to_s(ulong value) {
	char[66] tmp = void;
	return tango.text.convert.Integer.format(tmp, value, "u").dup;
}

public static char[] to_s(float value) {
	return tango.text.convert.Float.toString(value);
}

public static char[] to_s(double value) {
	return tango.text.convert.Float.toString(value);
}

public static char[] to_s(bool value) {
	return value ? "true" : "false";
}

public static char[] to_s(char[] value) {
	return tango.text.Util.repeat(value, 1);
}

public static char[] to_s(char value) {
	char[] new_value;
	new_value ~= value;
	return new_value;
}

// Add a to_# function for strings
public static int to_int(char[] value) {
	return tango.text.convert.Integer.toInt(value);
}

public static uint to_uint(char[] value) {
	return cast(uint) tango.text.convert.Integer.convert(value);
}

public static long to_long(char[] value) {
	return tango.text.convert.Integer.toLong(value);
}

public static ulong to_ulong(char[] value) {
	return tango.text.convert.Integer.convert(value);
}

public static float to_float(char[] value) {
	return tango.text.convert.Float.toFloat(value);
}

public static double to_double(char[] value) {
	return tango.text.convert.Float.parse(value);
}

public static bool to_bool(char[] value) {
	return value == "true";
}

// Can collect strings by auto converting any type you try to add
public class AutoStringArray {
	private char[][] _value;
	public char[][] value() { return _value; }
	public void opCatAssign(char[] value) { _value ~= value; }
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
public char[] capitalize(char[] value) {
	if(value.length == 0) return value;

	char[] first = value[0 .. 1].dup;
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

