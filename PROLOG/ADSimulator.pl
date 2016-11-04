

% database
% lib der Karten
cardlib(race, ["T"/car,"V"/2, "E"/1]).
cardlib(doedel, ["T"/car,"V"/1, "E"/1]).
cardlib(old, ["T"/car,"V"/0, "E"/1]).
cardlib(me, ["T"/me, "V"/2, "E"/2]).
cardlib(straight, ["T"/track, "V"/3]).
cardlib(right, ["T"/track, "V"/1]).


% mehrere Karten können aufeinander liegen
% Kartenstack
% Struktur eines Karten
place(CardStack, Before, Left).

% Spieloperatioen
% Spiele Karte links
playLeft(place(CS, B, L), NewCard, place(CS, B, L2)) :-
  playOn(L, NewCard, L2).

% Spiele Karte rechts
playBefore(place(CS, B, L), NewCard, place(CS, B2, L)) :-
  playOn(B, NewCard, B2).

playOn(Place, NewCard,  place([NewCard], _, _)) :-
    var(Place).

playOn(place(Stack, B, L), NewCard, place(Stack2, B, L)) :-
  append(NewCard, Stack, Stack2).

accessPlace(Card, place(Card, B, L), place(Card, B, L)).

accessPlace(Card, Place, Place) :-
  var(Place).

accessPlace(Card, place(C, B, L), Place) :-
  accessPlace(C, L, Place),
  accessPlace(C, B, Place).

accessPlace(Card, place(C, B, L), Place) :-
    accessPlace(C, B, Place).


% Baue ein Kartenfeld auf
initGame(Player1, Player2) :-
  playLeft( place([me], _, _), old, P1_2),
  playBefore(P1_2, doedel, Player1),
  accessPlace(doedel, Player1, Place),
  playLeft(B, old, _).



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

% fails if BeforePlace doesnt exis
% if beforePlace doesnt exist

% wenn es vertikal (before) keinen neuen Knoten gibt
writeCard([[]|T], Place, _, T) :-
    var(Place).
%    cardToString([], ["-"/"-", "-"/"-"], [], LB),
%    FB = [LB |T].

writeCard([LB|T], Place, Col, FB) :-
    var(Place),
    Col == 1,
    cardToString(LB, ["-"/"-", "-"/"-", "-"/"-"], [], LB2),
    FB = [LB2 |T].

writeCard([LB|T], Place, Col, FB) :-
    var(Place),
    Col > 1,
    FB = [LB|T].

% schreibe die Karte aus, Ergbenis ist eine List von Strings
% LB ist LineBlock: Zeilen, die die Karte repräsentieren
writeCard([LB|T], place([C|CS], B, L), Col, FB3) :-
  cardlib(C, Data),
  cardToString(LB, Data, [], LB2),
  Col2 is Col +1,
  writeCard([LB2|T], L, Col2, [H2|T2]),
  writeCard([ [], H2|T2], B, 0, FB3).

% Rootnode ist normalerweise das "me"
writeField(FB, RootPlace, FB2) :-
  writeCard(FB, RootPlace, 0, FB2),
  flatten(FB2, FB3),
  writeFB(FB3).

% setze Datenblock einer Karte in Zeile um
linePart(T/V, L ) :- atomic_list_concat([T, ":", V, "\t\t"], L).

% Schreibe das gesamte Kartenfeld
writeFB([]) :- nl.
writeFB([H|T]) :-
    write(H), nl,
    writeFB(T).


% Spielfeld
