/*************************************************************************
*									 *
*	 YAP Prolog 							 *
*									 *
*	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
*									 *
* Copyright L.Damas, V.S.Costa and Universidade do Porto 1985-1997	 *
*									 *
**************************************************************************
*									 *
* File:		newmod.pl						 *
* Last rev:								 *
* mods:									 *
* comments:     support	for new modules.					 *
*									 *
*************************************************************************/
/**

  @file newmod.yap
  @short support for creating a new module.

  @ingroup ModuleBuiltins
  @pred module(+M) is det
   set the type-in module


Defines  _M_ to be the current working or type-in module. All files
which are not bound to a module are assumed to belong to the working
module (also referred to as type-in module). To compile a non-module
file into a module which is not the working one, prefix the file name
with the module name, in the form ` _Module_: _File_`, when
loading the file.

**/
module(N) :-
	var(N),
	'$do_error'(instantiation_error,module(N)).
module(N) :-
	atom(N), !,
	% set it as current module.
	'$current_module'(_,N).
module(N) :-
	'$do_error'(type_error(atom,N),module(N)).

/**
 \pred	module(+ Module:atom, +ExportList:list) is directive

  @brief define a new module

This directive defines the file where it appears as a _module file_;
it must be the first declaration in the file.  _Module_ must be an
atom specifying the module name; _ExportList_ must be a list
containing the module's public predicates specification, in the form
`[predicate_name/arity,...]`. The _ExportList_ can  include
operator declarations for operators that are exported by the module.

The public predicates of a module file can be made accessible to other
files through loading the source file, using the directives
use_module/1 or use_module/2,
ensure_loaded/1 and the predicates
consult/1 or reconsult/1. The
non-public predicates of a module file are not supposed to be visible
to other modules; they can, however, be accessed by prefixing the module
name with the `:/2` operator.


'$module_dec'(_,system(N, Ss), Ps) :- !,
		new_system_module(N),
    '$mk_system_predicates'( Ss , N ),
    '$module_dec'(prolog,N, Ps).
'$module_dec'(_,system(N), Ps) :- !,
		new_system_module(N),
%    '$mk_system_predicates'( Ps , N ),
    '$module_dec'(prolog,N, Ps).
**/
'$declare_module'(_, HostM, DonorM, Ps, _Ops) :-
    source_location(F,Line),
	('__NB_getval__'( '$user_source_file', F0 , fail)
	->
	    true
	;
	    F0 = F
	),
    
    '$add_module_on_file'(DonorM, F, HostM, Ps, Line),
    current_source_module(HostM,DonorM).


'$mk_system_predicates'( Ps, _N ) :-
    '$memberchk'(Name/A , Ps),
    '$new_system_predicate'(Name, A, prolog),
    fail.
'$mk_system_predicates'( _Ps, _N ).

/*
declare_module(Mod) -->
	arguments(file(+file:F),
		  line(+integer:L),
		  parent(+module:P),
		  type(+module_type:T),
		  exports(+list(exports):E),

		  Props, P0) -> true ; Props = P0),
	( deleteline(L), P0, P1) -> true ; P0 == P1),
	( delete(parent(P), P1, P2) -> true ; P1 == P2),
	( delete(line(L), P2, P3) -> true ; P3 == P4),
	( delete(file(F), Props, P0) -> true ; Props = P0),
	( delete(file(F), Props, P0) -> true ; Props = P0),
	( delete(file(F), Props, P0) -> true ; Props = P0),
	de
*/
'$module'(_,N,P) :-
	current_source_module(M,M),
	'$declare_module'(_,M,N,P,[]).

/** set_module_property( +Mod, +Prop)

   Set a property for a module. Currently this includes:
     - base module, a module from where we automatically import all definitions, see add_import_module/2.
	 - the export list
	 - module class is currently ignored.
*/
set_module_property(Mod, base(Base)) :-
	must_be_of_type( module, Mod),
	add_import_module(Mod, Base, start).
