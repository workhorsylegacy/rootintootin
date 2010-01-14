
# FIXME: This needs to be simpler than rails, but allow for things like "http://localhost/titles/A. I. Artificial Intelligence"
routes = 	{'messages' : 
					{'index'  : {'/messages'        : 'GET'}, 
					 'create' : {'/messages'        : 'POST'}, 
					 'new'    : {'/messages/new'    : 'GET'}, 
					 'show'   : {'/messages/\d*'      : 'GET'}, 
					 'update' : {'/messages/\d*'      : 'PUT'}, 
					 'edit'   : {'/messages/\d*;edit' : 'GET'}, 
					 'destroy' : {'/messages/\d*'      : 'DELETE'}, 
					 'on_create' : {'/messages/\d*;on_create' : 'GET'}}
			}
