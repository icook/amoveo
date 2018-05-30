-module(talker).
-export([talk/2, talk/3, talk_timeout/3]).

-define(RETRY, 3).

talk_timeout(Msg, {IP, Port}, X) ->
    P = build_string_peer(IP, Port),
    talk_helper(Msg, P, ?RETRY, X).

talk(Msg, {IP, Port}) ->
    talk(Msg, build_string_peer(IP, Port));

talk(Msg, Peer) ->
    talk_helper(Msg, Peer, ?RETRY, 20000).

talk(Msg, IP, Port) ->
    talk(Msg, build_string_peer(IP, Port)).
ip2string2(X) ->
    (integer_to_list(X)) ++ (".").
ip2string([A,B,C,D]) ->
    ip2string({A,B,C,D});
ip2string({A,B,C,D}) ->
    ip2string2(A) ++ 
	ip2string2(B) ++ 
	ip2string2(C) ++ 
	integer_to_list(D).
build_string_peer(IP, Port) ->
    T = ip2string(IP),
    P = integer_to_list(Port),
    "http://" ++ T ++ ":" ++ P ++ "/".

talk_helper(_, _, 0, _) ->
    io:fwrite("talk helper fail\n"),
    bad_peer;
    %{error, failed_connect};
talk_helper(Msg, Peer, N, TimeOut) ->
    PM = packer:pack(Msg),
    %io:fwrite("sending message "),
    %io:fwrite(PM),
    %io:fwrite("\n"),
    %timer:sleep(500),
    Msg = packer:unpack(PM),
    case httpc:request(post, {Peer, [], "application/octet-stream", iolist_to_binary(PM)}, [{timeout, TimeOut}], []) of
        {ok, {{_, 500, _}, _Headers, []}} ->
            io:fwrite("talker: ret 500 for cmd '~p' from ~p\n", [element(1, Msg), Peer]),
	    bad_peer;
            %talk_helper(Msg, Peer, 0, TimeOut);
        {ok, {Status, _Headers, []}} ->
            io:fwrite("talker: weird response from ~p, status ~p\n", [Peer, Status]),
            io:fwrite(packer:pack(Status)),
            talk_helper(Msg, Peer, N - 1, TimeOut);
        {ok, {_, _, R}} ->
	    %io:fwrite("talker peer is "),
	    %io:fwrite(Peer),
	    %io:fwrite("\n"),
	    %io:fwrite("talker msg is "),
	    %io:fwrite(packer:pack(Msg)),
	    %io:fwrite("\n"),
	    %io:fwrite("talker response is "),
	    %io:fwrite(R),
	    %io:fwrite("\n"),
	    DoubleOK = packer:pack({ok, ok}),
	    if
		R == DoubleOK -> 0;
		true ->
		    packer:unpack(R)
	    end;
        {error, socket_closed_remotely} ->
            io:fwrite("talker: socket closed remotely ~p\n", [Peer]),
            talk_helper(Msg, Peer, N - 1, TimeOut);
        {error, timeout} ->
            io:fwrite("talk_helper timeout \n"),
	    io:fwrite(element(1, Msg)),
	    io:fwrite("\n"),
            talk_helper(Msg, Peer, N - 1, TimeOut);
        {error, failed_connect} ->
            io:fwrite("talker: failed_connect 0 ~p\n", [Peer]),
	    bad_peer;
            %talk_helper(Msg, Peer, N - 1, TimeOut);
        {error, {failed_connect, _}} ->
            io:fwrite("talker: failed_connect 1 ~p\n", [Peer]),
	    %io:fwrite(PM),
	    bad_peer;
            %talk_helper(Msg, Peer, N - 1, TimeOut);
        X ->
            io:fwrite("talker: unexpected error '~p' ~p\n", [X, Peer]),
            error
    end.
