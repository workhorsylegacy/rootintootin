
# FIXME: This needs to be simpler than rails, but allow for things like "http://localhost/titles/A. I. Artificial Intelligence"
routes = 	{'users' : 
					{'index'  : {'/users'        : 'get'}, 
					 'create' : {'/users'        : 'post'}, 
					 'new'    : {'/users/new'    : 'get'}, 
					 'show'   : {'/users/#'      : 'get'}, 
					 'update' : {'/users/#'      : 'put'}, 
					 'edit'   : {'/users/#;edit' : 'get'}, 
					 'create' : {'/users/#'      : 'delete'}}
			,'comments' : 
					{'index'  : {'/comments'        : 'get'}, 
					 'create' : {'/comments'        : 'post'}, 
					 'new'    : {'/comments/new'    : 'get'}, 
					 'show'   : {'/comments/#'      : 'get'}, 
					 'update' : {'/comments/#'      : 'put'}, 
					 'edit'   : {'/comments/#;edit' : 'get'}, 
					 'create' : {'/comments/#'      : 'delete'}}
			}

