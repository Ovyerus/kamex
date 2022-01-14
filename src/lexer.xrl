Definitions.

IdentStartChar = [^'"\s\r\n\t\f\(\)\[\],@#$]
% '
IdentChar      = [^'"\s\r\n\t\f\(\)\[\],@]
% '

Digit        = [0-9]
Int          = (-?{Digit}+)
Exponent     = ([eE]{Int})
Decimal      = \.{Digit}+
Float        = ({Int}({Exponent}|({Decimal}{Exponent}?)))
ComplexPart  = (({Float})|({Int}))
Hex          = [0-9a-fA-F]

FullIdent  = {IdentStartChar}{IdentChar}*
Whitespace = [\s\t\n\r,]

Rules.

% Lists & nil
nil : {token, {nil, TokenLine}}.
\(  : {token, {'(',  TokenLine}}.
\)  : {token, {')',  TokenLine}}.

% Special modifiers for idents/functions
#{Digit}+ : {token, {tack, TokenLine, tack_to_int(TokenChars)}}.
#         : {token, {fork, TokenLine}}.
\$        : {token, {bind, TokenLine}}.
'         : {token, {quot, TokenLine}}. % '

% Literals
0[xX]{Hex}+                 : {token, {int, TokenLine, hex_to_int(TokenChars)}}.
0[bB][10]+                  : {token, {int, TokenLine, binary_to_int(TokenChars)}}.
"(\\.|\r?\n|[^\\\n\"])*"    : {token, {string, TokenLine, list_to_binary(clean_str(TokenChars))}}.
{ComplexPart}J{ComplexPart} : {token, {complex, TokenLine, list_to_complex(TokenChars)}}.
{Float}                     : {token, {float, TokenLine, list_to_float(TokenChars)}}.
{Int}                       : {token, {int, TokenLine, list_to_integer(TokenChars)}}.

% TODO: fix to allow partial applied functions beforehand
% ({FullIdent}(@{FullIdent})+) : {token, {atop, TokenLine, atop_to_idents(TokenChars)}}.
@            : {token, {atop, TokenLine}}.
{FullIdent}+ : {token, {ident, TokenLine, list_to_atom(TokenChars)}}.

% Garbage
;.*           : {token, {comment, TokenLine}}.
{Whitespace}+ : skip_token.

Erlang code.

clean_str(Str) when is_list(Str) -> string:trim(Str, both, "\"").

tack_to_int([$# | Num]) -> list_to_integer(Num).
hex_to_int([$0, _ | Num]) -> list_to_integer(Num, 16).
binary_to_int([$0, _ | Num]) -> list_to_integer(Num, 2).

list_to_complex(Str) when is_list(Str) ->
  [Real, Im] = string:split(Str, "J"),
  {list_to_num(Real), list_to_num(Im)}.

% atop_to_idents(Atop) when is_list(Atop) ->
%   Tokens = string:tokens(Atop, "@"),
%   lists:map(fun(T) -> list_to_atom(T) end, Tokens).

list_to_num(Str) when is_list(Str) ->
  % TODO: i dont think erlang supports `1e3` but does `1.2e3`. need to properly look
  IsFloat = lists:member($., Str) or lists:member($e, Str) or lists:member($E, Str),

  if
    IsFloat -> list_to_float(Str);
    true -> list_to_integer(Str)
  end.