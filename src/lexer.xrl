Definitions.

Digit             = [0-9]
Int              = -?{Digit}+
IdentStartChar   = [^'"\s\r\n\t\f\(\)\[\],@#$]
% '
IdentChar        = [^'"\s\r\n\t\f\(\)\[\],@]
% '
FullIdent        = {IdentStartChar}{IdentChar}*
Whitespace       = [\s\t\n\r,]

Rules.
% TODO: what is `#0`?

nil : {token, {nil, TokenLine}}.
\(  : {token, {'(',  TokenLine}}.
\)  : {token, {')',  TokenLine}}.

#{Digit}+                        : {token, {tack, TokenLine, tack_to_int(TokenChars)}}.
#                                : {token, {fork, TokenLine}}.
\$                               : {token, {bind, TokenLine}}.
{Int}\.{Digit}+                  : {token, {float, TokenLine, list_to_float(TokenChars)}}.
{Int}                            : {token, {int, TokenLine, list_to_integer(TokenChars)}}.
"(\\.|\r?\n|[^\\\n\"])*"         : {token, {string, TokenLine, list_to_binary(clean_str(TokenChars))}}.
'                                : {token, {quot, TokenLine}}. % '
({FullIdent}(@{FullIdent})+)     : {token, {atop, TokenLine, atop_to_idents(TokenChars)}}.
{FullIdent}+                     : {token, {ident, TokenLine, list_to_atom(TokenChars)}}.
{Whitespace}+                    : skip_token.

Erlang code.

clean_str(Str) when is_list(Str) -> string:trim(Str, both, "\"").
tack_to_int([$# | Num]) -> list_to_integer(Num).

atop_to_idents(Atop) when is_list(Atop) ->
  Tokens = string:tokens(Atop, "@"),
  lists:map(fun(T) -> list_to_atom(T) end, Tokens).