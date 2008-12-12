class CreateUsers:
	def up(self):
		create_table('users', {
			'name' : 'string',
			'user_name' : 'string',
			'hashed_password' : 'string',
			'salt' : 'string',
			'time_zone' : 'string',
			'year_of_birth' : 'string',
			'gender' : 'string',
			'email' : 'string',
			'avatar_file' : 'string',
			'user_type' : 'string'})

	def down(self):
		drop_table('users')
