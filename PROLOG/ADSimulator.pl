
% Muster einer Karte
card([_/NE, _/_]) :- number(NE).

% database
% lib der Karten
cardlib(race, ["F"/12,"V"/22]).
cardlib(doedel, ["F"/13,"V"/1]).
cardlib(old, ["F"/2,"V"/0]).
cardlib(me, ["E"/1, "X"/2]).

% Knotenstruktur
node(N, Before, Left).

% Baue ein Kartenfeld auf
init(Playfield) :-
  Playfield = node(me, _, _),
  playLeft(Playfield, old, _),
  playBefore(Playfield, doedel, Node),
  playLeft(Node, old, _),
  playBefore(Node, race, _).

playLeft(node(N, _, L), Card, L) :-
  L = node(Card, _ , _).

playBefore(node(N, B, _), Card, B) :-
  B = node(Card, _, _).

%%%%%%%%%%% Ausgabe %%%%%%%%%%%%%
% schreibe alle Eigenschaften in gegebene Zeilten
% ["", "", ""]
% Elemente der List sind die Strings der Zeilen der Karte
cardToString(_, [], FB, FB2) :- append(FB, [""], FB2).
% Zeilenblock kann leer sein, in dem Fall geb Linien vor
cardToString([], D, [], FB) :-
  cardToString(["", "", "", ""], D, [], FB).
% Setze alle Properties der Karte in Zeilen zum (pro Prop. eine Zeile)
cardToString([H|T], [CH|CT], A, FB ) :-
  linePart(CH, S),
  atomic_list_concat([S, H], R),
  append(A, [R], A2),
  cardToString(T, CT, A2, FB).

% fails if BeforeNode doesnt exis
% if beforeNode doesnt exist

% wenn es vertikal (before) keinen neuen Knoten gibt
writeCard([[]|T], Node, _, T) :-
    var(Node).
%    cardToString([], ["-"/"-", "-"/"-"], [], LB),
%    FB = [LB |T].

writeCard([LB|T], Node, Col, FB) :-
    var(Node),
    Col == 1,
    cardToString(LB, ["-"/"-", "-"/"-"], [], LB2),
    FB = [LB2 |T].

writeCard([LB|T], Node, Col, FB) :-
    var(Node),
    Col > 1,
    FB = [LB|T].

% schreibe die Karte aus, Ergbenis ist eine List von Strings
% LB ist LineBlock: Zeilen, die die Karte repräsentieren
writeCard([LB|T], node(N, B, L) , Col, FB3) :-
  cardlib(N, Data),
  cardToString(LB, Data, [], LB2),
  Col2 is Col +1,
  writeCard([LB2|T], L, Col2, [H2|T2]),
  writeCard([ [], H2|T2], B, 0, FB3).

% Rootnode ist normalerweise das "me"
writeField(FB, RootNode, FB2) :-
  writeCard(FB, RootNode, 0, FB2),
  flatten(FB2, FB3),
  writeFB(FB3).

% setze Datenblock einer Karte in Zeile um
linePart(T/V, L ) :- atomic_list_concat([T, ":", V, " "], L).

Schreibe das gesamte Kartenfeld
writeFB([]) :- nl.
writeFB([H|T]) :-
    write(H), nl,
    writeFB(T).


% Spielfeld
