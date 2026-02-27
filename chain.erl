%% chain.erl
%% Team: Sanjana Nalla, Tejaswi Paladugu, Vedant Chanshetty
-module(chain).
-export([start/0, serv1/1, serv2/1, serv3/1]).

start() ->
    Serv3 = spawn(chain, serv3, [0]),
    Serv2 = spawn(chain, serv2, [Serv3]),
    Serv1 = spawn(chain, serv1, [Serv2]),

    io:format("Type a message for serv1 (or 'all_done' to stop):~n"),
    handle_user_input(Serv1).

handle_user_input(Serv1) ->
    io:format("> "),
    UserInput = io:get_line(""),
    TrimmedInput = string:trim(UserInput),

    case TrimmedInput of
        "all_done" ->
            io:format("Exiting program...~n"),
            ok;
        _ ->
            case parse_input(TrimmedInput) of
                {error, _Reason} ->
                    io:format("Error: Invalid input format. Try again.~n"),
                    handle_user_input(Serv1);
                Msg ->
                    Serv1 ! Msg,
                    handle_user_input(Serv1)
            end
    end.

parse_input(Input) ->
    case erl_scan:string(Input) of
        {ok, Tokens, _} ->
            case erl_parse:parse_exprs(Tokens) of
                {ok, [ParsedTerm]} ->
                    {value, Term, _} = erl_eval:expr(ParsedTerm, []),
                    Term;
                _ -> {error, parse_error}
            end;
        _ -> {error, scan_error}
    end.

serv1(NextServer) ->
    receive
        {Op, A, B} when Op =:= 'add'; Op =:= 'sub'; Op =:= 'mult'; Op =:= 'div' ->
            if
                is_number(A) andalso is_number(B) ->
                    Result = case Op of
                        'add' -> A + B;
                        'sub' -> A - B;
                        'mult' -> A * B;
                        'div' -> A / B
                    end,
                    io:format("(serv1) ~p: ~p ~p ~p = ~p~n", [Op, A, Op, B, Result]);
                true ->
                    NextServer ! {Op, A, B}
            end,
            serv1(NextServer);
        {Op, A} when Op =:= 'neg'; Op =:= 'sqrt' ->
            if
                is_number(A) ->
                    Result = case Op of
                        'neg' -> -A;
                        'sqrt' -> math:sqrt(A)
                    end,
                    io:format("(serv1) ~p: ~p(~p) = ~p~n", [Op, Op, A, Result]);
                true ->
                    NextServer ! {Op, A}
            end,
            serv1(NextServer);
        halt ->
            NextServer ! halt,
            io:format("(serv1) Halting...~n");
        Other ->
            NextServer ! Other,
            serv1(NextServer)
    end.

serv2(NextServer) ->
    receive
        [Head | Tail] when is_number(Head) ->
            case is_integer(Head) of
                true ->
                    Sum = lists:sum([X || X <- [Head | Tail], is_number(X)]),
                    io:format("(serv2) Sum of elements = ~p~n", [Sum]);
                false ->
                    Product = lists:foldl(fun(X, Acc) when is_number(X) -> X * Acc; (_, Acc) -> Acc end, 1, [Head | Tail]),
                    io:format("(serv2) Product of elements = ~p~n", [Product])
            end,
            serv2(NextServer);
        halt ->
            NextServer ! halt,
            io:format("(serv2) Halting...~n");
        Other ->
            NextServer ! Other,
            serv2(NextServer)
    end.

serv3(UnhandledCount) ->
    receive
        {error, Reason} ->
            io:format("(serv3) Error: ~p~n", [Reason]),
            serv3(UnhandledCount);
        halt ->
            io:format("(serv3) Halting... Unhandled message count = ~p~n", [UnhandledCount]),
            ok;
        Other ->
            io:format("(serv3) Not handled: ~p~n", [Other]),
            serv3(UnhandledCount + 1)
    end.
