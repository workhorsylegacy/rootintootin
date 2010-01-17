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

private import tango.text.json.Json;
private import tango.text.xml.Document;


public alias char[] string;

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

