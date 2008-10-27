

public class User : ModelBase {
	mixin ModelBaseMixin!(User, "user");

	public Field!(char[]) name = null;
	public Field!(bool) hide_email_address = null;

	public this() {
		name = new Field!(char[])("name");
		hide_email_address = new Field!(bool)("hide_email_address");
	}
}



