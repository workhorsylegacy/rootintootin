
class Create${pluralize(model_name.capitalize())}:
	def up(self, generator):
		generator.create_table('${pluralize(model_name)}', {
% for field in pairs:
<% field_name, field_type = field.split(':') %>\
			'${field_name}' : '${field_type}', 
% endfor 
		}) 
	def down(self, generator):
		generator.drop_table('${pluralize(model_name)}')


