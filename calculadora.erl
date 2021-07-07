-module(calculadora).
-import(string, [strip/3, split/3]).
-import(net_adm, [ping/1]).
-export([start/0]).

read_input() -> strip(io:get_line("Informe a expressão: "), right, $\n).

% https://stackoverflow.com/questions/17438727/in-erlang-how-to-return-a-string-when-you-use-recursion/17439656

% Realiza a analize de prioridade de operadores por meio do analisador Erlang,
% para que possamos obter uma árvore de análise de tokens Erlang.
parse(Str) ->
    {ok, Tokens, _} = erl_scan:string(Str ++ "."),
    {ok, [E]} = erl_parse:parse_exprs(Tokens),
    E.

% É feito um caminho em pós-ordem (percorre lado esquerdo e direito da árvore e
% saisse em um nó) onde, a ordem dos parênteses é armazenada na árvore - isso sendo
% tratado pelo analisador Erlang. Retorna uma lista ou string, para uso no loop.
rpn({op, _, What, LS, RS}) ->
    io_lib:format("~s ~s ~s", [rpn(LS), rpn(RS), atom_to_list(What)]);
rpn({integer, _, N}) ->
    io_lib:format("~b", [N]).

% Formatação da saída
p(Str) ->
    Tree = parse(Str),
    lists:flatten(rpn(Tree)).

% Funções de cálculo
divisao(_, 0) -> division_by_zero;
divisao(A, B) -> 
    io:format("divisao: ~p / ~p = ~p \n", [A, B, A/B]),
    A / B.

multiplicacao(A, B) ->
    io:format("multiplicacao: ~p * ~p = ~p \n", [A, B, A*B]),
    A * B.

soma(A, B) ->
    io:format("soma: ~p + ~p = ~p \n", [A, B, A+B]),
    A + B.

subtracao(A, B) ->
    io:format("subtracao: ~p - ~p = ~p \n", [A, B, A-B]),
    A - B.

% Operador para cálculo.
% É feita a verificação do operador, sendo atribuido a uma variavel - 'Stack' - o 
% valor associado a chave no dicionário do processo e em seguida, 'A' recebe o 
% último valor de 'Stack' referente a um número da expressão. 
% Logo após, uma outra variavel - 'ListaA' - lrecebe 'Stack' sem o último elemento 
% (esse já passado para 'A') onde posteriormente uma variável 'B' recebe o último 
% item da primeira lista, correspondente a outro número da expressão.
% Por fim, uma segunda lista, 'ListaB', recebe o valor da primeira lista sem o último 
% elemento desta. No final tudo, a chave recebe uma cópia da 'ListaB' e o resultado do
% cálculo dos elementos, números separados nas variáveis de acordo com a função definida pelo operador.
evaluate_aux(Elem) ->
    if
        Elem == "+" ->
            Stack = get("stack"),
            A = lists:last(Stack),
            ListaA = lists:droplast(Stack),
            B = lists:last(ListaA),
            ListaB = lists:droplast(ListaA),
            put("stack", ListaB ++ [soma(A,B)]);
        Elem == "-" ->
            Stack = get("stack"),
            A = lists:last(Stack),
            ListaA = lists:droplast(Stack),
            B = lists:last(ListaA),
            ListaB = lists:droplast(ListaA),
            put("stack", ListaB ++ [subtracao(A,B)]);
        Elem == "*" ->
            Stack = get("stack"),
            A = lists:last(Stack),
            ListaA = lists:droplast(Stack),
            B = lists:last(ListaA),
            ListaB = lists:droplast(ListaA),
            put("stack", ListaB ++ [multiplicacao(A,B)]);
        Elem == "/" ->
            Stack = get("stack"),
            A = lists:last(Stack),
            ListaA = lists:droplast(Stack),
            B = lists:last(ListaA),
            ListaB = lists:droplast(ListaA),
            put("stack", ListaB ++ [divisao(A,B)]);
        true ->
            {Num, Error} = string:to_integer(Elem),
            put("stack", get("stack") ++ [Num])
    end.

evaluate([]) -> ok;
evaluate([H|T]) ->
    evaluate_aux(H),
    evaluate(T).

% É passada para a chave uma lista que no caso será a nossa expressão.
% 'Entrada' recebe a expressão formatada conforme a definição do início
% do analisador de priorioridade implementado.
% Logo aṕos, outra variável recebe a string formatada e passada para 'Entrada' dividida em todas as partes.
% Finalizando, é chamadda a função evalute passando como parâmetro a string dividida, sendo por fim retornado
% o valor final associado a chave (este sendo o resultado do cálculo da expressão). 
loop() ->
    put("stack", []),
    ENTRADA = p(read_input()),
    Entrada_f = split(ENTRADA, " ", all),
    evaluate(Entrada_f),
    io:write(get("stack")),
    io:fwrite("\n"),
    loop().

% Função principal da calculadora
start() ->
    io:fwrite("\n"),
    loop()
