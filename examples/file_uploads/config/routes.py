
# FIXME: This needs to be simpler than rails, but allow for things like "http://localhost/titles/A. I. Artificial Intelligence"
routes = 	{'files' : 
					{'index'  : {'/files'        : 'GET'}, 
					 'create' : {'/files'        : 'POST'}, 
					 'new'    : {'/files/new'    : 'GET'}, 
					 'show'   : {'/files/\d*'      : 'GET'}, 
					 'update' : {'/files/\d*'      : 'PUT'}, 
					 'edit'   : {'/files/\d*;edit' : 'GET'}, 
					 'destroy' : {'/files/\d*'      : 'DELETE'}}
			}
