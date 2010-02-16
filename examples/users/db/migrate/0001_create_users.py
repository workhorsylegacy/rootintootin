class CreateUsers:
	def up(self, generator):
		generator.create_table('users', {
			'name' : 'unique_string',
			'email' : 'unique_string'})

	def down(self, generator):
		generator.drop_table('users')
