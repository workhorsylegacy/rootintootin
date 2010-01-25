
import tango.io.Stdout;
import tango.math.Math;
import language_helper;

public double pow(double x, int n) {
	return tango.math.Math.pow(cast(real) x, n);
}

public int pow(int x, int n) {
	return cast(int) tango.math.Math.pow(cast(real) x, n);
}

public int pow(int x, uint n) {
	return cast(int) tango.math.Math.pow(cast(real) x, n);
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
		Stdout.format("##{}\n", a).flush;
		Stdout.format("##{}\n", floor(a)).flush;
		Stdout.format("##{}\n", ((a - floor(a)) * pow(10, _precision))).flush;
		//_before_point = cast(uint) floor(a);
		//_after_point = cast(uint) ((a - floor(a)) * pow(10, _precision));
		///*
		uint before = cast(uint) floor(a);
		uint after = cast(uint) ((a - floor(a)) * pow(10, _precision));
		auto other = new FixedPoint(before, after, this.precision);
		this += other;
		//*/
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
		float f = 2.1;
		a += f;
		assert(a == 74.03, a.toString ~ " != 74.03");

		// Test += float with round
		float g = 1.99;
		a += g;
		assert(a == 75.02, a.toString ~ " != 75.02");

		// Test += double
		double h = 1.1;
		a += h;
		assert(a == 74.04, a.toString ~ " != 74.04");
	}
}

void main(){

}

