

% database
% lib der Karten
cardlib(race, ["T"/rce,"V"/2, "E"/1]).
cardlib(doedel, ["T"/doe,"V"/22, "E"/1]).
cardlib(old, ["T"/old,"V"/2, "E"/1]).
cardlib(me, ["T"/me, "V"/20, "E"/23]).
cardlib(straight, ["T"/trk, "V"/3]).
cardlib(right, ["T"/trk, "V"/1]).
cardlib(blank, ["."/"...", "."/"...", "."/"..."]).
cardlib(flip, ["X"/"XXX", "X"/"XXX", "X"/"XXX"]).

cardFieldDim(2,4).
% mehrere Karten können aufeinander liegen
% Kartenstack
% Struktur eines Karten
% place(CardStack, Mile, Before, Left).

card(Name, down).
card(Name, up).

% card can be flipped
flipCard(card(N, up), card(N, down)).
flipCard(card(N, down), card(N, up)).

% ausspielen auf feld
applyAction(action(Card, on),  Mile, place(CS, _, B, L), place(NCS, Mile, B, L)) :-
  append([card(Card, up)], CS, NCS).

applyAction(action(top, flip),  Mile, place([Card|CS], _, B, L), place([FlipCard|CS], Mile, B, L)) :-
  flipCard(Card, FlipCard).

applyAction(action(bottom, flip),  Mile, place(Cards, _, B, L), place(NCards, Mile, B, L)) :-
    reverse(Cards, [Bt|CS]),
    flipCard(Bt, FlipCard),
    reverse([FlipCard|CS], NCards).

% Karte wird nach links oder oben gespielt
applyAction(action(Card, left), Mile,  place(Cards, Mile, B, _), place(Cards, Mile, B, NL)) :-
    NM is Mile + 1,
    NL = place([card(Card, up)], NM, _, _).

applyAction(action(Card, before), Mile,  place(Cards, Mile, _, L), place(Cards, Mile, NB, L)) :-
    NM is Mile + 10,
    NB = place([card(Card, up)], NM, _, _).

playOn(_, action(_, _),  Place, Place) :-
  var(Place).
% treffer
playOn(Mile, Action, place(Cards, Mile, B, L), NewPlace ) :-
  applyAction(Action, Mile, place(Cards, Mile, B, L), NewPlace).

% gehe durch den Kartenbaum
playOn(Mile, Action, place(CS, M, B, L), place(CS, M, NB, NL) ) :-
  playOn(Mile, Action, L, NL),
  L = NL,
  playOn(Mile, Action, B, NB).

playOn(Mile, Action, place(CS, M, B, L), place(CS, M, NB, L) ) :-
    playOn(Mile, Action, B, NB).


% Baue ein Kartenfeld auf
initGame(Player1, Player2) :-
  playOn(0, action(me, on), place([], _, _, _), P1),
  playOn(0, action(old, left), P1, P2),
  playOn(0, action(doedel, before), P2, P3),
  playOn(0, action(right, on), P3, P4),
  playOn(10, action(race, left), P4, P5),
  playOn(10, action(bottom, flip), P5, Player1).



%%%%%%%%%%% Ausgabe %%%%%%%%%%%%%
% schreibe alle Eigenschaften in gegebene Zeilten
% Elemente der List sind die Strings der Zeilen der Karte
% schreibe nach allen Properties noch eine Leerzeile
cardToString(_, [], FB, FB2) :- append(FB, [""], FB2).
% Zeilenblock kann leer sein, fanke mit einer Zeile an
cardToString([], D, [], FB) :-
  cardToString([""], D, [], FB).
% Setze alle Properties der Karte in Zeilen zum (pro Prop. eine Zeile)
cardToString([L|[]], [CH|CT], A, FB ) :-
  cardToString([L, ""], [CH|CT], A, FB ).

cardToString([L|LS], [CH|CT], A, FB ) :-
  linePart(CH, S),
  atomic_list_concat([S, L], R),
  append(A, [R], A2),
  cardToString(LS, CT, A2, FB).


% setze Datenblock einer Karte in Zeile um
% Das Feild muss sein: I:XXX  mit XXX ist zahl
linePart(T/V, L ) :-
  number(V),
  format( atom(L),'~a:~|~`0t~d~3+ ', [T,  V]).
linePart(T/S, L ) :-
  format( atom(L),'~a:~|~` t~s~3+ ', [T,  S]).

% fails if BeforePlace doesnt exis
% if beforePlace doesnt exist

% wenn es vertikal (before) keinen neuen Knoten gibt
writeCard([[]|T], Place, _, T) :-
    var(Place).
%    cardToString([], ["-"/"-", "-"/"-"], [], LB),
%    FB = [LB |T].

writeCard([LB|T], Place, Col, FB2) :-
    var(Place),
    cardFieldDim(CMAX, _),
    Col =< CMAX,
    cardlib(blank, Data),
    cardToString(LB, Data , [], LB2),
    writeStack(LB2, [], LB3),
    FB = [LB3 |T],
    Col2 is Col +1,
    writeCard(FB, Place, Col2, FB2).

writeCard([LB|T], Place, Col, FB) :-
    var(Place),
    Col > 1,
    FB = [LB|T].

closeBlock([], LB, LB).
closeBlock([L|LS], A, LB3) :-
    format( atom(S),'   ~a  ', [L]),
    append( A, [S], A2),
    closeBlock(LS, A2, LB3).

writeStack(LB, [], LB2) :-
  closeBlock(LB, [], LB2).

writeStack(LB, [card(N, up)|CS], LB3) :-
  cardlib(N, Data),
  cardToString(LB, Data, [], LB2),
  writeStack(LB2, CS, LB3).

writeStack(LB, [card(N, down)|CS], LB3) :-
    cardlib(flip, Data),
    cardToString(LB, Data, [], LB2),
    writeStack(LB2, CS, LB3).

% schreibe die Karte aus, Ergbenis ist eine List von Strings
% LB ist LineBlock: Zeilen, die die Karte repräsentieren
writeCard([LB|T], place(Cards, M, B, L), Col, FB3) :-
  writeStack(LB, Cards, LB2),
  % cardlib(C, Data),
  % cardToString(LB, Data, [], LB2),
  Col2 is Col +1,
  writeCard([LB2|T], L, Col2, [H2|T2]),
  writeCard([ [], H2|T2], B, 0, FB3).

% Rootnode ist normalerweise das "me"
writeField(RootPlace) :-
  writeCard([[]], RootPlace, 0, FB2),
  flatten(FB2, FB3),
  writeFB(FB3).

% Schreibe das gesamte Kartenfeld
% FB steht für FrameBuffer
writeFB([]) :- nl.
writeFB([H|T]) :-
    write(H), nl,
    writeFB(T).

%%%%%%%%%%%%%% Game Play %%%%%%%%%%%%%%%%%%

play() :-
  initGame(Player1, P2),
  writeField(Player1),
  writeln("next action: (Coord, cardname, action)"),
  read((Coord, CardName, Cmd)),
  play(Player1, Coord, CardName, Cmd).

play(_, _, stop,_).

play(P1, Coord, CardName, Cmd) :-
  playOn(Coord, action(CardName, Cmd), P1, P2),
  writeField(P2),
  writeln("next action: (Coord, cardname, action)"),
  read((Coord2, CardName2, Cmd2)),
  play(P2, Coord2, CardName2, Cmd2).



% Spielfeld
