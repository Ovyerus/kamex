Definitions.

Digit       = [0-9]
Int         = -?{Digit}+
Ident        = [^'"\s\r\n\t\f\(\)\[\]]+
% '
Whitespace  = [\s\t\n\r,]

Rules.

nil : {token, {nil, TokenLine}}.
\(  : {token, {'(',  TokenLine}}.
\)  : {token, {')',  TokenLine}}.

{Int}\.{Digit}+          : {token, {float, TokenLine, list_to_float(TokenChars)}}.
{Int}                    : {token, {int, TokenLine, list_to_integer(TokenChars)}}.
"(\\.|\r?\n|[^\\\n\"])*" : {token, {string, TokenLine, list_to_binary(clean_str(TokenChars))}}.
'                        : {token, {quot, TokenLine}}. % '
{Ident}+                 : {token, {ident, TokenLine, list_to_atom(TokenChars)}}.
{Whitespace}+            : skip_token.

Erlang code.

clean_str(Str) when is_list(Str) -> string:trim(Str, both, "\"").
