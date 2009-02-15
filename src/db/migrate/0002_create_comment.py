class CreateComment:
	def up(self):
		create_table('comments', {
			'body' : 'string', 
			'references' : 'user', 
		}) 
	def down(self):
		drop_table('comments')


