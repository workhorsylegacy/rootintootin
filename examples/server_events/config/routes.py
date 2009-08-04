
# FIXME: This needs to be simpler than rails, but allow for things like "http://localhost/titles/A. I. Artificial Intelligence"
routes = {'message' : { 'member' : { 'show' : 'get',
								'new' : 'get',
								'create' : 'post',
								'edit' : 'get',
								'update' : 'put',
								'destroy' : 'delete',
								'on_create' : 'get' }
					,
					'collection' : { 'index' : 'get' }
					}
		}

'''

# the browser's js will look like this
set_server_event('message', {'on_create'}, function(id, text) {  });

'''
