
import tango.text.Util;
import tango.text.convert.Integer;
import tango.text.convert.Float;

// Add a to_s function for basic types
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
	return tango.text.convert.Integer.toString(value);
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
	return tango.text.convert.Integer.convert(value);
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

