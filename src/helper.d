/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


// FIXME: Rename to web_helper

private import language_helper;

private import tango.util.digest.Digest;
private import tango.util.digest.Sha256;
private import tango.util.encode.Base64;

/** @defgroup web_helper_group The Web Helpers
 *  Helper functions for the web.
 *  @{
 */

// Helper functions for the server
public class Helper {
	private static string[ushort] status_code;
	private static string[string] mimetype_map;
	private static Sha256 _sha_encoder;

	public static this() {
		_sha_encoder = new Sha256();
	}

	public static char[] escape(char[] unescaped) {
		size_t len = unescaped.length;
		size_t i, j;

		// Get the length of the escaped string
		size_t newlen = 0;
		char c;
		for(i=0; i<len; ++i) {
			c = unescaped[i];
			if((c >= '0' && c <= '9') || 
				(c >= 'A' && c <= 'Z') || 
				(c >= 'a' && c <= 'z') || 
				(c == ' ')) {
				++newlen;
			} else {
				newlen += 3;
			}
		}

		// Convert each char
		char[] escaped = new char[newlen];
		for(i=0; i<len; ++i) {
			c = unescaped[i];
			// Escape the normal value
			if((c >= '0' && c <= '9') || 
				(c >= 'A' && c <= 'Z') || 
				(c >= 'a' && c <= 'z')) {
				escaped[j] = c;
				++j;
			// Escape the '+' value
			} else if(c == ' ') {
				escaped[j] = '+';
				++j;
			// Escape the '%FF' value
			} else {
				escaped[j] = '%';
				escaped[j+1] = char_to_hex(cast(char)((c & 0xF0) >> 4));
				escaped[j+2] = char_to_hex(c & 0x0F);
				j += 3;
			}
		}

		return escaped;
	}

	public static char[] unescape(char[] escaped) {
		size_t i, j;

		// Get the length of the escaped and unescaped strings
		size_t len = escaped.length;
		size_t hexcount = count(escaped, "%");
		size_t newlen = len - (hexcount * 2);
		char[] unescaped = new char[newlen];

		// Convert each character
		for(i=0; i<newlen; ++i) {
			// Unescape the '%FF' value
			if(escaped[j] == '%') {
				unescaped[i] = 
					(hex_to_char(escaped[j+1]) << 4) +
					hex_to_char(escaped[j+2]);
				j += 3;
			// Unescape the '+' value
			} else if(escaped[j] == '+') {
				unescaped[i] = ' ';
				++j;
			// Copy the normal value
			} else {
				unescaped[i] = escaped[j];
				++j;
			}
		}

		return unescaped;
	}

	public static string html_escape(string value) {
		value = substitute(value, "&", "&amp;");
		value = substitute(value, "\"", "&quot;");
		value = substitute(value, ">", "&gt;");
		value = substitute(value, "<", "&lt;");

		return value;
	}

	public static string html_unescape(string value) {
		value = substitute(value, "&amp;", "&");
		value = substitute(value, "&quot;", "\"");
		value = substitute(value, "&gt;", ">");
		value = substitute(value, "&lt;", "<");

		return value;
	}

	public static string get_verbose_status_code(ushort code) {
		return tango.text.convert.Integer.toString(code) ~ " " ~ status_code[code];
	}

	public static string hash_and_base64(string value, string salt) {
		_sha_encoder.update(value ~ salt);
		ubyte[] encoded = _sha_encoder.binaryDigest();

		string encodebuf = new char[tango.util.encode.Base64.allocateEncodeSize(encoded)];
		return tango.util.encode.Base64.encode(encoded, encodebuf);
	}

	public static this() {
		status_code[100] = "Continue";
		status_code[101] = "Switching Protocols";
		status_code[200] = "OK";
		status_code[201] = "Created";
		status_code[202] = "Accepted";
		status_code[203] = "Non-Authoritative Information";
		status_code[204] = "No Content";
		status_code[205] = "Reset Content";
		status_code[206] = "Partial Content";
		status_code[300] = "Multiple Choices";
		status_code[301] = "Moved Permanently";
		status_code[302] = "Found";
		status_code[303] = "See Other";
		status_code[304] = "Not Modified";
		status_code[305] = "Use Proxy";
		status_code[307] = "Temporary Redirect";
		status_code[400] = "Bad Request";
		status_code[401] = "Unauthorized";
		status_code[402] = "Payment Required";
		status_code[403] = "Forbidden";
		status_code[404] = "Not Found";
		status_code[405] = "Method Not Allowed";
		status_code[406] = "Not Acceptable";
		status_code[407] = "Proxy Authentication Required";
		status_code[408] = "Request Time-out";
		status_code[409] = "Conflict";
		status_code[410] = "Gone";
		status_code[411] = "Length Required";
		status_code[412] = "Precondition Failed";
		status_code[413] = "Request Entity Too Large";
		status_code[414] = "Request-URI Too Large";
		status_code[415] = "Unsupported Media Type";
		status_code[416] = "Requested range not satisfiable";
		status_code[417] = "Expectation Failed";
		status_code[422] = "Unprocessable Entity";
		status_code[500] = "Internal Server Error";
		status_code[501] = "Not Implemented";
		status_code[502] = "Bad Gateway";
		status_code[503] = "Service Unavailable";
		status_code[504] = "Gateway Time-out";
		status_code[505] = "HTTP Version not supported";

		// FIXME: Add all the popular ones
		// FIXME: Users should be able to add their own in their apps config
		mimetype_map["js"]   = "application/x-javascript";
		mimetype_map["css"]  = "text/css";
		mimetype_map["ico"]  = "image/x-icon";
		mimetype_map["gif"]  = "image/gif";
		mimetype_map["png"]  = "image/png";
		mimetype_map["jpg"]  = "image/jpeg";
		mimetype_map["jpeg"] = "image/jpeg";
		mimetype_map["bmp"]  = "image/bmp";
		mimetype_map["pdf"]  = "application/pdf";
		mimetype_map["html"] = "text/html; charset=utf-8";
		mimetype_map["htm"]  = "text/html; charset=utf-8";
		mimetype_map["json"] = "application/json";
		mimetype_map["xml"] = "text/xml";
		mimetype_map["text"] = "text/plain";
		mimetype_map["txt"] = "text/plain";
	}

	private static char hex_to_char(char c) {
		if(c >= '0' && c <= '9')
			return c - '0';
		else if(c >= 'A' && c <= 'F')
			return c - 'A' + 10;
		else
			return c - 'a' + 10;
	}

	private static char char_to_hex(char c) {
		char retval;
		if(c >= 0 && c <= 9)
			retval = c + '0';
		else if(c >= 10 && c <= 19)
			retval = c + 'A' - 10;
		else
			retval = c + 'a' - 10;

		return retval;
	}
}

/** @} */ // end of web_helper_group