set_module_property(Mod, exports(Exports)) :-
	must_be_of_type( module, Mod),
	current_source_module(OMod,OMod),
	'$add_module_on_file'(Mod, user_input, OMod, Exports, 1).
set_module_property(Mod, exports(Exports, File, Line)) :-
	current_source_module(OMod,OMod),
	must_be_of_type( module, Mod),
	'$add_module_on_file'(Mod, File, OMod, Exports, Line).
set_module_property(Mod, class(Class)) :-
	must_be_of_type( module, Mod),
	must_be_of_type( atom, Class).

'$add_module_on_file'( DonorM, DonorF, _HostM, Exports, _LineF) :-
    '$module'(OtherF, DonorM, OExports, _),
    % the module has been found, are we reconsulting?
    (
	DonorF \= OtherF
	->
	'$do_error'(permission_error(module,redefined,DonorM, OtherF, DonorF),module(DonorM,Exports) )
    ;
    OExports == Exports
    ->
    !
    ;
    unload_module(DonorM),
    fail
    ).
'$add_module_on_file'( DonorM, DonorF0, _, Exports, Line) :-
    (DonorM= prolog -> DonorF = user_input ;
     DonorM= user -> DonorF = user_input ;
     DonorF0 = DonorF),
    '$sort'( Exports, AllExports ),
    % last, export to the host.
    asserta('$module'(DonorF,DonorM, AllExports, Line)),
    '$operators'(Exports,DonorM),
   (
       recorded('$source_file','$source_file'( DonorF, Time), R), erase(R),
       fail
   ;
   recorda('$source_file','$source_file'( DonorF, Time), _) 
	).

'$operators'([],_).
'$operators'([op(A,B,C)|AllExports0], DonorM) :-
    op(A,B,DonorM:C),
    !,
    '$operators'(AllExports0, DonorM).
'$operators'([_|AllExports0], DonorM) :-
    '$operators'(AllExports0, DonorM).

/**

@defgroup ModPreds Module Interface Predicates
@ingroup YAPModules


  @{

**/


'$export_preds'([]).
'$export_preds'([N/A|Decls]) :-
    functor(S, N, A),
    '$sys_export'(S, prolog),
    '$export_preds'(Decls).

/**

  @pred reexport(+F) is directive
  @pred reexport(+F, +Decls ) is directive
  allow a module to use and export predicates from another module

Export all predicates defined in list  _F_ as if they were defined in
the current module.

Export predicates defined in file  _F_ according to  _Decls_. The
declarations should be of the form:

<ul>
    A list of predicate declarations to be exported. Each declaration
may be a predicate indicator or of the form `` _PI_ `as`
 _NewName_'', meaning that the predicate with indicator  _PI_ is
to be exported under name  _NewName_.

    `except`( _List_)
In this case, all predicates not in  _List_ are exported. Moreover,
if ` _PI_ `as`  _NewName_` is found, the predicate with
indicator  _PI_ is to be exported under name  _NewName_ as
before.


Re-exporting predicates must be used with some care. Please, take into
account the following observations:

<ul>
  + The `reexport` declarations must be the first declarations to
  follow the `module` declaration.  </li>

  + It is possible to use both `reexport` and `use_module`, but all
  predicates reexported are automatically available for use in the
  current module.

  + In order to obtain efficient execution, YAP compiles
  dependencies between re-exported predicates. In practice, this means
  that changing a `reexport` declaration and then *just* recompiling
  the file may result in incorrect execution.

*/
'$reexport'(M, M ) :-
    !.
'$reexport'(HostM, DonorM ) :-
%        writeln(r0:DonorM/HostM),
    ( retract('$module'( HostF, HostM, AllExports, Line)) -> true ; HostF = user_input,AllExports=[] ,Line=1),
    (
	'$module'( _DonorF, DonorM, AllReExports, _Line) -> true ; AllReExports=[] ),
    '$append'( AllReExports, AllExports, Everything0 ),
    '$sort'( Everything0, Everything ),
    '$operators'(AllReExports, HostM),
    %    writeln(r:DonorM/HostM),
    asserta('$module'(HostF,HostM, Everything, Line)).



