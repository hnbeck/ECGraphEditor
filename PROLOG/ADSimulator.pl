
% Muster einer Karte
card([_/NE, _/_]) :- number(NE).

% database
% beziehungsstruktur
% lib der Karten
carlib(race, ["F"/12,"V"/22]).
carlib(doedel, ["F"/13,"V"/1]).
carlib(me, ["E"/1, "X"/2]).

node(N, Before, left).

init(Playfield) :-
  Playfield = node(me, _, _),
  playBefore(Playfield, doedel, B),
  playBefore(B, race, _).

playLeft(node(N, _, L), Card, L) :-
  L = node(Card, _ , _).

playBefore(node(N, B, _), Card, B) :-
  B = node(Card, _, _).


nodeID(node(ID, _, _), ID).
writeBefore(FB, node(N, BeforeNode, _), FB) :- var(BeforeNode).

% fails if BeforeNode doesnt exist
writeBefore(FB, node(N, BeforeNode, _), FB3) :-
  nodeID(BeforeNode, ID),
  carlib(ID, [A, _]),
  linePart(A, S),
  append([S], FB, FB2),
  writeBefore(FB2, BeforeNode, FB3).
% if beforeNode doesnt exist


writeBefore(FB , node(N, node(NN, BB, LL), L), FB2) :-
  carlib(NN, [A, _]),
  linePart(A, S),
  writeLeft(S, node(N, node(NN, BB, LL), L), Line),
  append(Line, FB, FB2),
  writeBefore(FB2, node(NN, BB, L), FB2 ).
writeBefore(_ , node(N, _, _), "").

writeLeft(Line, node(N, B, node(NN, _, LL)), Line3) :-
  carlib(NN, [A, _]),
  linePart(A, S),
  atomic_list_concat([S, Line], Line2),
  writeLeft(Line2, LL, Line3).
writeLeft(Line, node(N, B, _), Line).

writeField(FB, RootNode, FB2) :-
  writeBefore(FB, RootNode, FB2),
  writeFB(FB2).

linePart(T/V, L ) :- atomic_list_concat([T, ":", V, " "], L).

writeFB([]) :- nl.
writeFB([H|T]) :-
    write(H), nl,
    writeFB(T).

writeTable(Table) :-
  scanLine(["","","",""], Table, R),
  writeFB(R).

% Spielfeld
