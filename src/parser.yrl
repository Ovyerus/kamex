Rootsymbol group.
Nonterminals list elems elem group.
Terminals '(' ')' int float ident string nil quot atop fork tack bind.

group -> list       : ['$1'].
group -> list group : ['$1' | '$2'].

% TODO: maybe disallow literal () as empty list since original impl doesn't.
list -> nil           : [].
list -> '(' ')'       : [].
list -> '(' elems ')' : '$2'.

elems -> elem       : ['$1'].
elems -> elem elems : ['$1' | '$2'].

elem -> quot list  : [quote, '$2'].
elem -> quot ident : [quote, extract_token('$2')].
elem -> atop       : [atop | extract_token('$1')].
elem -> fork list  : [fork | '$2'].
elem -> bind list  : [bind | '$2'].
elem -> tack       : [tack | [extract_token('$1')]].
elem -> int        : extract_token('$1').
elem -> float      : extract_token('$1').
elem -> string     : extract_token('$1').
elem -> ident      : extract_token('$1').
elem -> list       : '$1'.

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
