/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module regex;
private import tango.stdc.stringz;

class Regex {
	private RegexAddress _address;
	private char[] _pattern;

	public this(char[] pattern) {
		_pattern = pattern;

		const char* error = null;
		int erroffset = 0;
		_address = c_setup_regex(toStringz(_pattern), error, erroffset);

		if(!_address) {
			throw new Exception("Failed to compile regex: '" ~ _pattern ~ "'\n");
		}
	}

	public char[] pattern() {
		return _pattern;
	}

	public bool is_match(char[] value) {
		return c_is_match_regex(_address, toStringz(value));
	}
}

private:

extern (C):

typedef size_t RegexAddress;
RegexAddress c_setup_regex(char* pattern, char* error, int erroffset);
bool c_is_match_regex(RegexAddress address, char* value);

