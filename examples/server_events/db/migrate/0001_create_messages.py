class CreateMessages:
	def up(self, generator):
		generator.create_table('messages', {
			'text' : 'string'})

	def down(self, generator):
		generator.drop_table('messages')
