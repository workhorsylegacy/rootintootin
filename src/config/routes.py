
# FIXME: This needs to be simpler than rails, but allow for things like "http://localhost/titles/A. I. Artificial Intelligence"
routes = {'user' : { 'member' : { 'show' : 'get',
								'new' : 'get',
								'create' : 'post',
								'edit' : 'get',
								'update' : 'put',
								'destroy' : 'delete' }
					,
					'collection' : { 'index' : 'get' }
					}, 
		'comment' : { 'member' : { 'show' : 'get',
								'new' : 'get',
								'create' : 'post',
								'edit' : 'get',
								'update' : 'put',
								'destroy' : 'delete' }
					,
					'collection' : { 'index' : 'get' }
					}
		}

