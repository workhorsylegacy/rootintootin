#!/usr/bin/env python
# -*- coding: UTF-8 -*-
#-------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-------------------------------------------------------------------------------

blacklist = ['this', 'super', 'return', 'is', 'ref', 'inout', 
			'if', 'else', 'elseif', 'not', 
			'select', 'switch', 'case', 'default', 'break', 
			'true', 'false', 'is', 
			'for', 'foreach', 'while', 'continue', 'goto', 'do', 
			'throw', 'raise', 'try', 'catch', 'finally', 'retry', 
			'synchronized', 'asm', 
			'function', 'delegate', 
			'new', 'delete', 'cast', 'typeof', 'sizeof', 'typeid', 
			'class', 'module', 'import', 'template', 'mixin', 'extern', 'interface', 
			'union', 'struct', 'enum', 
			'public', 'private', 'protected', 'package', 'export', 
			'static', 'final', 'override', 'const', 'align', 'deprecated', 
			'unittest', 'body', 'in', 'out', 'assert', 
			'short',  'ushort', 'int', 'uint',  'long', 'ulong', 'cent', 'ucent', 
			'float', 'ifloat', 'cfloat', 
			'double', 'idouble', 'cdouble', 
			'real', 'ireal', 'creal', 
			'char', 'wchar', 'dchar', 
			'version', 'ptrdiff_t', 'debug', 'abstract', 
			'byte', 'ubyte', 'bool', 'bit', 'size_t', 'void', 'null', 'volatile', 
			'alias', 'typedef', 'auto', 'var', 'val', 'scope', 'pragma', 'invariant', 
			'opneg', 'oppos', 'opcom', 'opstar', 'oppostInc', 'oppostdec', 'opcast', 
			'opadd', 'opsub', 'opmul', 'opdiv', 'opmod', 'oppow', 'opand', 
			'opor', 'opxor', 'opshl', 'opshr', 'opushr', 'opcat', 'opequals', 
			'opcmp', 'opassign', 'opaddassign', 'opsubassign', 'opmulassign', 
			'opdivassign', 'opmodassign', 'opandassign', 'oporassign', 
			'opxorassign', 'opshlassign', 'opshrassign', 'opushrassign', 
			'opcatassign', 'opin', 
			'typeinfo', 'switcherror', 'outofmemoryexception', 'object', 
			'moduleinfo', 'error', 'classinfo', 'arrayboundserror', 'asserterror', 
			'_d_throw', '_d_switch_ustring', '_d_switch_string', '_d_switch_dstring', 
			'_d_OutOfMemory', '_d_obj_eq', '_d_obj_cmp', '_d_newclass', '_d_newbitarray', 
			'_d_newarrayi', '_d_new', '_d_monitorrelease', '_d_monitor_prolog', 
			'_d_monitor_handler', '_d_monitorexit', '_d_monitor_epilog', '_d_monitorenter', 
			'_d_local_unwind', '_d_isbaseof2', '_d_isbaseof', '_d_invariant', 
			'_d_interface_vtbl', '_d_interface_cast', '_d_framehandler', 
			'_d_exception_filter', '_d_exception', '_d_dynamic_cast', '_d_delmemory', 
			'_d_delinterface', '_d_delclass', '_d_delarray', '_d_criticalexit', 
			'_d_criticalenter', '_d_create_exception_object', '_d_callfinalizer', 
			'_d_arraysetlengthb', '_d_arraysetlength', '_d_arraysetbit2', '_d_arraysetbit', 
			'_d_arraycopybit', '_d_arraycopy', '_d_arraycatn', '_d_arraycatb', 
			'_d_arraycat', '_d_arraycast_frombit', '_d_arraycast', '_d_arrayappendcb', 
			'_d_arrayappendc', '_d_arrayappendb', '_d_arrayappend', 
			'tango', 'array', 't', 'rootintootin' 'request', 'string']

