class CreateUsers:
	def up(self, generator):
		generator.create_table('users', {
			'name' : 'string',
			'email' : 'string'})

	def down(self, generator):
		generator.drop_table('users')
