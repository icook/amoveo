-module(block_organizer).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
	add/1, check/0, view/0, pid/0]).
-include("../../records.hrl").
init(ok) -> {ok, []}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("block_organizer: died!\n"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast(check, BS) -> 
    BS2 = helper(BS),
    {noreply, BS2}.
handle_call({add, Blocks}, _From, BS) -> 
    BS2 = merge(Blocks, BS),
    BS3 = helper(BS2),
    {reply, ok, BS3};
handle_call(pid, _From, X) -> 
    {reply, self(), X};
handle_call(view, _, BS) -> 
    {reply, BS, BS};
handle_call(_, _From, X) -> {reply, X, X}.

pid() -> gen_server:call(?MODULE, pid).
view() ->
    gen_server:call(?MODULE, view).
merge(New, []) -> [New];
merge([], Old) -> Old;
merge([N|NT], [O|OT]) ->
    %HN = hd(N),
    HO = hd(O),
    H1 = N#block.height,
    H2 = HO#block.height,
    if
	H2 < H1 -> [O|merge([N|NT], OT)];
	true -> [[N|NT]|[O|OT]]
    end.
helper([]) -> [];
helper([[]]) -> [];
helper([H|T]) ->
    %we should run this in the background, and if H has an error, don't drop the rest of the list.

    %io:fwrite("organizer helper\n"),
    MyHeight = block:height(),
    HH = hd(H),
    H2 = HH#block.height,
    if
	H2 =< MyHeight + 1 ->
	    block_absorber:save(H),
	    helper(T);
	true -> [H|T]
    end.
	    
check() -> gen_server:cast(?MODULE, check).
add([]) -> 0;
add(Blocks) when not is_list(Blocks) -> 0;
add(Blocks) ->
    true = is_list(Blocks),
    io:fwrite("block_organizer: add ~p blocks. ~p-~p\n",
          [lists:flatlength(Blocks),
           (hd(Blocks))#block.height,
           (lists:last(Blocks))#block.height]),
    {Blocks2, AddReturn} = add1(Blocks, []),
    case Blocks2 of
	[] -> ok;
	_ ->
	    gen_server:call(?MODULE, {add, lists:reverse(Blocks2)})
    end,
    AddReturn.
add1([], []) -> {[], 0};
add1([X], L) -> 
    {L2, A} = add2(X, L),
    {L++L2, A};
add1([H|T], L) ->
    {L2, _} = add2(H, L),
    add1(T, L2).
add2(Block, Out) ->
    if
	not(is_record(Block, block)) -> {Out, 0};
	true ->
	    Height = Block#block.height,
	    BH = block:hash(Block),
	    BHC = block_hashes:check(BH),
	    if
		Height == 0 -> {Out, 0};
		BHC -> {Out, 3}; %we have seen this block already
		true -> {[Block|Out], 0}
	    end
    end.
