%%%-------------------------------------------------------------------
%%% @author Toby Leheup - TL258 & Simon Thompson
%%% @copyright (C) 2014, <University of Kent>
%%% @doc
%%%
%%% @end
%%% Created : 28. Feb 2014 21:46
%%%-------------------------------------------------------------------
-module(expr).
-compile([export_all]).

%
% A suite of functions for handling arithmetical expressions
%

% Expressions are represented like this
%
%     {num, N}
%     {var, A}
%     {add, E1, E2}
%     {mul, E1, E2}
%     {sub, E1, E2}
%
% where N is a number, A is an atom,
% and E1, E2 are themselves expressions,

-type expr() ::
{'num', integer()}
|   {'var', atom()}
|   {'add', expr(), expr()}
|   {'mul', expr(), expr()}
|   {'sub', expr(), expr()}.

% For example,
%   {add,{var,a},{mul,{num,2},{var,b}}
% represents the mathematical expression
%   (a+(2*b))

%
% Printing
%

% Turn an expression into a string, so that
%   {add,{var,a},{mul,{num,2},{var,b}}
% is turned into
%   "(a+(2*b))"

% ADDED SUB

-spec print(expr()) -> string().

print({num, N}) ->
	integer_to_list(N);
print({var, A}) ->
	atom_to_list(A);
print({add, E1, E2}) ->
	"(" ++ print(E1) ++ "+" ++ print(E2) ++ ")";
print({mul, E1, E2}) ->
	"(" ++ print(E1) ++ "*" ++ print(E2) ++ ")";
print({sub, E1, E2}) ->
	"(" ++ print(E1) ++ "-" ++ print(E2) ++ ")".

%
% parsing
%

% recognise expressions
% deterministic, recursive descent, parser.

% the function returns two things
%   - an expression recognised at the beginning of the string
%     (in fact, the longers such expression)
%   - whatever of the string is left
%
% for example, parse("(-55*eeee)+1111)") is
%   {{mul,{num,-55},{var,eeee}} , "+1111)"}

% ADDED SUB

% recognise a fully-bracketed expression, with no spaces etc.

-spec parse(string()) -> {expr(), string()}.

parse([$( | Rest]) ->                            % starts with a '('
	{E1, Rest1} = parse(Rest),            % then an expression
	[Op | Rest2] = Rest1,                  % then an operator, '+' or '*'
	{E2, Rest3} = parse(Rest2),          % then another expression
	[$) | RestFinal] = Rest3,                  % starts with a ')'
	{case Op of
		 $+ -> {add, E1, E2};
		 $* -> {mul, E1, E2};
		 $- -> {sub, E1, E2}
	 end,
	 RestFinal};

% recognise an integer, a sequence of digits
% with an optional '-' sign at the start

parse([Ch | Rest]) when ($0 =< Ch andalso Ch =< $9) orelse Ch == $- ->
	{Succeeds, Remainder} = get_while(fun is_digit/1, Rest),
	{{num, list_to_integer([Ch | Succeeds])}, Remainder};

% recognise a variable: an atom built of small letters only.

parse([Ch | Rest]) when $a =< Ch andalso Ch =< $z ->
	{Succeeds, Remainder} = get_while(fun is_alpha/1, Rest),
	{{var, list_to_atom([Ch | Succeeds])}, Remainder}.

% auxiliary functions

% recognise a digit

-spec is_digit(integer()) -> boolean().

is_digit(Ch) ->
	$0 =< Ch andalso Ch =< $9.

% recognise a small letter

-spec is_alpha(integer()) -> boolean().

is_alpha(Ch) ->
	$a =< Ch andalso Ch =< $z.

% the longest initial segment of a list in which all
% elements have property P. Used in parsing integers
% and variables

-spec get_while(fun((T) -> boolean()), [T]) -> {[T], [T]}.
%-spec get_while(fun((T) -> boolean()),[T]) -> [T].

get_while(P, [Ch | Rest]) ->
	case P(Ch) of
		true ->
			{Succeeds, Remainder} = get_while(P, Rest),
			{[Ch | Succeeds], Remainder};
		false ->
			{[], [Ch | Rest]}
	end;
get_while(_P, []) ->
	{[], []}.

%
% Evaluate an expression
%

% First version commented out.

% eval({num,N}) ->
%     N;
% eval({add,E1,E2}) ->
%     eval(E1) + eval(E2);
% eval({mul,E1,E2}) ->
%     eval(E1) * eval(E2).

% ADDED SUB

-type env() :: [{atom(), integer()}].

-spec eval(env(), expr()) -> integer().

eval(_Env, {num, N}) ->
	N;
eval(Env, {var, A}) ->
	lookup(A, Env);
eval(Env, {add, E1, E2}) ->
	eval(Env, E1) + eval(Env, E2);
eval(Env, {mul, E1, E2}) ->
	eval(Env, E1) * eval(Env, E2);
eval(Env, {sub, E1, E2}) ->
	eval(Env, E1) - eval(Env, E2).

%
% Compiler and virtual machine
%

% Instructions
%    {push, N} - push integer N onto the stack
%    {fetch, A} - lookup value of variable a and push the result onto the stack
%    {add2} - pop the top two elements of the stack, add, and push the result
%    {mul2} - pop the top two elements of the stack, multiply, and push the result

-type instr() :: {'push', integer()}
|  {'fetch', atom()}
|  {'add2'}
|  {'mul2'}
|  {'sub2'}.

-type program() :: [instr()].

% compiler

-spec compile(expr()) -> program().

% ADDED SUB

compile({num, N}) ->
	[{push, N}];
compile({var, A}) ->
	[{fetch, A}];
compile({add, E1, E2}) ->
	compile(E1) ++ compile(E2) ++ [{add2}];
compile({mul, E1, E2}) ->
	compile(E1) ++ compile(E2) ++ [{mul2}];
compile({sub, E1, E2}) ->
	compile(E1) ++ compile(E2) ++ [{sub2}].

% run a code sequence in given environment and empty stack

-spec run(program(), env()) -> integer().

run(Code, Env) ->
	run(Code, Env, []).

% execute an instruction, and when the code is exhausted,
% return the top of the stack as result.
% classic tail recursion

% ADDED SUB

-type stack() :: [integer()].

-spec run(program(), env(), stack()) -> integer().

run([{push, N} | Continue], Env, Stack) ->
	run(Continue, Env, [N | Stack]);
run([{fetch, A} | Continue], Env, Stack) ->
	run(Continue, Env, [lookup(A, Env) | Stack]);
run([{add2} | Continue], Env, [N1, N2 | Stack]) ->
	run(Continue, Env, [(N1 + N2) | Stack]);
run([{mul2} | Continue], Env, [N1, N2 | Stack]) ->
	run(Continue, Env, [(N1 * N2) | Stack]);
run([{sub2} | Continue], Env, [N1, N2 | Stack]) ->
	run(Continue, Env, [(N2 - N1) | Stack]);
run([], _Env, [N]) ->
	N.

% compile and run ...
% should be identical to eval(Env,Expr)

-spec execute(env(), expr()) -> integer().

execute(Env, Expr) ->
	run(compile(Expr), Env).

%
% Simplify an expression
%

% first version commented out

% simplify({add,E1,{num,0}}) ->
%     E1;
% simplify({add,{num,0},E2}) ->
%     E2;
% simplify({mul,E1,{num,1}}) ->
%     E1;
% simplify({mul,{num,1},E2}) ->
%     E2;
% simplify({mul,_,{num,0}}) ->
%     {num,0};
% simplify({mul,{num,0},_}) ->
%     {num,0}.

% second version commented out

% simplify({add,E1,{num,0}}) ->
%     simplify(E1);
% simplify({add,{num,0},E2}) ->
%     simplify(E2);
% simplify({mul,E1,{num,1}}) ->
%     simplify(E1);
% simplify({mul,{num,1},E2}) ->
%     simplify(E2);
% simplify({mul,_,{num,0}}) ->
%     {num,0};
% simplify({mul,{num,0},_}) ->
%     {num,0};
% simplify(E) ->
%     E.

% This simplify is refactored to accommodate sub AND simplifies everything to it's simplest possible form
% It does this using recursion
% Try and break something down twice. If the second time was successful, keep the latest version and keep going
% Otherwise, return what you got
-spec simplify(expr()) -> expr().
simplify(Exp) ->
	Simp1 = breakdown(Exp),
	Simp2 = breakdown(Simp1),
	case Simp1 == Simp2 of
 		true -> Simp1;
 		false -> simplify(Simp2)
 	end.

% breakdown is a function which works with simplify. It reevaluates certain expressions to be their simpler brothers
% It accomodates sub
-spec breakdown(expr()) -> expr().
breakdown({add, E1, {num, 0}}) ->
	breakdown(E1);
breakdown({add, {num, 0}, E2}) ->
	breakdown(E2);
breakdown({sub, E1, {num, 0}}) ->
	breakdown(E1);
breakdown({sub, {num, 0}, E2}) ->
	breakdown({mul, E2, {num, -1}});
breakdown({mul, E1, {num, 1}}) ->
	breakdown(E1);
breakdown({mul, {num, 1}, E2}) ->
	breakdown(E2);
breakdown({mul, _, {num, 0}}) ->
	{num, 0};
breakdown({mul, {num, 0}, _}) ->
	{num, 0};
breakdown({add, E1, E2}) ->
	{add, breakdown(E1), breakdown(E2)};
breakdown({mul, E1, E2}) ->
	{mul, breakdown(E1), breakdown(E2)};
breakdown({sub, E1, E2}) ->
	{sub, breakdown(E1), breakdown(E2)};
breakdown(E) ->
	E.

% env_check is a function that checks that an environment has all the variables required to do complete the function
-spec env_check(env(),expr()) -> boolean().
env_check(Env, Expression) ->
	TestList = getVariables(Expression),
	subsetCheck(TestList, envToVarList(Env)).

% getVariables takes an expression and returns the list of variables that makes up the expression
-spec getVariables(expr()) -> [{atom(), atom()}].
getVariables({var, Var}) ->
	[{var, Var}];
getVariables({num, _}) ->
	[];
getVariables({_, E1, E2}) ->
	getVariables(E1) ++ getVariables(E2).

% subset check checks to see if the first list is a subset of the second list
% Uses the lists library module
-spec subsetCheck([{atom(), atom()}], [{atom(), atom()}]) -> boolean().
subsetCheck([Elem|Elems], List) ->
	lists:member(Elem, List) andalso subsetCheck(Elems, List);
subsetCheck([], _) ->
	true.

% envToVarList takes an environment and converts it to the same representation as an expression is parsed to
% Makes subset checking much easier
-spec envToVarList(env()) -> [{var, atom()}].
envToVarList(Env) ->
	envToVarList(Env, []).

% Tail recursive solution of above
-spec envToVarList(env(), [{var, atom()}]) -> [{var, atom()}].
envToVarList([{Var, _}|Variables], List) ->
	envToVarList(Variables, [{var, Var}|List]);
envToVarList([], List) ->
	List.


% Auxiliary function: lookup a
% key in a list of key-value pairs.
% Fails if the key not present.

-spec lookup(atom(), env()) -> integer().

lookup(A, [{A, V} | _]) ->
	V;
lookup(A, [_ | Rest]) ->
	lookup(A, Rest).

% Test data.

-spec env1() -> env().
env1() ->
	[{a, 23}, {b, -12}].

-spec env2() -> env().
env2() ->
	[{myvar, 16}].

-spec expr1() -> expr().
expr1() ->
	{add, {var, a}, {mul, {num, 2}, {var, b}}}.

-spec expr2() -> expr().
expr2() ->
	{add, {mul, {num, 1}, {var, b}}, {mul, {add, {mul, {num, 2}, {var, b}}, {mul, {num, 1}, {var, b}}}, {num, 0}}}.

-spec expr3() -> expr().
expr3() ->
	{sub,
	 {mul,
	  {add, {num, 1}, {num, 4}},
	  {mul, {num, 4}, {num, 9}}
	 },
	 {mul,
	  {sub, {num, 2}, {num, 0}},
	  {var, myvar}
	 }
	}.

-spec test1() -> integer().
test1() ->
	eval(env1(), expr1()).

-spec test2() -> integer().
test2() ->
	eval(env1(), expr2()).

-spec test3() -> integer().
test3() ->
	eval(env2(), expr3()).