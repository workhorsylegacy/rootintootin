/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


/****h* language_helper/language_helper.d
 *  NAME
 *    language_helper.d
 *  FUNCTION
 *    This file contains many high-level functions that should be useful in 
 *    most D programs. It uses the Tango library. In many cases it can be imported
 *    instead of having to import many of the common files from Tango.
 ******
 */

private import tango.text.Util;
private import tango.text.Ascii;
private import tango.text.convert.Integer;
private import tango.text.convert.Float;
private import tango.math.Math;

private import tango.io.Stdout;
private import tango.text.json.Json;
private import tango.text.xml.Document;


/****d* rootintootin/BUFFER_SIZE
 *  FUNCTION
 *    The default size of of any string buffer.
 * SOURCE
 */
public static const size_t BUFFER_SIZE = 1024 * 10;
/*******/

/****c* language_helper/string
 *  FUNCTION
 *    An alias to the D type char[]
 *  EXAMPLE
 *    string name = "bobrick";
 * SOURCE
 */
public alias char[] string;
/*******/

/****f* language_helper/pow 1
 *  FUNCTION
 *    Returns x to the power of n.
 *  INPUTS
 *    x     - the number.
 *    n     - the exponent.
 *  RESULT
 *    n^x
 *  EXAMPLE
 *    double result = pow(1.5d, 7);
 * SOURCE
 */
public double pow(double x, int n) {
	return tango.math.Math.pow(cast(real) x, n);
}
/*******/

/****f* language_helper/pow 2
 *  FUNCTION
 *    Returns x to the power of n.
 *  INPUTS
 *    x     - the number.
 *    n     - the exponent.
 *  RESULT
 *    n^x
 *  EXAMPLE
 *    int result = pow(2, 32);
 * SOURCE
 */
public int pow(int x, int n) {
	return cast(int) tango.math.Math.pow(cast(real) x, n);
}
/*******/

/****f* language_helper/pow 3
 *  FUNCTION
 *    Returns x to the power of n.
 *  INPUTS
 *    x     - the number.
 *    n     - the exponent.
 *  RESULT
 *    n^x
 *  EXAMPLE
 *    int result = pow(2, 32);
 * SOURCE
 */
public int pow(int x, uint n) {
	return cast(int) tango.math.Math.pow(cast(real) x, n);
}
/*******/

/****f* language_helper/substitute
 *  FUNCTION
 *    Substitute a part of a string.
 *  INPUTS
 *    value   - the string to look in.
 *    before  - the part of the string to replace.
 *    after   - the string that will replace the matches.
 * SOURCE
 */
public static string substitute(string value, string before, string after) {
	return tango.text.Util.substitute(value, before, after);
}
/*******/

/****f* language_helper/index
 *  FUNCTION
 *    Returns the index of the first match in the value.
 *    Scans from left to right.
 *    Returns the length of the value when no match is found.
 *  INPUTS
 *    value   - the string to look in.
 *    match   - the part of the string to find.
 *    start   - the index to start at. The default is zero.
 * SOURCE
 */
public static size_t index(string value, string match, size_t start=0) {
	return tango.text.Util.index!(char)(value, match, start);
}
/*******/

/****f* language_helper/rindex
 *  FUNCTION
 *    Returns the index of the first match in the value. 
 *    Scans from right to left.
 *    Returns the length of the value when no match is found.
 *  INPUTS
 *    value   - the string to look in.
 *    match   - the part of the string to find.
 * SOURCE
 */
public static size_t rindex(string value, string match) {
	return tango.text.Util.rindex!(char)(value, match);
}
/*******/

/****f* language_helper/count
 *  FUNCTION
 *    Returns the number of instances of match in the value.
 *  INPUTS
 *    value   - the string to look in.
 *    match   - the part of the string to find.
 *  NOTES
 *    The tango count function is broken. This:
 *    tango.text.Util.count!(char)("method", "%")
 *    returns 1 instead of 0. So we create our own.
 * SOURCE
 */
public static size_t count(string value, string match) {
	// Just return 0 if the length is 0
	if(match.length == 0)
		return 0;

	size_t retval = 0;
	size_t i = 0;
	while(i < value.length && i + match.length <= value.length) {
		if(value[i .. i+match.length] == match)
			retval++;
		i++;
	}

	return retval;
}

