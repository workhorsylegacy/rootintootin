/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


// FIXME: Rename to server_helper

private import tango.text.Util;
private import tango.text.convert.Integer;
private import language_helper;

private import tango.io.digest.Digest;
private import tango.io.digest.Sha256;
private import tango.io.encode.Base64;


// Helper functions for the server
public class Helper {
	private static string[ushort] status_code;
	private static string[string] escape_map;
	private static string[string] mimetype_map;

	public static string escape_value(string value) {
		value = tango.text.Util.substitute(value, "+", "%2B");
		value = tango.text.Util.substitute(value, " ", "+");

		foreach(string normal, string escaped ; escape_map) {
			value = tango.text.Util.substitute(value, escaped, normal);
		}

		return value;
	}

	public static string unescape_value(string value) {
		foreach(string normal, string escaped ; escape_map) {
			value = tango.text.Util.substitute(value, escaped, normal);
		}

		value = tango.text.Util.substitute(value, "+", " ");
		value = tango.text.Util.substitute(value, "%2B", "+");
		return value;
	}

	public static string get_verbose_status_code(ushort code) {
		return tango.text.convert.Integer.toString(code) ~ " " ~ status_code[code];
	}

	public static string hash_and_base64(string value, string salt) {
		Sha256 sha_encoder = new Sha256();
		sha_encoder.update(value ~ salt);
		ubyte[] encoded = sha_encoder.binaryDigest();

		string encodebuf = new char[tango.io.encode.Base64.allocateEncodeSize(encoded)];
		return tango.io.encode.Base64.encode(encoded, encodebuf);
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
		status_code[500] = "Internal Server Error";
		status_code[501] = "Not Implemented";
		status_code[502] = "Bad Gateway";
		status_code[503] = "Service Unavailable";
		status_code[504] = "Gateway Time-out";
		status_code[505] = "HTTP Version not supported";

		escape_map[";"] = "%3B";
		escape_map["\n"] = "%0A";
		escape_map["\r"] = "%0D";
		escape_map["\t"] = "%09";
		escape_map[" "] = "%20";
		escape_map["!"] = "%21";
		escape_map["\""] = "%22";
		escape_map["$"] = "%24";
//		escape_map["%"] = "%25";
		escape_map["&"] = "%26";
		escape_map["'"] = "%27";
		escape_map["("] = "%28";
		escape_map[")"] = "%29";
		escape_map["*"] = "%2A";
		escape_map[","] = "%2C";
		escape_map["-"] = "%2D";
		escape_map["."] = "%2E";
		escape_map["/"] = "%2F";
/*
		escape_map["0"] = "%30";
		escape_map["1"] = "%31";
		escape_map["2"] = "%32";
		escape_map["3"] = "%33";
		escape_map["4"] = "%34";
		escape_map["5"] = "%35";
		escape_map["6"] = "%36";
		escape_map["7"] = "%37";
		escape_map["8"] = "%38";
		escape_map["9"] = "%39";
*/
		escape_map[":"] = "%3A";
		escape_map["<"] = "%3C";
		escape_map["="] = "%3D";
		escape_map[">"] = "%3E";
		escape_map["?"] = "%3F";
		escape_map["@"] = "%40";
/*
		escape_map["A"] = "%41";
		escape_map["B"] = "%42";
		escape_map["C"] = "%43";
		escape_map["D"] = "%44";
		escape_map["E"] = "%45";
		escape_map["F"] = "%46";
		escape_map["G"] = "%47";
		escape_map["H"] = "%48";
		escape_map["I"] = "%49";
		escape_map["J"] = "%4A";
		escape_map["K"] = "%4B";
		escape_map["L"] = "%4C";
		escape_map["M"] = "%4D";
		escape_map["N"] = "%4E";
		escape_map["O"] = "%4F";
		escape_map["P"] = "%50";
		escape_map["Q"] = "%51";
		escape_map["R"] = "%52";
		escape_map["S"] = "%53";
		escape_map["T"] = "%54";
		escape_map["U"] = "%55";
		escape_map["V"] = "%56";
		escape_map["W"] = "%57";
		escape_map["X"] = "%58";
		escape_map["Y"] = "%59";
		escape_map["Z"] = "%5A";
*/
		escape_map["["] = "%5B";
		escape_map["\\"] = "%5C";
		escape_map["]"] = "%5D";
		escape_map["^"] = "%5E";
		escape_map["_"] = "%5F";
		escape_map["`"] = "%60";
/*
		escape_map["a"] = "%61";
		escape_map["b"] = "%62";
		escape_map["c"] = "%63";
		escape_map["d"] = "%64";
		escape_map["e"] = "%65";
		escape_map["f"] = "%66";
		escape_map["g"] = "%67";
		escape_map["h"] = "%68";
		escape_map["i"] = "%69";
		escape_map["j"] = "%6A";
		escape_map["k"] = "%6B";
		escape_map["l"] = "%6C";
		escape_map["m"] = "%6D";
		escape_map["n"] = "%6E";
		escape_map["o"] = "%6F";
		escape_map["p"] = "%70";
		escape_map["q"] = "%71";
		escape_map["r"] = "%72";
		escape_map["s"] = "%73";
		escape_map["t"] = "%74";
		escape_map["u"] = "%75";
		escape_map["v"] = "%76";
		escape_map["w"] = "%77";
		escape_map["x"] = "%78";
		escape_map["y"] = "%79";
		escape_map["z"] = "%7A";
*/
		escape_map["{"] = "%7B";
		escape_map["|"] = "%7C";
		escape_map["}"] = "%7D";
		escape_map["~"] = "%7E";
		escape_map["¡"] = "%A1";
		escape_map["¢"] = "%A2";
		escape_map["£"] = "%A3";
		escape_map["¤"] = "%A4";
		escape_map["¥"] = "%A5";
		escape_map["¦"] = "%A6";
		escape_map["§"] = "%A7";
		escape_map["¨"] = "%A8";
		escape_map["©"] = "%A9";
		escape_map["ª"] = "%AA";
		escape_map["«"] = "%AB";
		escape_map["¬"] = "%AC";
		escape_map["­"] = "%AD";
		escape_map["®"] = "%AE";
		escape_map["¯"] = "%AF";
		escape_map["°"] = "%B0";
		escape_map["±"] = "%B1";
		escape_map["²"] = "%B2";
		escape_map["³"] = "%B3";
		escape_map["´"] = "%B4";
		escape_map["µ"] = "%B5";
		escape_map["¶"] = "%B6";
		escape_map["·"] = "%B7";
		escape_map["¸"] = "%B8";
		escape_map["¹"] = "%B9";
		escape_map["º"] = "%BA";
		escape_map["»"] = "%BB";
		escape_map["¼"] = "%BC";
		escape_map["½"] = "%BD";
		escape_map["¾"] = "%BE";
		escape_map["¿"] = "%BF";
		escape_map["À"] = "%C0";
		escape_map["Á"] = "%C1";
		escape_map["Â"] = "%C2";
		escape_map["Ã"] = "%C3";
		escape_map["Ä"] = "%C4";
		escape_map["Å"] = "%C5";
		escape_map["Æ"] = "%C6";
		escape_map["Ç"] = "%C7";
		escape_map["È"] = "%C8";
		escape_map["É"] = "%C9";
		escape_map["Ê"] = "%CA";
		escape_map["Ë"] = "%CB";
		escape_map["Ì"] = "%CC";
		escape_map["Í"] = "%CD";
		escape_map["Î"] = "%CE";
		escape_map["Ï"] = "%CF";
		escape_map["Ð"] = "%D0";
		escape_map["Ñ"] = "%D1";
		escape_map["Ò"] = "%D2";
		escape_map["Ó"] = "%D3";
		escape_map["Ô"] = "%D4";
		escape_map["Õ"] = "%D5";
		escape_map["Ö"] = "%D6";
		escape_map["×"] = "%D7";
		escape_map["Ø"] = "%D8";
		escape_map["Ù"] = "%D9";
		escape_map["Ú"] = "%DA";
		escape_map["Û"] = "%DB";
		escape_map["Ü"] = "%DC";
		escape_map["Ý"] = "%DD";
		escape_map["Þ"] = "%DE";
		escape_map["ß"] = "%DF";
		escape_map["à"] = "%E0";
		escape_map["á"] = "%E1";
		escape_map["â"] = "%E2";
		escape_map["ã"] = "%E3";
		escape_map["ä"] = "%E4";
		escape_map["å"] = "%E5";
		escape_map["æ"] = "%E6";
		escape_map["ç"] = "%E7";
		escape_map["è"] = "%E8";
		escape_map["é"] = "%E9";
		escape_map["ê"] = "%EA";
		escape_map["ë"] = "%EB";
		escape_map["ì"] = "%EC";
		escape_map["í"] = "%ED";
		escape_map["î"] = "%EE";
		escape_map["ï"] = "%EF";
		escape_map["ð"] = "%F0";
		escape_map["ñ"] = "%F1";
		escape_map["ò"] = "%F2";
		escape_map["ó"] = "%F3";
		escape_map["ô"] = "%F4";
		escape_map["õ"] = "%F5";
		escape_map["ö"] = "%F6";
		escape_map["÷"] = "%F7";
		escape_map["ø"] = "%F8";
		escape_map["ù"] = "%F9";
		escape_map["ú"] = "%FA";
		escape_map["û"] = "%FB";
		escape_map["ü"] = "%FC";
		escape_map["ý"] = "%FD";
		escape_map["þ"] = "%FE";
		escape_map["ÿ"] = "%FF";
		escape_map["Ā"] = "%100";
		escape_map["ā"] = "%101";
		escape_map["Ă"] = "%102";
		escape_map["ă"] = "%103";
		escape_map["Ą"] = "%104";
		escape_map["ą"] = "%105";
		escape_map["Ć"] = "%106";
		escape_map["ć"] = "%107";
		escape_map["Ĉ"] = "%108";
		escape_map["ĉ"] = "%109";
		escape_map["Ċ"] = "%10A";
		escape_map["ċ"] = "%10B";
		escape_map["Č"] = "%10C";
		escape_map["č"] = "%10D";
		escape_map["Ď"] = "%10E";
		escape_map["ď"] = "%10F";
		escape_map["Đ"] = "%110";
		escape_map["đ"] = "%111";
		escape_map["Ē"] = "%112";
		escape_map["ē"] = "%113";
		escape_map["Ĕ"] = "%114";
		escape_map["ĕ"] = "%115";
		escape_map["Ė"] = "%116";
		escape_map["ė"] = "%117";
		escape_map["Ę"] = "%118";
		escape_map["ę"] = "%119";
		escape_map["Ě"] = "%11A";
		escape_map["ě"] = "%11B";
		escape_map["Ĝ"] = "%11C";
		escape_map["ĝ"] = "%11D";
		escape_map["Ğ"] = "%11E";
		escape_map["ğ"] = "%11F";
		escape_map["Ġ"] = "%120";
		escape_map["ġ"] = "%121";
		escape_map["Ģ"] = "%122";
		escape_map["ģ"] = "%123";
		escape_map["Ĥ"] = "%124";
		escape_map["ĥ"] = "%125";
		escape_map["Ħ"] = "%126";
		escape_map["ħ"] = "%127";
		escape_map["Ĩ"] = "%128";
		escape_map["ĩ"] = "%129";
		escape_map["Ī"] = "%12A";
		escape_map["ī"] = "%12B";
		escape_map["Ĭ"] = "%12C";
		escape_map["ĭ"] = "%12D";
		escape_map["Į"] = "%12E";
		escape_map["į"] = "%12F";
		escape_map["İ"] = "%130";
		escape_map["ı"] = "%131";
		escape_map["Ĳ"] = "%132";
		escape_map["ĳ"] = "%133";
		escape_map["Ĵ"] = "%134";
		escape_map["ĵ"] = "%135";
		escape_map["Ķ"] = "%136";
		escape_map["ķ"] = "%137";
		escape_map["ĸ"] = "%138";
		escape_map["Ĺ"] = "%139";
		escape_map["ĺ"] = "%13A";
		escape_map["Ļ"] = "%13B";
		escape_map["ļ"] = "%13C";
		escape_map["Ľ"] = "%13D";
		escape_map["ľ"] = "%13E";
		escape_map["Ŀ"] = "%13F";
		escape_map["ŀ"] = "%140";
		escape_map["Ł"] = "%141";
		escape_map["ł"] = "%142";
		escape_map["Ń"] = "%143";
		escape_map["ń"] = "%144";
		escape_map["Ņ"] = "%145";
		escape_map["ņ"] = "%146";
		escape_map["Ň"] = "%147";
		escape_map["ň"] = "%148";
		escape_map["ŉ"] = "%149";
		escape_map["Ŋ"] = "%14A";
		escape_map["ŋ"] = "%14B";
		escape_map["Ō"] = "%14C";
		escape_map["ō"] = "%14D";
		escape_map["Ŏ"] = "%14E";
		escape_map["ŏ"] = "%14F";
		escape_map["Ő"] = "%150";
		escape_map["ő"] = "%151";
		escape_map["Œ"] = "%152";
		escape_map["œ"] = "%153";
		escape_map["Ŕ"] = "%154";
		escape_map["ŕ"] = "%155";
		escape_map["Ŗ"] = "%156";
		escape_map["ŗ"] = "%157";
		escape_map["Ř"] = "%158";
		escape_map["ř"] = "%159";
		escape_map["Ś"] = "%15A";
		escape_map["ś"] = "%15B";
		escape_map["Ŝ"] = "%15C";
		escape_map["ŝ"] = "%15D";
		escape_map["Ş"] = "%15E";
		escape_map["ş"] = "%15F";
		escape_map["Š"] = "%160";
		escape_map["š"] = "%161";
		escape_map["Ţ"] = "%162";
		escape_map["ţ"] = "%163";
		escape_map["Ť"] = "%164";
		escape_map["ť"] = "%165";
		escape_map["Ŧ"] = "%166";
		escape_map["ŧ"] = "%167";
		escape_map["Ũ"] = "%168";
		escape_map["ũ"] = "%169";
		escape_map["Ū"] = "%16A";
		escape_map["ū"] = "%16B";
		escape_map["Ŭ"] = "%16C";
		escape_map["ŭ"] = "%16D";
		escape_map["Ů"] = "%16E";
		escape_map["ů"] = "%16F";
		escape_map["Ű"] = "%170";
		escape_map["ű"] = "%171";
		escape_map["Ų"] = "%172";
		escape_map["ų"] = "%173";
		escape_map["Ŵ"] = "%174";
		escape_map["ŵ"] = "%175";
		escape_map["Ŷ"] = "%176";
		escape_map["ŷ"] = "%177";
		escape_map["Ÿ"] = "%178";
		escape_map["Ź"] = "%179";
		escape_map["ź"] = "%17A";
		escape_map["Ż"] = "%17B";
		escape_map["ż"] = "%17C";
		escape_map["Ž"] = "%17D";
		escape_map["ž"] = "%17E";
		escape_map["ſ"] = "%17F";
		escape_map["Ŕ"] = "%154";
		escape_map["ŕ"] = "%155";
		escape_map["Ŗ"] = "%156";
		escape_map["ŗ"] = "%157";
		escape_map["Ř"] = "%158";
		escape_map["ř"] = "%159";
		escape_map["Ś"] = "%15A";
		escape_map["ś"] = "%15B";
		escape_map["Ŝ"] = "%15C";
		escape_map["ŝ"] = "%15D";
		escape_map["Ş"] = "%15E";
		escape_map["ş"] = "%15F";
		escape_map["Š"] = "%160";
		escape_map["š"] = "%161";
		escape_map["Ţ"] = "%162";
		escape_map["ţ"] = "%163";
		escape_map["Ť"] = "%164";
		escape_map["ť"] = "%241";
		escape_map["Ŧ"] = "%166";
		escape_map["ŧ"] = "%167";
		escape_map["Ũ"] = "%168";
		escape_map["ũ"] = "%169";
		escape_map["Ū"] = "%16A";
		escape_map["ū"] = "%16B";
		escape_map["Ŭ"] = "%16C";
		escape_map["ŭ"] = "%16D";
		escape_map["Ů"] = "%16E";
		escape_map["ů"] = "%16F";
		escape_map["Ű"] = "%170";
		escape_map["ű"] = "%171";
		escape_map["Ų"] = "%172";
		escape_map["ų"] = "%173";
		escape_map["Ŵ"] = "%174";
		escape_map["ŵ"] = "%175";
		escape_map["Ŷ"] = "%176";
		escape_map["ŷ"] = "%177";
		escape_map["Ÿ"] = "%178";
		escape_map["Ź"] = "%179";
		escape_map["ź"] = "%17A";
		escape_map["Ż"] = "%17B";
		escape_map["ż"] = "%17C";
		escape_map["Ž"] = "%17D";
		escape_map["ž"] = "%17E";
		escape_map["ſ"] = "%17F";

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
	}
}

