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

private import tango.io.Stdout;
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
	private long _precision;
	private ulong _scale;
	private uint _max_precision_width;
	private uint _max_scale_width;

	public long precision() { return _precision; }
	public ulong scale() { return _scale; }
	public uint max_precision_width() { return _max_precision_width; }
	public uint max_scale_width() { return _max_scale_width; }

	public this(long precision, ulong scale, uint max_precision_width, uint max_scale_width) {
		uint max_precision = to_s(long.max).length-1;
		// Make sure the max_precision_width is not too big
		if(max_precision_width > max_precision) {
			throw new Exception("The max_precision_width of '" ~ 
				to_s(max_precision_width) ~ "' is bigger than '" ~ 
				to_s(max_precision) ~ "' the max precision.");
		}

		// Make sure the max_scale_width is not too big
		if(max_scale_width > max_precision) {
			throw new Exception("The max_scale_width of '" ~ 
				to_s(max_scale_width) ~ "' is bigger than '" ~ 
				to_s(max_precision) ~ "' the max precision.");
		}

		// Make sure the max_precision_width is not zero
		if(max_precision_width == 0) {
			throw new Exception("The max_precision_width cannot be zero.");
		}

		// Make sure the max_scale_width is not zero
		if(max_scale_width == 0) {
			throw new Exception("The max_scale_width cannot be zero.");
		}

		// Make sure the value will fit in the max_precision_width
		if(to_s(precision).length > max_precision_width) {
			throw new Exception("The value '" ~ to_s(precision) ~ 
			"' will not fit in the max_precision_width '" ~ to_s(max_precision_width) ~ "'.");
		}

		// Make sure the value will fit in the max_scale_width
		if(to_s(scale).length > max_scale_width) {
			throw new Exception("The value '" ~ to_s(scale) ~ 
			"' will not fit in the max_scale_width '" ~ to_s(max_scale_width) ~ "'.");
		}

		_precision = precision;
		_scale = scale;
		_max_precision_width = max_precision_width;
		_max_scale_width = max_scale_width;
	}

	public ulong max_scale() {
		return pow(10, _max_scale_width) - 1;
	}

	public string toString() {
		return to_s(_precision) ~ "." ~ rjust(to_s(_scale), _max_scale_width, "0");
	}

	public double toDouble() {
		double new_precision = _precision;
		double new_scale = (cast(double)_scale) / (this.max_scale+1);
		if(new_precision >= 0) {
			return new_precision + new_scale;
		} else {
			return new_precision + (-new_scale);
		}
	}

	public long toLong() {
		return cast(long) this.toDouble();
	}

	public void opSubAssign(FixedPoint a){
		// Negative the number so we can add it
		auto other = new FixedPoint(-a.precision, a.scale, a.max_precision_width, a.max_scale_width);
		this += other;
	}

	public void opAddAssign(FixedPoint a) {
		// Get the new precision and scale
		ulong max = this.max_scale();
		long new_precision = _precision + a._precision;
		ulong new_scale;
		if(a._precision >= 0) {
			new_scale = _scale + a._scale;
		} else {
			if(a._scale > _scale) {
				new_precision -= 1;
				new_scale = (100 + _scale) - a._scale;
			} else {
				new_scale = _scale - a._scale;
			}
		}

		// Perform the rounding
		if(new_scale > max) {
			ulong new_scale_extra = new_scale - max;
			long new_precision_extra = (cast(long)new_scale / (cast(long)max+1));
			new_precision += new_precision_extra;
			new_scale = new_scale - (new_precision_extra * (max+1));
		}

		// Make sure the new_precision does not overflow
		if(to_s(new_precision).length > _max_precision_width) {
			string[] buffer;
			for(size_t i=0; i<_max_precision_width; i++)
				buffer ~= "9";
			new_precision = to_long(join(buffer, ""));
		}

		// Make sure the new_scale does not overflow
		if(to_s(new_scale).length > _max_scale_width) {
			string[] buffer;
			for(size_t i=0; i<_max_scale_width; i++)
				buffer ~= "9";
			new_scale = to_ulong(join(buffer, ""));
		}

		// Save the result
		_precision = new_precision;
		_scale = new_scale;
	}

	public void opAddAssign(double a) {
		string[] pair = split(to_s(a), ".");
		long new_precision = to_long(pair[0]);
		ulong new_scale = to_ulong(pair[1]);
		auto other = new FixedPoint(new_precision, new_scale, this.max_precision_width, this.max_scale_width);
		this += other;
	}

	public void opAddAssign(int a) {
		_precision += a;
	}

	public bool opEquals(long a) {
		return this.toLong() == a;
	}

	public bool opEquals(double a) {
		return this.toDouble() == a;
	}

	unittest {
		bool has_thrown = false;

		// Test properties
		auto a = new FixedPoint(11, 3, 10, 2);
		assert(a.precision == 11, to_s(a.precision) ~ " != 11");
		assert(a.scale == 3, to_s(a.scale) ~ " != 3");
		assert(a.max_scale_width == 2, to_s(a.max_scale_width) ~ " != 2");
		assert(a.max_precision_width == 10, to_s(a.max_precision_width) ~ " != 10");
		assert(a.max_scale == 99, to_s(a.max_scale) ~ " != 99");

		// Test properties negative
		a = new FixedPoint(-9, 4, 10, 2);
		assert(a.precision == -9, to_s(a.precision) ~ " != -9");
		assert(a.scale == 4, to_s(a.scale) ~ " != 4");
		assert(a.max_scale_width == 2, to_s(a.max_scale_width) ~ " != 2");
		assert(a.max_precision_width == 10, to_s(a.max_precision_width) ~ " != 10");
		assert(a.max_scale == 99, to_s(a.max_scale) ~ " != 99");

		// Test converters
		a = new FixedPoint(11, 3, 10, 2);
		assert(a.toDouble == 11.03, to_s(a.toDouble) ~ " != 11.03");
		assert(a.toLong == 11, to_s(a.toLong) ~ " != 11");
		assert(a.toString ==  "11.03", a.toString ~ " != 11.03");

		// Test converters negative
		a = new FixedPoint(-9, 4, 10, 2);
		assert(a.toDouble == -9.04, to_s(a.toDouble) ~ " != -9.04");
		assert(a.toLong == -9, to_s(a.toLong) ~ " != -9");
		assert(a.toString ==  "-9.04", a.toString ~ " != -9.04");

		// Test += FixedPoint
		a = new FixedPoint(11, 3, 10, 2);
		auto b = new FixedPoint(34, 1, 10, 2);
		a += b;
		assert(a == 45.04, a.toString ~ " != 45.04");

		// Test += FixedPoint
		auto c = new FixedPoint(12, 99, 10, 2);
		a += c;
		assert(a == 58.03, a.toString ~ " != 58.03");

		// Test += FixedPoint with round
		auto d = new FixedPoint(12, 99, 10, 2);
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

		// Test += FixedPoint negative
		b = new FixedPoint(-13, 5, 10, 2);
		a += b;
		assert(a == 68.07, a.toString ~ " != 68.07");

		// Test -= FixedPoint
		b = new FixedPoint(13, 5, 10, 2);
		a -= b;
		assert(a == 55.02, a.toString ~ " != 55.02");

		// Test -= FixedPoint negative
		b = new FixedPoint(-13, 4, 10, 2);
		a -= b;
		assert(a == 68.06, a.toString ~ " != 68.06");

		// Test += double negative
		i = -1.99;
		a  = new FixedPoint(68, 6, 10, 2);
		a += i;
		assert(a == 66.07, a.toString ~ " != 66.07");

		// Precision overflow
		i = 1;
		a = new FixedPoint(99, 0, 2, 1);
		a += i;
		assert(a == 99.0, a.toString ~ " != 99.0");

		// Make sure the max_precision_width breaks at zero
		has_thrown = false;
		try {
			auto j = new FixedPoint(0, 0, 1, 0);
		} catch(Exception err) {
			has_thrown = true;
		}
		assert(has_thrown == true, "FixedPoint max_precision_width did not break at 0.");

		// Make sure the max_scale_width breaks at zero
		has_thrown = false;
		try {
			auto k = new FixedPoint(0, 0, 0, 1);
		} catch(Exception err) {
			has_thrown = true;
		}
		assert(has_thrown == true, "FixedPoint max_scale_width did not break at 0.");

		// Make sure the max_precision_width breaks at > 19
		has_thrown = false;
		try {
			auto l = new FixedPoint(0, 0, 20, 1);
		} catch(Exception err) {
			has_thrown = true;
		}
		assert(has_thrown == true, "FixedPoint max_precision_width did not break at > 19.");

		// Make sure the max_scale_width breaks at > 19
		has_thrown = false;
		try {
			auto m = new FixedPoint(0, 0, 1, 20);
		} catch(Exception err) {
			has_thrown = true;
		}
		assert(has_thrown == true, "FixedPoint max_scale_width did not break at > 19.");
	}
}

