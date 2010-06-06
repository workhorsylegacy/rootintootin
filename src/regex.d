/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module regex;
private import tango.stdc.stringz;

// FIXME: This is not thread safe. 
class Regex {
	private static size_t _inc;
	private static size_t _max;
	public size_t _id;
	private char[] _pattern;

	public static void init(size_t regex_count) {
		_max = regex_count;
		c_regex_init(_max);
	}

	public this(char[] pattern) {
		// Make sure we are not out of ids
		if(_inc == _max)
			throw new Exception("No more free ids.");

		// Get the next id
		_pattern = pattern;
		_id = _inc;
		_inc++;

		int ret = c_setup_regex(_id, toStringz(_pattern));
		if(ret != 0) {
			throw new Exception("Failed to compile regex: '" ~ pattern ~ "'\n");
		}
	}

	public char[] pattern() {
		return _pattern;
	}

	public bool is_match(char[] value) {
		bool retval;
		c_is_match_regex(_id, toStringz(value), &retval);
		return retval;
	}
}

private:

extern (C):

void c_regex_init(size_t regex_count);
int c_setup_regex(size_t index, char* pattern);
int c_is_match_regex(size_t index, char* value, bool* retval);

