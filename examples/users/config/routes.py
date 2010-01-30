
routes = 	{'users' : 
					{'index'  : {'^/users$'        : 'GET'}, 
					 'create' : {'^/users$'        : 'POST'}, 
					 'new'    : {'^/users/new$'    : 'GET'}, 
					 'show'   : {'^/users/\d+$'      : 'GET'}, 
					 'update' : {'^/users/\d+$'      : 'PUT'}, 
					 'edit'   : {'^/users/\d+;edit$' : 'GET'}, 
					 'destroy' : {'^/users/\d+$'      : 'DELETE'}}
			,'comments' : 
					{'index'  : {'^/comments$'        : 'GET'}, 
					 'create' : {'^/comments$'        : 'POST'}, 
					 'new'    : {'^/comments/new$'    : 'GET'}, 
					 'show'   : {'^/comments/\d+$'      : 'GET'}, 
					 'update' : {'^/comments/\d+$'      : 'PUT'}, 
					 'edit'   : {'^/comments/\d+;edit$' : 'GET'}, 
					 'destroy' : {'^/comments/\d+$'      : 'DELETE'}}
			}

