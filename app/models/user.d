

public class User : ModelBase {
	mixin ModelBaseMixin!(User, "user");

	public Field!(string) name = null;
	public Field!(bool) hide_email_address = null;

	public this() {
		name = new Field!(string)("name");
		hide_email_address = new Field!(bool)("hide_email_address");
	}
}



