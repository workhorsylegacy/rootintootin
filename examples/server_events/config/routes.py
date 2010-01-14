
# FIXME: This needs to be simpler than rails, but allow for things like "http://localhost/titles/A. I. Artificial Intelligence"
routes = 	{'messages' : 
					{'index'     : {'/messages'             : 'get'}, 
					 'create'    : {'/messages'             : 'post'}, 
					 'new'       : {'/messages/new'         : 'get'}, 
					 'show'      : {'/messages/#'           : 'get'}, 
					 'update'    : {'/messages/#'           : 'put'}, 
					 'edit'      : {'/messages/#;edit'      : 'get'}, 
					 'create'    : {'/messages/#'           : 'delete'}}, 
					 'on_create' : {'/messages/#;on_create' : 'get'}
			}