unittest {
	assert(count("", "") == 0);
	assert(count("abc", "abcdef") == 0);
	assert(count("method", "") == 0);
	assert(count("method", "m") == 1);
	assert(count("methhod", "hh") == 1);
	assert(count("hhmethhod", "hh") == 2);
	assert(count("hhmethhodhh", "hh") == 3);
}
/*******/

/****f* language_helper/contains
 *  FUNCTION
 *    Returns true if the match is in the value.
 *  INPUTS
 *    value   - the string to look in.
 *    match   - the part of the string to find.
 * SOURCE
 */
public static bool contains(string value, string match) {
	return tango.text.Util.containsPattern!(char)(value, match);
}

unittest {
	assert(contains("abc", "c"));
	assert(!contains("abc", "z"));
	assert(!contains("abc", ""));
	assert(!contains("", "abc"));
	assert(!contains("", ""));
}
/*******/

/****f* language_helper/pair
 *  FUNCTION
 *    Splits the string in half, and returns the two strings in an array.
 *    Returns true if the separator was found, or false if not.
 *  INPUTS
 *    value       - the string to split.
 *    separator   - the string that is between the two returned strings.
 * SOURCE
 */
public static bool pair(string value, string separator, ref string[] pair) {
	size_t i = index(value, separator);
	if(i == value.length)
		return false;

	pair[0] = value[0 .. i];
	pair[1] = value[i+separator.length .. length];

	return true;
}

unittest {
	string[] _pair = new string[2];
	assert(pair("abc", "b", _pair));
	assert(_pair == ["a", "c"]);

	assert(!pair("abc", "z", _pair));
	assert(_pair == ["a", "c"]);
}
/*******/

/****f* language_helper/split_lines
 *  FUNCTION
 *    Returns the value split with "\r\n"
 *  INPUTS
 *    value   - the string to split.
 * SOURCE
 */
public static string[] split_lines(string value) {
	return split(value, "\r\n");
}
/*******/

/****f* language_helper/split
 *  FUNCTION
 *    Returns the value split with the separator
 *  INPUTS
 *    value       - the string to split.
 *    separator   - the string that splits the value.
 * SOURCE
 */
