%%%-------------------------------------------------------------------
%%% @author Toby Leheup - TL258
%%% @copyright (C) 2014, <University of Kent>
%%% @doc
%%%
%%% @end
%%% Created : 28. Feb 2014 21:46
%%%-------------------------------------------------------------------
-module(test).
-author("Toby Leheup").

%% API
-compile([export_all]).

-type expr() ::
{'num', integer()}
|   {'var', atom()}
|   {'add', expr(), expr()}
|   {'mul', expr(), expr()}
|   {'sub', expr(), expr()}.

-type env() :: [{atom(), integer()}].

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

-spec highExpr1() -> string().
highExpr1() ->
	"((atom*0)+foo)".

-spec test1() -> integer().
test1() ->
	expr:eval(env1(), expr1()).

-spec test1alt() -> integer().
test1alt() ->
	expr:execute(env1(), expr1()).

-spec test2() -> integer().
test2() ->
	expr:eval(env1(), expr2()).

-spec test2alt() -> integer().
test2alt() ->
	expr:execute(env1(), expr2()).

-spec test3() -> integer().
test3() ->
	expr:eval(env2(), expr3()).

-spec test3alt() -> integer().
test3alt() ->
	expr:execute(env2(), expr3()).

-spec evalFuncs() -> [function()].
evalFuncs() ->
	[fun test1/0, fun test2/0, fun test3/0].

-spec executeFuncs() -> [function()].
executeFuncs() ->
	[fun test1alt/0, fun test2alt/0, fun test3alt/0].

-spec simplifyExprs() -> [string()].
simplifyExprs() ->
	["((atom*0)+foo)", "((atom*0)-9)", "((atom*1)+(foo+0))", "((atom-0)+(0+foo))"].

-spec simplestExprs() -> [string()].
simplestExprs() ->
	["foo", "(9*-1)", "(atom+foo)", "(atom+foo)"].

-spec operationsTest() -> ok.
operationsTest() ->
	Bool = operationTest(evalFuncs(), executeFuncs(), 1),
	io:format("Overall Test Success: ~w~n", [Bool]).

-spec operationTest([function()], [function()], integer()) -> boolean().
operationTest([Standard | StandardFuncs], [Alternate | AlternateFuncs], N) ->
	testResult(Standard, Alternate, N) andalso
	operationTest(StandardFuncs, AlternateFuncs, N + 1);
operationTest([], [], _) ->
	true.

-spec simplifyTest() -> ok.
simplifyTest() ->
	Bool = simplifyTest(simplifyExprs(), simplestExprs(), 1),
	io:format("Overall Test Success: ~w~n", [Bool]).

-spec simplifyTest([string()], [string()], integer()) -> boolean().
simplifyTest([Expr | Exprs], [Simplest | Simplests], N) ->
	{E1, _} = expr:parse(Expr),
	{E2, _} = expr:parse(Simplest),
	testSimplify(expr:simplify(E1), E2, N) andalso
	simplifyTest(Exprs, Simplests, N + 1);
simplifyTest([], [], _) ->
	true.

-spec same(_, _) -> boolean().
same(A, A) ->
	true;
same(_, _) ->
	false.

-spec testResult(function(), function(), integer()) -> boolean().
testResult(A, B, N) ->
	Bool = same(A(), B()),
	io:format("Test ~w = ~w is equal to ~w: ~w~n", [N, A, B, Bool]),
	Bool.

-spec testSimplify(string(), string(), integer()) -> boolean().
testSimplify(A, B, N) ->
	Bool = same(A, B),
	io:format("Test ~w = ~s is equal to ~s: ~w~n", [N, expr:print(A), expr:print(B), Bool]),
	Bool.

-spec check_Env_Test() -> boolean().
check_Env_Test() ->
	expr:env_check(env1(), expr1()) andalso
	expr:env_check(env1(), expr2()) andalso not
	expr:env_check(env1(), expr3()) andalso
		expr:env_check(env2(), expr3()) andalso not
		expr:env_check(env2(), expr2()).
