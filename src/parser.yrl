Rootsymbol group.
Nonterminals list elems elem group.
Terminals '(' ')' int float ident string nil quot.

group -> list       : ['$1'].
group -> list group : ['$1' | '$2'].

% TODO: empty list as nil instead?
list -> nil           : [].
list -> '(' ')'       : [].
list -> '(' elems ')' : '$2'.

elems -> elem       : ['$1'].
elems -> elem elems : ['$1' | '$2'].

elem -> quot list : [quote, '$2'].
elem -> quot ident : [quote, extract_token('$2')].
elem -> int        : extract_token('$1').
elem -> float      : extract_token('$1').
elem -> string     : extract_token('$1').
elem -> ident      : extract_token('$1').
elem -> list       : '$1'.

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
