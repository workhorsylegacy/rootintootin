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
			new_precision = to_ulong(tango.text.Util.join(buffer, ""));
		}

		// Make sure the new_scale does not overflow
		if(to_s(new_scale).length > _max_scale_width) {
			string[] buffer;
			for(size_t i=0; i<_max_scale_width; i++)
				buffer ~= "9";
			new_scale = to_ulong(tango.text.Util.join(buffer, ""));
		}

		// Save the result
		_precision = new_precision;
		_scale = new_scale;
	}

	public void opAddAssign(double a) {
		string[] pair = tango.text.Util.split(to_s(a), ".");
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

//void main(){}