/**
@}
**/

/**
 
This predicate actually exports _Module to the _ContextModule_.
 _Imports is what the ContextModule needed.																			
*/

'$import_module'(DonorM, HostM, F, _Opts) :-
    DonorM ==  HostM,
    !,
    (
	'$source_file_scope'( F, M)
    ->
    true;
	assert('$source_file_scope'( F, M) )
    ).
'$import_module'(DonorM, HostM, File, _Opts) :-
    \+
	'$module'(File, DonorM, _ModExports, _),                                                                 
	% enable loading C-predicates from a different file
	recorded( '$load_foreign_done', [File, DonorM], _),
	'$import_foreign'(File, DonorM, HostM ),
	fail.
'$import_module'(DonorM, HostM,File, Opts) :-
    DonorM \= HostM,
    '$module'(File, DonorM, Exports, _),
    ignore('$member'(imports(Imports),Opts)),
    '$convert_for_export'(Imports, Exports, DonorM, HostM, Tab, _),
    '$add_to_imports'(Tab, DonorM, HostM),
    (     '$memberchk'(reexport(true),Opts)
    ->
    '$reexport'(HostM, DonorM )
    ;
    true
    ),
    !.
'$import_module'(_, _, _, _).



	
'$convert_for_export'(All, Exports, _Module, _ContextModule, Tab, MyExports) :-
    var(All),
    !,
    '$simple_conversion'(Exports, Tab, MyExports).
'$convert_for_export'(all, Exports, _Module, _ContextModule, Tab, MyExports) :-
	'$simple_conversion'(Exports, Tab, MyExports).
'$convert_for_export'([], Exports, Module, ContextModule, Tab, MyExports) :-
	'$clean_conversion'([], Exports, Module, ContextModule, Tab, MyExports, _Goal).
'$convert_for_export'([P1|Ps], Exports, Module, ContextModule, Tab, MyExports) :-
	'$clean_conversion'([P1|Ps], Exports, Module, ContextModule, Tab, MyExports, _Goal).
'$convert_for_export'(except(Excepts), Exports, DonorM, HostM, Tab, MyExports) :-
	'$neg_conversion'(Excepts, Exports, DonorM, HostM, MyExports, _Goal),
	'$simple_conversion'(MyExports, Tab, _).

'$simple_conversion'([], [], []).
'$simple_conversion'([F/N|Exports], [F/N-F/N|Tab], [F/N|E]) :-
    '$simple_conversion'(Exports, Tab, E).
