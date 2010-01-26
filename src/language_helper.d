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
private import tango.math.Math;

private import tango.text.json.Json;
private import tango.text.xml.Document;


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

public class FixedPoint {
	private uint _before_point;
	private uint _after_point;
	private uint _precision;

	public uint before_point() { return _before_point; }
	public uint after_point() { return _after_point; }
	public uint precision() { return _precision; }

	public this(uint before_point, uint after_point, uint precision) {
		// Make sure the value will fit in the precision
		if(to_s(after_point).length > precision)
			throw new Exception("The value '" ~ to_s(after_point) ~ 
			"' will not fit in the precision '" ~ to_s(precision) ~ "'.");

		_before_point = before_point;
		_after_point = after_point;
		_precision = precision;
	}

	public uint max_after_point() {
		return pow(10, _precision) - 1;
	}

	public string toString() {
		return to_s(_before_point) ~ "." ~ rjust(to_s(_after_point), _precision, "0");
	}

	public double toDouble() {
		double before = _before_point;
		double after = (cast(double)_after_point) / (this.max_after_point+1);
		return before + after;
	}

	public uint toUint() {
		return cast(uint) this.toDouble();
	}

	public void opAddAssign(FixedPoint a) {
		// Get the new before and after
		uint max = this.max_after_point();
		uint before = _before_point + a._before_point;
		uint after = _after_point + a._after_point;

		// Perform the rounding
		if(after > max) {
			uint after_extra = after - max;
			uint before_extra = (after / (max+1));
			before += before_extra;
			after = after - (before_extra * (max+1));
		}

		// Save the result
		_before_point = before;
		_after_point = after;
	}

	public void opAddAssign(double a) {
		string[] pair = tango.text.Util.split(to_s(a), ".");
		uint before = to_uint(pair[0]);
		uint after = to_uint(pair[1]);
		auto other = new FixedPoint(before, after, this.precision);
		this += other;
	}

	public void opAddAssign(int a) {
		_before_point += a;
	}

	public bool opEquals(uint a) {
		return this.toUint() == a;
	}

	public bool opEquals(double a) {
		return this.toDouble() == a;
	}

	unittest {
		// Test properties
		auto a = new FixedPoint(11, 3, 2);
		assert(a.before_point ==  11, to_s(a.before_point) ~ " != 11");
		assert(a.after_point ==  3, to_s(a.after_point) ~ " != 3");
		assert(a.precision ==  2, to_s(a.precision) ~ " != 2");
		assert(a.max_after_point ==  99, to_s(a.max_after_point) ~ " != 99");

		// Test converters
		assert(a.toDouble == 11.03, to_s(a.toDouble) ~ " != 11.03");
		assert(a.toUint == 11, to_s(a.toUint) ~ " != 11");
		assert(a.toString ==  "11.03", a.toString ~ " != 11.03");

		// Test += FixedPoint
		auto b = new FixedPoint(34, 1, 2);
		a += b;
		assert(a == 45.04, a.toString ~ " != 45.04");

		// Test += FixedPoint
		auto c = new FixedPoint(12, 99, 2);
		a += c;
		assert(a == 58.03, a.toString ~ " != 58.03");

		// Test += FixedPoint with round
		auto d = new FixedPoint(12, 99, 2);
		a += d;
		assert(a == 71.02, a.toString ~ " != 71.02");

		// Test += int
		int e = 1;
		a += e;
		assert(a == 72.02, a.toString ~ " != 72.02");

		// Test += float
		float f = 3.02;
		a += f;
		assert(a == 75.04, a.toString ~ " != 75.04");

		// Test += float with round
		float g = 2.99;
		a += g;
		assert(a == 78.03, a.toString ~ " != 78.03");

		// Test += double
		double h = 1.1;
		a += h;
		assert(a == 79.13, a.toString ~ " != 79.13");

		// Test += double with round
		double i = 1.99;
		a += i;
		assert(a == 81.12, a.toString ~ " != 81.12");
	}
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

public static void json_to_dict(ref Dictionary dict, string json_in_a_string) {
	auto json = new Json!(char);
	json.parse(json_in_a_string);
	json_to_dict(dict, json.value());
}

public static void json_to_dict(ref Dictionary dict, Json!(char).Value value) {
	switch(value.type) {
		case Json!(char).Type.Null:
			dict.value = to_s("null");
			break;
		case Json!(char).Type.String:
			dict.value = to_s(value.toString());
			break;
		case Json!(char).Type.RawString:
			dict.value = to_s(value.toString());
			break;
		case Json!(char).Type.True:
			dict.value = to_s(value.toBool());
			break;
		case Json!(char).Type.False:
			dict.value = to_s(value.toBool());
			break;
		case Json!(char).Type.Number:
			dict.value = to_s(value.toNumber());
			break;
		case Json!(char).Type.Object:
			foreach(string sub_key, Json!(char).Value sub_value ; value.toObject.attributes()) {
				Dictionary d = dict[sub_key];
				json_to_dict(d, sub_value);
			}
			break;
		case Json!(char).Type.Array:
			foreach(Json!(char).Value sub_value ; value.toArray()) {
				size_t i = dict.array_items.length;
				Dictionary d = dict[i];
				json_to_dict(d, sub_value);
			}
			break;
	}
}

public static void xml_to_dict(ref Dictionary dict, string xml_in_a_string) {
	auto doc = new Document!(char);
	doc.parse(xml_in_a_string);
	xml_to_dict(dict, doc.tree);
}

public static void xml_to_dict(ref Dictionary dict, Document!(char).Node node) {
	switch(node.type) {
		case XmlNodeType.Data:
			dict.value = to_s(node.value);
		case XmlNodeType.Attribute:
		case XmlNodeType.CData:
		case XmlNodeType.Comment:
		case XmlNodeType.PI:
		case XmlNodeType.Doctype:
			Dictionary d = dict[node.name];
			foreach(child ; node.children) {
				xml_to_dict(d, child);
			}
			break;
		case XmlNodeType.Document:
			// use dict as the root element
			foreach(child ; node.children) {
				xml_to_dict(dict, child);
			}
			break;
		case XmlNodeType.Element:
			Dictionary d = null;
			// Array
			foreach(attribute ; node.attributes) {
				if(attribute.name == "type" && attribute.value == "array") {
					size_t i = dict.array_items.length;
					d = dict[node.name][i];
				}
			}

			// Object
			if(d is null)
				d = dict[node.name];
			foreach(child ; node.children) {
				xml_to_dict(d, child);
			}
			break;
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

