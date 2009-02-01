class CreateUsers:
	def up(self):
		create_table('users', {
			'name' : 'string',
			'email' : 'string'})

	def down(self):
		drop_table('users')
