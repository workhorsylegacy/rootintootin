
# FIXME: This needs to be simpler than rails, but allow for things like "http://localhost/titles/A. I. Artificial Intelligence"
routes = 	{'files' : 
					{'index'  : {'/files'        : 'get'}, 
					 'create' : {'/files'        : 'post'}, 
					 'new'    : {'/files/new'    : 'get'}, 
					 'show'   : {'/files/#'      : 'get'}, 
					 'update' : {'/files/#'      : 'put'}, 
					 'edit'   : {'/files/#;edit' : 'get'}, 
					 'create' : {'/files/#'      : 'delete'}}
			}