public static string[] split(string value, string separator) {
	string[] retval = new string[count(value, separator)+1];
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

unittest {
	assert(split("abc", "") == ["abc"]);
	assert(split("abc", "z") == ["abc"]);
	assert(split("abc", "b") == ["a", "c"]);
	assert(split("abc", "a") == ["", "bc"]);
	assert(split("abc", "c") == ["ab", ""]);
}
/*******/

/****f* language_helper/trim
 *  FUNCTION
 *    Returns the value with white space removed from the ends.
 *  INPUTS
 *    value       - the string to trim.
 * SOURCE
 */
public static string trim(string value) {
	return tango.text.Util.trim(value);
}
/*******/

/****f* language_helper/strip
 *  FUNCTION
 *    Returns the value with the match removed from the ends.
 *  INPUTS
 *    value   - the string to split.
 *    match   - the part of the string to remove.
 * SOURCE
 */
public static string strip(char[] value, char[] match) {
	string retval = value;
	retval = tango.text.Util.chopl!(char)(retval, match);
	retval = tango.text.Util.chopr!(char)(retval, match);
	return retval;
}

unittest {
	assert(strip(null, null) == null);
	assert(strip("abc", "") == "abc");
	assert(strip(" abc ", " ") == "abc");
	assert(strip(" abc\t ", " ") == "abc\t");
}
/*******/

/****f* language_helper/join
 *  FUNCTION
 *    Returns the values joined together with the separator between them.
 *  INPUTS
 *    values      - the strings to join.
 *    separator   - the part of the string to remove.
 * SOURCE
 */
public static string join(string[] values, string separator) {
	return tango.text.Util.join(values, separator);
}
/*******/

/****f* language_helper/starts_with
 *  FUNCTION
 *    Returns true if the value starts with the match.
 *  INPUTS
 *    value      - the string to examine.
 *    match      - the string to look for at the start.
 * SOURCE
 */
public static bool starts_with(string value, string match) {
	if(value is null || match is null)
		return false;

	if(value.length < match.length)
		return false;

	return value[0 .. match.length] == match;
}

unittest {
	assert(!starts_with(null, null));
	assert(starts_with("abc", ""));
	assert(starts_with("abc", "a"));
	assert(!starts_with("abc", "b"));
}
/*******/

/****f* language_helper/ends_with
 *  FUNCTION
 *    Returns true if the value ends with the match.
 *  INPUTS
 *    value      - the string to examine.
 *    match      - the string to look for at the end.
 * SOURCE
 */
public static bool ends_with(string value, string match) {
	if(value is null || match is null)
		return false;

	if(value.length < match.length)
		return false;

	return value[length-match.length .. length] == match;
}

unittest {
	assert(!ends_with(null, null));
	assert(ends_with("abc", ""));
	assert(ends_with("abc", "c"));
	assert(!ends_with("abc", "b"));
}
/*******/

/****f* language_helper/between
 *  FUNCTION
 *    Returns the substring between the before and after.
 *  INPUTS
 *    value      - the string to examine.
 *    before     - the string at the front.
 *    after      - the string at the back.
 * SOURCE
 */
public static string between(string value, string before, string after) {
	return split(split(value, before)[1], after)[0];
}
/*******/

/****f* language_helper/before
 *  FUNCTION
 *    Returns a substring before the separator.
 *    Returns the value if there are no separators.
 *  INPUTS
 *    value         - the string to examine.
 *    separator     - the string at the front.
 * SOURCE
 */
public static string before(string value, string separator) {
	size_t i = index(value, separator);

	if(i == value.length)
		return value;

	return value[0 .. i];
}
/*******/

/****f* language_helper/after
 *  FUNCTION
 *    Returns a substring after the separator.
 *    Returns "" if there are no separators.
 *  INPUTS
 *    value         - the string to examine.
 *    separator     - the string at the back.
 * SOURCE
 */
public static string after(string value, string separator) {
	size_t i = index(value, separator);

	if(i == value.length)
		return "";

	size_t start = i + separator.length;

	return value[start .. length];
}
/*******/

/****f* language_helper/after_last
 *  FUNCTION
 *    Returns a substring after the last separator.
 *    Returns "" if there are no separators.
 *  INPUTS
 *    value         - the string to examine.
 *    separator     - the string at the back.
 * SOURCE
 */
public static string after_last(string value, string separator) {
	size_t i = rindex(value, separator);

	if(i == value.length)
		return "";

	size_t start = i + separator.length;

	return value[start .. length];
}
/*******/

/****f* language_helper/rjust
 *  FUNCTION
 *    Returns the value justified to the right.
 *  INPUTS
 *    value         - the value to pad.
 *    width         - the width on the returned string.
 *    pad_char      - the character to pad the string with. The default is "".
 * SOURCE
 */
public string rjust(string value, uint width, string pad_char=" ") {
	int len = width - value.length;
	char[] retval = new char[width];
	tango.text.Util.repeat(pad_char, width, retval);
	retval[len .. length] = value;
	return retval;
}
/*******/

/****f* language_helper/ljust
 *  FUNCTION
 *    Returns the value justified to the left.
 *  INPUTS
 *    value         - the value to pad.
 *    width         - the width on the returned string.
 *    pad_char      - the character to pad the string with. The default is "".
 * SOURCE
 */
public string ljust(string value, uint width, string pad_char=" ") {
	int len = value.length;
	char[] retval = new char[width];
	tango.text.Util.repeat(pad_char, width, retval);
	retval[0 .. len] = value;
	return retval;
}
/*******/

/****f* language_helper/capitalize
 *  FUNCTION
 *    Returns a capitalized string.
 * SOURCE
 */
public string capitalize(string value) {
	if(value.length == 0) return value;

	string first = value[0 .. 1].dup;
	toUpper(first);
	return first ~ value[1 .. length];
}
/*******/

/****f* language_helper/to_s( short )
 *  FUNCTION
 *    Returns a short converted to a string.
 * SOURCE
 */
public static string to_s(short value) {
	return tango.text.convert.Integer.toString(value);
}
/*******/

/****f* language_helper/to_s( ushort )
 *  FUNCTION
 *    Returns an ushort converted to a string.
 * SOURCE
 */
public static string to_s(ushort value) {
	return tango.text.convert.Integer.toString(value);
}
/*******/

/****f* language_helper/to_s( int )
 *  FUNCTION
 *    Returns an int converted to a string.
 * SOURCE
 */
public static string to_s(int value) {
	return tango.text.convert.Integer.toString(value);
}
/*******/

/****f* language_helper/to_s( uint )
 *  FUNCTION
 *    Returns an uint converted to a string.
 * SOURCE
 */
public static string to_s(uint value) {
	return tango.text.convert.Integer.toString(value);
}
/*******/

/****f* language_helper/to_s( long )
 *  FUNCTION
 *    Returns a long converted to a string.
 * SOURCE
 */
public static string to_s(long value) {
	return tango.text.convert.Integer.toString(value);
}
/*******/

/****f* language_helper/to_s( ulong )
 *  FUNCTION
 *    Returns an ulong converted to a string.
 * SOURCE
 */
public static string to_s(ulong value) {
	char[66] tmp = void;
	return tango.text.convert.Integer.format(tmp, cast(long)value, "u").dup;
}
/*******/

/****f* language_helper/to_s( float )
 *  FUNCTION
 *    Returns a float converted to a string.
 * SOURCE
 */
public static string to_s(float value) {
	return tango.text.convert.Float.toString(value);
}
/*******/

/****f* language_helper/to_s( double )
 *  FUNCTION
 *    Returns a double converted to a string.
 * SOURCE
 */
public static string to_s(double value) {
	return tango.text.convert.Float.toString(value);
}
/*******/

/****f* language_helper/to_s( real )
 *  FUNCTION
 *    Returns a real converted to a string.
 * SOURCE
 */
public static string to_s(real value) {
	return tango.text.convert.Float.toString(value);
}
/*******/

/****f* language_helper/to_s( bool )
 *  FUNCTION
 *    Returns a bool converted to a string.
 * SOURCE
 */
public static string to_s(bool value) {
	return value ? "true" : "false";
}
/*******/

/****f* language_helper/to_s( string )
 *  FUNCTION
 *    Returns a string converted to a string.
 * SOURCE
 */
public static string to_s(string value) {
	return value.dup;
}
/*******/

/****f* language_helper/to_s( char )
 *  FUNCTION
 *    Returns a char converted to a string.
 * SOURCE
 */
public static string to_s(char value) {
	string new_value;
	new_value ~= value;
	return new_value;
}
/*******/

/****f* language_helper/to_s( FixedPoint )
 *  FUNCTION
 *    Returns a FixedPoint converted to a string.
 * SOURCE
 */
public static string to_s(FixedPoint value) {
	if(value)
		return value.toString();
	else
		return "0.0";
}
/*******/

/****f* language_helper/to_int( string )
 *  FUNCTION
 *    Returns an int converted to a string.
 * SOURCE
 */
public static int to_int(string value) {
	return tango.text.convert.Integer.toInt(value);
}
/*******/

/****f* language_helper/to_uint( string )
 *  FUNCTION
 *    Returns an uint converted to a string.
 * SOURCE
 */
public static uint to_uint(string value) {
	return cast(uint) tango.text.convert.Integer.convert(value);
}
/*******/

/****f* language_helper/to_short( string )
 *  FUNCTION
 *    Returns a short converted to a string.
 * SOURCE
 */
public static short to_short(string value) {
	return cast(short) tango.text.convert.Integer.convert(value);
}
/*******/

/****f* language_helper/to_ushort( string )
 *  FUNCTION
 *    Returns an ushort converted to a string.
 * SOURCE
 */
public static ushort to_ushort(string value) {
	return cast(ushort) tango.text.convert.Integer.convert(value);
}
/*******/

/****f* language_helper/to_long( string )
 *  FUNCTION
 *    Returns a long converted to a string.
 * SOURCE
 */
public static long to_long(string value) {
	return tango.text.convert.Integer.toLong(value);
}
/*******/

/****f* language_helper/to_ulong( string )
 *  FUNCTION
 *    Returns an ulong converted to a string.
 * SOURCE
 */
public static ulong to_ulong(string value) {
	return tango.text.convert.Integer.convert(value);
}
/*******/

/****f* language_helper/to_float( string )
 *  FUNCTION
 *    Returns a float converted to a string.
 * SOURCE
 */
public static float to_float(string value) {
	return tango.text.convert.Float.toFloat(value);
}
/*******/

/****f* language_helper/to_double( string )
 *  FUNCTION
 *    Returns a double converted to a string.
 * SOURCE
 */
public static double to_double(string value) {
	return tango.text.convert.Float.parse(value);
}
/*******/

/****f* language_helper/to_real( string )
 *  FUNCTION
 *    Returns a real converted to a string.
 * SOURCE
 */
public static real to_real(string value) {
	return tango.text.convert.Float.parse(value);
}
/*******/

/****f* language_helper/to_bool( string )
 *  FUNCTION
 *    Returns a bool converted to a string.
 * SOURCE
 */
public static bool to_bool(string value) {
	return value=="true" || value=="1";
}
/*******/

// FIXME: This has 18, 2 hard coded
/****f* language_helper/to_FixedPoint( string )
 *  FUNCTION
 *    Returns a string converted to a FixedPoint.
 * SOURCE
 */
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
/*******/

// FIXME: Should this be changed to aliases?
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

/****f* language_helper/json_to_dict( string )
 *  FUNCTION
 *    Converts a json string into a Dictionary.
 * SOURCE
 */
public static void json_to_dict(ref Dictionary dict, string json_in_a_string) {
	auto json = new Json!(char);
	json.parse(json_in_a_string);
	json_to_dict(dict, json.value());
}
/*******/

/****f* language_helper/json_to_dict( value )
 *  FUNCTION
 *    Converts a json value into a Dictionary.
 * SOURCE
 */
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
/*******/

/****f* language_helper/xml_to_dict( string )
 *  FUNCTION
 *    Converts an xml string into a Dictionary.
 * SOURCE
 */
public static void xml_to_dict(ref Dictionary dict, string xml_in_a_string) {
	auto doc = new Document!(char);
	doc.parse(xml_in_a_string);
	xml_to_dict(dict, doc.tree);
}
/*******/

/****f* language_helper/xml_to_dict( node )
 *  FUNCTION
 *    Converts an xml node into a Dictionary.
 * SOURCE
 */
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
/*******/

/****c* language_helper/Array
 *  FUNCTION
 *    Template functions that are useful for arrays.
 ******
 */
template Array(T) {
	/****m* language_helper/Array.remove
	 *  FUNCTION
	 *    Remove the item at the index.
	 *  INPUTS
	 *    array   - the array.
	 *    i       - the index to remove.
	 * SOURCE
	 */
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
	/*******/

	/****m* language_helper/Array.remove_item
	 *  FUNCTION
	 *    Remove the item.
	 *  INPUTS
	 *    array   - the array.
	 *    item    - the item to remove.
	 * SOURCE
	 */
	void remove_item(ref T[] array, T item) {
		// Find the index of the item
		for(size_t i=0; i<array.length; i++) {
			if(array[i] == item) {
				remove(array, i);
				return;
			}
		}
	}
	/*******/

	/****m* language_helper/Array.contains
	 *  FUNCTION
	 *    Return true if the item is in the array.
	 *  INPUTS
	 *    array   - the array.
	 *    item    - the item to look for.
	 * SOURCE
	 */
	bool contains(ref T[] array, ref T item) {
		// Return true if the item is in it
		foreach(T entry; array)
			if(entry == item)
				return true;

		// Return false if not found
		return false;
	}
	/*******/

	/****m* language_helper/Array.pop
	 *  FUNCTION
	 *    Remove the item at the index and return it.
	 *  INPUTS
	 *    array   - the array.
	 *    i       - the index of the item to pop.
	 * SOURCE
	 */
	T pop(ref T[] array, size_t i) {
		// Get the item
		T item = array[i];

		// Remove the item
		remove(array, i);

		return item;
	}
	/*******/

	/****m* language_helper/Array.pop_item
	 *  FUNCTION
	 *    Remove the item and return it.
	 *  INPUTS
	 *    array   - the array.
	 *    item    - the item to pop.
	 * SOURCE
	 */
	T pop_item(ref T[] array, ref T item) {
		for(size_t i=0; i<array.length; i++)
			if(array[i] == item)
				return pop(array, i);

		throw new Exception("No item to pop.");
	}
	/*******/
}

/****c* language_helper/AutoStringArray
 *  NAME
 *    AutoStringArray
 *  FUNCTION
 *    Collects strings by auto converting any type you try to add.
 *    For performance, it stores them in a buffer as they are added.
 *  EXAMPLE
 *    auto a = new AutoStringArray();
 *    a ~= "An int: ";
 *    a ~= 600;
 *    a ~= "\n";
 *    a ~= "A bool: ";
 *    a ~= true;
 *    a ~= "\n";
 *    a ~= "A float: ";
 *    a ~= 5.5f;
 *    a ~= "\n";
 *    Stdout(a.toString());
 ******
 */
public class AutoStringArray {
	private string[] _buffers;
	private size_t _i;
	private size_t _j;

	/****m* language_helper/AutoStringArray.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    buffer    - an existing string buffer. Or null if you want 
	 *                it to create its own buffer.
	 * SOURCE
	 */
	public this(string buffer = null) { 
		if(buffer)
			_buffers ~= buffer;
		else
			_buffers ~= new char[BUFFER_SIZE];
	}
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( int )
	 *  INPUTS
	 *    value       - the int to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(int value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( uint )
	 *  INPUTS
	 *    value       - the uint to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(uint value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( long )
	 *  INPUTS
	 *    value       - the long to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(long value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( ulong )
	 *  INPUTS
	 *    value       - the ulong to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(ulong value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( float )
	 *  INPUTS
	 *    value       - the float to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(float value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( double )
	 *  INPUTS
	 *    value       - the double to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(double value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( real )
	 *  INPUTS
	 *    value       - the real to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(real value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( bool )
	 *  INPUTS
	 *    value       - the bool to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(bool value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( char )
	 *  INPUTS
	 *    value       - the char to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(char value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( FixedPoint )
	 *  INPUTS
	 *    value       - the FixedPoint to concatenate to the buffer.
	 * SOURCE
	 */
	public void opCatAssign(FixedPoint value) { opCatAssign(to_s(value)); }
	/*******/

	/****m* language_helper/AutoStringArray.opCatAssign( string )
	 *  INPUTS
	 *    value       - the string to concatenate to the buffer.
	 * SOURCE
	 */
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
	/*******/

	/****m* language_helper/AutoStringArray.toString
	 *  FUNCTION
	 *    Returns everything added to the AutoStringArray as a string.
	 * SOURCE
	 */
	public string toString() {
		string retval;
		if(_buffers.length > 1) {
			retval = join(_buffers[0 .. length-1], "");
		}
		retval ~= _buffers[length-1][0 .. _i];

		return retval;
	}
	/*******/
}

/****c* language_helper/Dictionary
 *  NAME
 *    Dictionary
 *  FUNCTION
 *    A dictionary that has key value pairs. It is designed to have keys
 *    that are strings or ints, with a value of Dictionary.
 *  EXAMPLE
 *    auto d = new Dictionary();
 *    d["company"].value = "Can Opener Inc.";
 *    d["employees"]["bob"].value = "So Awesome";
 *    d["employees"]["tim"].value = "Just Okay";
 ******
 */
public class Dictionary {
	public string value = null;
	public Dictionary[string] named_items = null;
	public Dictionary[size_t] array_items = null;

	/****m* language_helper/Dictionary.opIndex( string )
	 *  FUNCTION
	 *    Returns the value associated with a string key.
	 *  INPUTS
	 *    key       - the associative array key as a string.
	 * SOURCE
	 */
	public Dictionary opIndex(string key) {
		// Initialize the value if it does not exist.
		if((key in this.named_items) == null)
			this.named_items[key] = new Dictionary();
		return this.named_items[key];
	}
	/*******/

	/****m* language_helper/Dictionary.opIndex( size_t )
	 *  FUNCTION
	 *    Returns the value associated with a number key.
	 *  INPUTS
	 *    key       - the associative array key as a size_t.
	 * SOURCE
	 */
	public Dictionary opIndex(size_t i) {
		if((i in this.array_items) == null)
			this.array_items[i] = new Dictionary();
		return this.array_items[i];
	}
	/*******/

	/****m* language_helper/Dictionary.has_key( string )
	 *  FUNCTION
	 *    Returns true if the associative array uses the string key.
	 *  INPUTS
	 *    key       - the associative array key as a string.
	 * SOURCE
	 */
	public bool has_key(string key) {
		return(this.named_items != null && (key in this.named_items) != null);
	}
	/*******/
}


/****c* language_helper/FixedPoint
 *  NAME
 *    FixedPoint
 *  FUNCTION
 *    A class for using fixed point numbers.
 *  EXAMPLE
 *    FixedPoint f = new FixedPoint(11, 3, 10, 2);
 ******
 */
public class FixedPoint {
	private long _precision;
	private ulong _scale;
	private uint _max_precision_width;
	private uint _max_scale_width;

	/****m* language_helper/FixedPoint.precision
	 *  FUNCTION
	 *    The precision is the number before the decimal.
	 * SOURCE
	 */
	public long precision() { return _precision; }
	/*******/

	/****m* language_helper/FixedPoint.scale
	 *  FUNCTION
	 *    The scale is the number after the decimal.
	 * SOURCE
	 */
	public ulong scale() { return _scale; }
	/*******/

	/****m* language_helper/FixedPoint.max_precision_width
	 *  FUNCTION
	 *    The max precision width is the number of digits before the decimal.
	 * SOURCE
	 */
	public uint max_precision_width() { return _max_precision_width; }
	/*******/

	/****m* language_helper/FixedPoint.max_scale_width
	 *  FUNCTION
	 *    The max scale width is the number of digits after the decimal.
	 * SOURCE
	 */
	public uint max_scale_width() { return _max_scale_width; }
	/*******/

	/****m* language_helper/FixedPoint.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    precision           - the number before the decimal.
	 *    scale               - the number after the decimal.
	 *    max_precision_width - the width of digits before the decimal.
	 *    max_scale_width     - the width of digits after the decimal.
	 * SOURCE
	 */
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
	/*******/

	/****m* language_helper/FixedPoint.max_scale
	 *  FUNCTION
	 *    The max scale is the largest number that fits in the max scale width.
	 * SOURCE
	 */
	public ulong max_scale() {
		return pow(10, _max_scale_width) - 1;
	}
	/*******/

	/****m* language_helper/FixedPoint.toString
	 *  FUNCTION
	 *    The number converted to a string.
	 * SOURCE
	 */
	public string toString() {
		return to_s(_precision) ~ "." ~ rjust(to_s(_scale), _max_scale_width, "0");
	}
	/*******/

	/****m* language_helper/FixedPoint.toDouble
	 *  FUNCTION
	 *    The number converted to a double.
	 * SOURCE
	 */
	public double toDouble() {
		double new_precision = _precision;
		double new_scale = (cast(double)_scale) / (this.max_scale+1);
		if(new_precision >= 0) {
			return new_precision + new_scale;
		} else {
			return new_precision + (-new_scale);
		}
	}
	/*******/

	/****m* language_helper/FixedPoint.toLong
	 *  FUNCTION
	 *    The number converted to a long.
	 * SOURCE
	 */
	public long toLong() {
		return cast(long) this.toDouble();
	}
	/*******/

	/****m* language_helper/FixedPoint.opSubAssign
	 *  FUNCTION
	 *    This fixed point -= another fixed point.
	 *  INPUTS
	 *    a       - the FixedPoint to subtract.
	 * SOURCE
	 */
	public void opSubAssign(FixedPoint a){
		// Negative the number so we can add it
		auto other = new FixedPoint(-a.precision, a.scale, a.max_precision_width, a.max_scale_width);
		this += other;
	}
	/*******/

	/****m* language_helper/FixedPoint.opAddAssign( FixedPoint )
	 *  FUNCTION
	 *    This fixed point += another fixed point.
	 *  INPUTS
	 *    a       - the FixedPoint to add.
	 * SOURCE
	 */
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
	/*******/

	/****m* language_helper/FixedPoint.opAddAssign( double )
	 *  FUNCTION
	 *    This fixed point += a double.
	 *  INPUTS
	 *    a       - the double to add.
	 * SOURCE
	 */
	public void opAddAssign(double a) {
		string[] pair = split(to_s(a), ".");
		long new_precision = to_long(pair[0]);
		ulong new_scale = to_ulong(pair[1]);
		auto other = new FixedPoint(new_precision, new_scale, this.max_precision_width, this.max_scale_width);
		this += other;
	}
	/*******/

	/****m* language_helper/FixedPoint.opAddAssign( int )
	 *  FUNCTION
	 *    This fixed point += an int.
	 *  INPUTS
	 *    a       - the int to add.
	 * SOURCE
	 */
	public void opAddAssign(int a) {
		_precision += a;
	}
	/*******/

	/****m* language_helper/FixedPoint.opEquals( long )
	 *  FUNCTION
	 *    This fixed point == an int.
	 *  INPUTS
	 *    a       - the long to compare.
	 * SOURCE
	 */
	public bool opEquals(long a) {
		return this.toLong() == a;
	}
	/*******/

	/****m* language_helper/FixedPoint.opEquals( double )
	 *  FUNCTION
	 *    This fixed point == an double.
	 *  INPUTS
	 *    a       - the double to compare.
	 * SOURCE
	 */
	public bool opEquals(double a) {
		return this.toDouble() == a;
	}
	/*******/

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

//void main() {}
// clear; ldc -g language_helper.d -unittest -I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a
