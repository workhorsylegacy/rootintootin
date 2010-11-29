
private import tango.io.Stdout;
private import tango.io.device.File;
private import tango.text.json.Json;

private import language_helper;

int main(){
		Stdout(to_s(6.0f)).newline.flush;
		Stdout(to_s(6.7f)).newline.flush;

				auto a = new FixedPoint(99, 0, 2, 1);
				double i = 1;
				a += i;
				assert(a == 99.0);

	return 0;
}

