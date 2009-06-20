class CreateFiles:
	def up(self, generator):
		generator.create_table('files', {
			'name' : 'string'})

	def down(self, generator):
		generator.drop_table('files')
