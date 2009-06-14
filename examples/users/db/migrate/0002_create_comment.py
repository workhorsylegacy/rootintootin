class CreateComment:
	def up(self, generator):
		generator.create_table('comments', {
			'value' : 'string', 
			'user' : 'reference', 
		}) 
	def down(self, generator):
		generator.drop_table('comments')