'$simple_conversion'([F//N|Exports], [F/N2-F/N2|Tab], [F/N2|E]) :-
    N2 is N+1,
    '$simple_conversion'(Exports, Tab, E).
'$simple_conversion'([F/N as NF|Exports], [F/N-NF/N|Tab], [NF/N|E]) :-
    '$simple_conversion'(Exports, Tab, E).
'$simple_conversion'([F//N as NF|Exports], [F/N2-NF/N2|Tab], [NF/N2|E]) :-
    N2 is N+1,
    '$simple_conversion'(Exports, Tab, E).
'$simple_conversion'([op(Prio,Assoc,Name)|Exports], [op(Prio,Assoc,Name)|Tab], [op(Prio,Assoc,Name)|E]) :-
    '$simple_conversion'(Exports, Tab, E).

'$clean_conversion'([], _, _, _, [], [], _).
'$clean_conversion'([(N1/A1 as N2)|Ps], List, Module, ContextModule, [N1/A1-N2/A1|Tab], [N2/A1|MyExports], Goal) :- !,
    ( '$memberchk'(N1/A1, List)
    ->
    true
    ;
    '$bad_export'((N1/A1 as N2), Module, ContextModule)
    ),
    '$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).
'$clean_conversion'([N1/A1|Ps], List, Module, ContextModule, [N1/A1-N1/A1|Tab], [N1/A1|MyExports], Goal) :- !,
          	(
          	 '$memberchk'(N1/A1, List)
          	->
          	   true
          	;
          	  '$bad_export'(N1/A1, Module, ContextModule)
          	),
          	'$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).
          '$clean_conversion'([N1//A1|Ps], List, Module, ContextModule, [N1/A2-N1/A2|Tab], [N1/A2|MyExports], Goal) :- !,
          	A2 is A1+2,
          	(
          	  '$memberchk'(N1/A2, List)
          	->
          	  true
          	;
          	  '$bad_export'(N1//A1, Module, ContextModule)

          	),
          	'$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).
          '$clean_conversion'([N1//A1 as N2|Ps], List, Module, ContextModule, [N2/A2-N1/A2|Tab], [N2/A2|MyExports], Goal) :- !,
          	A2 is A1+2,
          	(
          	  '$memberchk'(N2/A2, List)
          	->
          	  true
          	;
          	  '$bad_export'((N1//A1 as A2), Module, ContextModule)
          	),
          	'$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).
          '$clean_conversion'([op(Prio,Assoc,Name)|Ps], List, Module, ContextModule, [op(Prio,Assoc,Name)|Tab], [op(Prio,Assoc,Name)|MyExports], Goal) :- !,
          	(
          	 '$memberchk'(op(Prio,Assoc,Name), List)
          	->
          	 true
          	;
          	 '$bad_export'(op(Prio,Assoc,Name), Module, ContextModule)
          	),
          	'$clean_conversion'(Ps, List, Module, ContextModule, Tab, MyExports, Goal).
          '$clean_conversion'([P|_], _List, _, _, _, _, Goal) :-
          	'$do_error'(domain_error(module_export_predicates,P), Goal).

          '$bad_export'(_, _Module, _ContextModule) :- !.
          '$bad_export'(Name/Arity, Module, ContextModule) :-
          	functor(P, Name, Arity),
          	predicate_property(Module:P, _), !,
          	print_message(warning, declaration(Name/Arity, Module, ContextModule, private)).
          '$bad_export'(Name//Arity, Module, ContextModule) :-
          	Arity2 is Arity+2,
          	functor(P, Name, Arity2),
          	predicate_property(Module:P, _), !,
          	print_message(warning, declaration(Name/Arity, Module, ContextModule, private)).
          '$bad_export'(Indicator, Module, ContextModule) :- !,
          	print_message(warning, declaration( Indicator, Module, ContextModule, undefined)).

          '$neg_conversion'([], Exports, _, _, Exports, _).
          '$neg_conversion'([N1/A1|Ps], List, Module, ContextModule, MyExports, Goal) :- !,
          	(
          	 '$delete'(List, N1/A1, RList)
          	->
          	 '$neg_conversion'(Ps, RList, Module, ContextModule, MyExports, Goal)
          	;
          	 '$bad_export'(N1/A1, Module, ContextModule)
          	).
          '$neg_conversion'([N1//A1|Ps], List, Module, ContextModule, MyExports, Goal) :- !,
          	A2 is A1+2,
          	(
          	 '$delete'(List, N1/A2, RList)
          	->
          	 '$neg_conversion'(Ps, RList, Module, ContextModule, MyExports, Goal)
          	;
          	 '$bad_export'(N1//A1, Module, ContextModule)
          	).
          '$neg_conversion'([op(Prio,Assoc,Name)|Ps], List, Module, ContextModule, MyExports, Goal) :- !,
          	(
          	 '$delete'(List, op(Prio,Assoc,Name), RList)
          	->
          	 '$neg_conversion'(Ps, RList, Module, ContextModule, MyExports, Goal)
          	;
          	 '$bad_export'(op(Prio,Assoc,Name), Module, ContextModule)
          	).
          '$clean_conversion'([P|_], _List, _, _, _, Goal) :-
          	'$do_error'(domain_error(module_export_predicates,P), Goal).

