-module(find_date).
-compile([export_all]).
-include_lib("i18n/include/i18n.hrl").

find(C, Date, MaxDate, CmpFn) when Date < MaxDate ->
	case CmpFn(Date) of
	false ->
		NewDate = i18n_date:add(C, Date, [{day, 1}]),
		find(C, NewDate, MaxDate, CmpFn);
	true ->
		Date
	end;
find(_C, _Date, _MaxDate, _CmpFn) ->
	not_found.
	
find(Year, FormatFn) ->
	C = i18n_calendar:open(),
	Date = i18n_date:new(1970, 1, 1),
	MaxDate = max_date(Year),
	SecretDate = random_date(Year),
	CmpFn = get_compare_fun(SecretDate, FormatFn),
	find(C, Date, MaxDate, CmpFn).

test() ->
	lists:map(fun io_test/1, 
		[{long,   get_format_fun(long)}
		,{medium, get_format_fun(medium)}
		,{short,  get_format_fun(short)}
		,{as_float, fun(X) -> X end}]),
	ok.
	
io_test({Name, FormatFn}) ->
	Year = 500,
	{Duration, SecretDate} = timer:tc(?MODULE, find, [Year, FormatFn]),
	io:format("Function: ~ts~n"
			"Secret Date (formatted): ~ts~n"
			"Secret Date (string): ~ts~n"
			"Secret Date (float): ~f~n"
			"Duration: ~f ms~2n", 
		[Name
		,case FormatFn(SecretDate) of
		 Str when is_binary(Str) -> i18n:to(Str);
		 X when is_float(X) -> float_to_list(X) 	
		 end
		,i18n:to((get_format_fun(short))(SecretDate))
		,SecretDate
		,Duration / 1000]).


-type format_type() :: long | short | medium.

-spec get_format_fun(format_type()) -> fun().

get_format_fun(Type) ->
	Format = i18n_message:open(?ISTR("{0,date," ++ atom_to_list(Type) ++ "}")),
	fun(Date) ->
		i18n_message:format(Format, [Date])
	end.

%%
%% Helpers
%%
	
random_date(Year) when Year>0 ->
	i18n_date:add(
		i18n_date:new(1970, 1, 1),
		[{year, round(random:uniform() * Year)}]).

max_date(Year) when Year>0 ->
	i18n_date:new(1970+Year, 1, 1).
	

get_compare_fun(SecretDate, FormatFn) ->
	SecretFormattedDate = FormatFn(SecretDate),
	fun(Date) ->
		FormattedDate = FormatFn(Date),
		SecretFormattedDate =:= FormattedDate
	end.
		