public static string substitute(string value, string before, string after) {
	return tango.text.Util.substitute(value, before, after);
}

public static size_t index(string value, string match, size_t start=0) {
	return tango.text.Util.index!(char)(value, match, start);
}

public static size_t rindex(string value, string match) {
	return tango.text.Util.rindex!(char)(value, match);
}

public static size_t count(string value, string match) {
	return tango.text.Util.count!(char)(value, match);
}

public static bool contains(string value, string match) {
	return tango.text.Util.containsPattern!(char)(value, match);
}

public static string[] split_lines(string value) {
	return split(value, "\r\n");
}

public static bool pair(string value, string separator, ref string[] pair) {
	size_t i = index(value, separator);
	if(i == value.length)
		return false;

	pair[0] = value[0 .. i];
	pair[1] = value[i+separator.length .. length];

	return true;
}

public static string[] split(string value, string separator) {
	string[] retval = new string[count(value, separator)];
	size_t start = 0;
	size_t value_length = value.length;
	size_t separator_length = separator.length;
	size_t i, j;

	while(true) {
		// Get the location of the next split
		i = index(value, separator, start);

		// If there are no more splits, add the last string
		if(i == value_length) {
			retval[j] = value[start .. value_length];
			break;
		}

		// Add the next string
		retval[j] = value[start .. i];
		start = i + separator_length;
		j++;
	}

	return retval;
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

// Returns a substring before the separator. 
// Returns the value if there are no separators.
public static string before(string value, string separator) {
	size_t i = index(value, separator);

	if(i == value.length)
		return value;

	return value[0 .. i];
}

// Returns a substring after the separator. 
// Returns "" if there are no separators.
public static string after(string value, string separator) {
	size_t i = index(value, separator);

	if(i == value.length)
		return "";

	size_t start = i + separator.length;

	return value[start .. length];
}

// Returns a substring after the last separator. 
// Returns "" if there are no separators.
public static string after_last(string value, string separator) {
	size_t i = rindex(value, separator);

	if(i == value.length)
		return "";

	size_t start = i + separator.length;

	return value[start .. length];
}

public string rjust(string value, uint width, string pad_char=" ") {
	int len = width - value.length;
	char[] retval = new char[width];
	tango.text.Util.repeat(pad_char, width, retval);
	retval[len .. length] = value;
	return retval;
}

public string ljust(string value, uint width, string pad_char=" ") {
	int len = value.length;
	char[] retval = new char[width];
	tango.text.Util.repeat(pad_char, width, retval);
	retval[0 .. len] = value;
	return retval;
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
	return tango.text.convert.Integer.format(tmp, cast(long)value, "u").dup;
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

public static string to_s(FixedPoint value) {
	if(value)
		return value.toString();
	else
		return "0.0";
}

// Add a to_# function for strings
public static int to_int(string value) {
	return tango.text.convert.Integer.toInt(value);
}

public static uint to_uint(string value) {
	return cast(uint) tango.text.convert.Integer.convert(value);
}

public static short to_short(string value) {
	return cast(short) tango.text.convert.Integer.convert(value);
}

public static ushort to_ushort(string value) {
	return cast(ushort) tango.text.convert.Integer.convert(value);
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

// FIXME: This has 18, 2 hard coded
public static FixedPoint to_FixedPoint(string value) {
	try {
		string[] pair = split(value, ".");
		if(pair.length == 2) {
			return new FixedPoint(to_long(pair[0]), to_ulong(pair[1]), 18, 2);
		} else if(pair.length == 1) {
			return new FixedPoint(to_long(pair[0]), 0, 18, 2);
		}
	} catch {
	}
	return new FixedPoint(0, 0, 18, 2);
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
public static string to_string(FixedPoint value) { return to_s(value); }


// Collects strings by auto converting any type you try to add
// For performance, it stores them in a buffer as they are added.
public class AutoStringArray {
	private string[] _buffers;
	private size_t _i;
	private size_t _j;
	public static const size_t BUFFER_SIZE = 1024*50;
	public this() { _buffers ~= new char[BUFFER_SIZE]; }
	public void opCatAssign(int value) { opCatAssign(to_s(value)); }
	public void opCatAssign(uint value) { opCatAssign(to_s(value)); }
	public void opCatAssign(long value) { opCatAssign(to_s(value)); }
	public void opCatAssign(ulong value) { opCatAssign(to_s(value)); }
	public void opCatAssign(float value) { opCatAssign(to_s(value)); }
	public void opCatAssign(double value) { opCatAssign(to_s(value)); }
	public void opCatAssign(real value) { opCatAssign(to_s(value)); }
	public void opCatAssign(bool value) { opCatAssign(to_s(value)); }
	public void opCatAssign(char value) { opCatAssign(to_s(value)); }
	public void opCatAssign(FixedPoint value) { opCatAssign(to_s(value)); }

	public void opCatAssign(string value) {
		size_t value_length = value.length;

		// If the value wont fit in the buffer move to a new one
		if(_i + value_length > BUFFER_SIZE) {
			// Trim the extra space off the buffer
			_buffers[_j] = _buffers[_j][0 .. _i];

			// Use the regular buffer size. But if the value is too big, use its size.
			size_t new_size;
			if(value_length > BUFFER_SIZE)
				new_size = value_length;
			else
				new_size = BUFFER_SIZE;

			// Create a new buffer
			_buffers ~= new char[new_size];
			_j++;
			_i = 0;
		}

		// Copy the value into the buffer
		_buffers[_j][_i .. _i+value_length] = value[0 .. value_length];
		_i+= value_length;
	}

	public string toString() {
		string retval;
		if(_buffers.length > 1) {
			retval = join(_buffers[0 .. length-1], "");
		}
		retval ~= _buffers[length-1][0 .. _i];

		return retval;
	}
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
		default:
			throw new Exception("Unknown json type.");
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
		default:
			throw new Exception("Unknown xml type.");
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
