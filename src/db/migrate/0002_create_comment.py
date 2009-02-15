class CreateComment:
	def up(self, generator):
		generator.create_table('comments', {
			'body' : 'string', 
			'references' : 'user', 
		}) 
	def down(self, generator):
		generator.drop_table('comments')


