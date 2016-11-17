
%%%%%%%%%%%%%% Kartendatenbank %%%%%%%%%%%%%%%%%
% cardlib( Kartentyp, [Tag/Valze, ...])
cardlib(race, ["T"/rce,"V"/2, "E"/1]).
cardlib(doedel, ["T"/doe,"V"/22, "E"/1]).
cardlib(old, ["T"/old,"V"/2, "E"/1]).
cardlib(me, ["T"/me, "V"/20, "E"/23]).
cardlib(straight, ["T"/trk, "V"/3]).
cardlib(right, ["T"/trk, "V"/1]).
cardlib(blank, ["."/"...", "."/"...", "."/"..."]).
cardlib(flip, ["X"/"XXX", "X"/"XXX", "X"/"XXX"]).


%%%%%% helper
% Replace item in list
replace([], _,_,[]).
replace([Org|T], Org, New, [New|T]).
replace([H|T], Org, New, [H|T2]) :-
      replace(T, Org, New, T2).


% definiert maximale Dimension des Kartenfeldes
cardFieldDim(3,4).
% mehrere Karten können aufeinander liegen
% Kartenstack
% Struktur eines Karten
% place(CardStack, Mile, Before, Left).

% Karte: Name und up oder down
card(_, down).
card(_, up).

% card can be flipped
flipCard(card(N, up), card(N, down)).
flipCard(card(N, down), card(N, up)).


% wegnehmen einer Karte, geht nur für top
applyAction(action(_, drop),  _, [], [], _).
applyAction(action(_, drop),  _, [R|CS], CS, R).

% flip einer Karte
applyAction(action(top, flip),  _, [Card|CS], [FlipCard|CS], FlipCard) :-
  flipCard(Card, FlipCard).
applyAction(action(bottom, flip),  _, Cards,  NewCards,  FlipCard) :-
    reverse(Cards, [Bt|CS]),
    flipCard(Bt, FlipCard),
    reverse([FlipCard|CS], NewCards).

% Karte wird nach links oder oben gespielt
% ausspielen auf feld
% Card ist eine card(id, _) struktur
applyAction(action(Card, on),  _, CS, NewCards, Card) :-
  append([Card], CS, NewCards).

applyAction(action(To, move), Mile,  place([Card|CS], Mile, _, L), place(NCards, Mile, NB, L), Card).


%%%%%%%%%%% Available Commands %%%%%%%%%%%%%
% action(top, flip)
% action(bottom, flip)
% action(Card, on)
% action(Card, left)
% action(Card, before)
% action(Card, move)
% action(_, drop)

heading(before, 10).
heading(after, -10).
heading(left, 1).
heading(right, -1).

%%% Kommandoausführung
%% so kommt es aus der Kommandozeile
playOn((Coord, Name, flip), P1, P2) :-
  applyOn(Coord, action(Name, flip), P1, P2, _).

playOn((From, To, move), P1, P3) :-
  applyOn(From, action(To, drop), P1, P2, R),
  applyOn(To, action(R, on), P2, P3, R2).

playOn((Coord, Name, Cmd), P1, P2) :-
  applyOn(Coord, action(card(Name, up), Cmd), P1, P2, _).

playOn((Coord, Cmd), P1, P2) :-
    applyOn(Coord, action(_, Cmd), P1, P2, _).

newPlace(Mile, Heading, NewCards, NewPlace) :-
  heading( Heading, D),
  NM is Mile + D,
  NewPlace = place(NewCards, NM, _, _).

%%%%%% Suche den Kartenplatz, für den die Aktion gilt
% Ende einer Suchrichtung
applyOn(_, action(_, _),  Place, Place,_ ) :-
  var(Place).

applyOn(Mile, action(Cmd, before), place(Cards, Mile, _, L), place(Cards, Mile, NB, L), R) :-
  applyAction(action(Cmd, on), Mile, [],  NewCards, R),
  newPlace(Mile, before, NewCards, NB).

applyOn(Mile, action(Cmd, left), place(Cards, Mile, B, _), place(Cards, Mile, B, NL), R) :-
  applyAction(action(Cmd, on), Mile, [],  NewCards, R),
  newPlace(Mile, left, NewCards, NL).

% place gefunden
applyOn(Mile, Action, place(Cards, Mile, B, L), place(NewCards, Mile, B, L), R) :-
  applyAction(Action, Mile, Cards, NewCards, R).

% gehe durch den Kartenbaum
applyOn(Mile, Action, place(CS, M, B, L), place(CS, M, NB, NL), R ) :-
  applyOn(Mile, Action, L, NL, R),
  % var(R), % es liegt noch kein Ergebnis vor
  applyOn(Mile, Action, B, NB, R).


% Baue ein Kartenfeld auf
initGame(Player1, _) :-
  applyOn(0, action(card(me, up), on), place([], _, _, _), P1,_),
  applyOn(0, action(card(old,up), left), P1, P2,_),
  applyOn(0, action(card(doedel,up), before), P2, P3,_),
  applyOn(0, action(card(right,up), on), P3, P4,_),
  applyOn(10, action(card(race,up), left), P4, P5,_),
  applyOn(10, action(card(bottom,up), flip), P5, Player1,_).


  %%%%%%%%%%%%%% Game Play %%%%%%%%%%%%%%%%%%

play() :-
  initGame(Player1, _),
  writeField(Player1),
  writeln("next action: (Coord, cardname, action)"),
  read(Cmd),
  play(Player1, Cmd).

play(_, _, stop,_).

play(P1, Cmd) :-
  playOn(Cmd, P1, P2),
  writeField(P2),
  writeln("next action: (Coord, cardname, action)"),
  read(Cmd2),
  play(P2, Cmd2).




%%%%%%%%%%%%%% Ausgabe %%%%%%%%%%%%%%%%
% FrameBuffer ist eine Liste von Zeilenblöcken
% FB = [[1,2,3..], [1,2,3..]...]
% jede Zeile 1,2,3... enthält eine Property einer Karte
% jede [1,2,3...] ist ein Zeilenblock (stellt eine Karte dar)

% setze eine Zeile des Datenblock einer Karte in eine Zeile um
% Das Feild muss sein: I:XXX  mit XXX ist zahl oder string
linePart(T/V, L ) :-
  number(V), !,
  format( atom(L),'~a:~|~`0t~d~3+ ', [T,  V]).
linePart(T/S, L ) :-
  format( atom(L),'~a:~|~` t~s~3+ ', [T,  S]).

% schreibe alle Eigenschaften in gegebene Zeilten
% Elemente der List sind die Strings der Zeilen der Karte
% schreibe nach allen Properties noch eine Leerzeile

% cardToString(Zeileliste des Blocks, Properyliste, Akku, FrameBuffer)

% keine Properties mehr
cardToString(_, [], FB, FB).
% Zeilenblock kann leer sein, fange mit einer Zeile an
cardToString([], D, [], FB) :-
  cardToString([""], D, [], FB).
% Füge neue Zeile dazu falls weniger Zeilen als Properties
cardToString([L|[]], [CH|CT], A, FB ) :-
  cardToString([L, ""], [CH|CT], A, FB ).
% allgemeiner Fall
cardToString([L|LS], [CH|CT], A, FB ) :-
  linePart(CH, S),
  atomic_list_concat([S, L], R),
  append(A, [R], A2),
  cardToString(LS, CT, A2, FB).


% wenn es vertikal (before) keinen neuen Knoten gibt
% closeBlock fügt links und rechts des Blocks Leerzeichen einer
% closeBlock(Ausgangszeilenblock, Akku, Ergebniszeilenblock)
% ende des Blocks erreicht: füge Positionsinfo ein
closeBlock([], [L|LS], M, N, LB2, N2) :-
  N2 is N * 9,
  format(atom(F), '~~| (~~d)~~` t~~~d+', [N2]),
  format(atom(S), F, [M]),
  append([L|LS], [S], LB2).
% allgemeiner Fall
closeBlock([L|LS], A, M, N, LB3, W2) :-
    format( atom(S),' ~a  ', [L]),
    append( A, [S], A2),
    closeBlock(LS, A2, M, N, LB3, W2).


%% add the card block to the frame buffer lines
addBlock([], _ , FS, FS).
addBlock(LB, [], _, LB).
addBlock([L| LS], [F|FS], A, LB2) :-
  atomic_list_concat([L, F], S),
  append(A, [S], A2),
  addBlock(LS, FS, A2, LB2).


writeBlankStack(LB, M, LB3, W) :-
  cardlib(blank, Data),
  cardToString(LB, Data, [], LB2),
  closeBlock(LB2, [], M, 1, LB3, W).
% Leerer Platz
writeStack(LB, [], M, 0, LB3, W) :-
  writeBlankStack(LB, M, LB3, W), !.
% ende des Stacks herausschreiben, N ist dann >= 1
writeStack(LB, [], M, N, LB2, W) :-
  closeBlock(LB, [], M, N, LB2, W).
% ungeflippte Karte
writeStack(LB, [card(Name, up)|CS], M, N, LB3, W) :-
  cardlib(Name, Data),
  cardToString(LB, Data, [], LB2),
  N2 is N + 1,
  writeStack(LB2, CS, M, N2, LB3, W).
% Geflippte Karte
writeStack(LB, [card(_, down)|CS], M, N, LB3, W) :-
  cardlib(flip, Data),
  cardToString(LB, Data, [], LB2),
  N2 is N + 1,
  writeStack(LB2, CS, M, N2, LB3, W).
% Leeres Feld
writeStack(LB, [[]|_], M, _, LB3, W) :-
  writeBlankStack(LB, M, LB3, W), !.

% Zeilenblock ist leer und Platz ist undefiniert
% = schreibbewegung nach oben (Before)
writePlace([RL, []|T], Place, _, [RL|T]) :-
    var(Place).
% Es gibt einen Zeilenblock und Platz ist undefiniert
% Schreibbewegung ist links
writePlace([RL, LB|T], Place, Col, FB2) :-
    var(Place),
    cardFieldDim(CMAX, _),
    Col < CMAX,
    writeStack([], [[]], -1, 1, Block, Size), % Deute Platz an
    append([Block], LB, LB2),
    Col2 is Col +1,
    writePlace([RL, LB2 |T], Place, Col2, FB2).
% Linksbewegung aushalb der Feldgrenzen (Col >= CMAX)
writePlace(FB, Place, _, FB) :-
    var(Place).
% schreibe die Karte aus, Ergbenis ist eine List von Strings
% LB ist LineBlock: Zeilen, die die Karte repräsentieren
writePlace([RL, LB|T], place(Cards, M, B, L), Col, FB2) :-
  writeStack([], Cards, M, 0, Block, Size),
  append([Block], LB, LB2),
  updateRulers(RL, Col, Size, RL3),
  Col2 is Col +1,
  writePlace([RL3, LB2|T], L, Col2, [RL4 | FBs]),
  writePlace([ RL4, [] | FBs], B, 0, FB2).

updateRulers(RulerList, Col, Size, RulerList) :-
  nth0(Col, RulerList, OldSize),
  Size =< OldSize.

updateRulers(RulerList, Col, Size, NewRulerList) :-
  nth0(Col, RulerList, OldSize),
  Size > OldSize,
  replace(RulerList, OldSize, Size, NewRulerList).

% Schreibe das ganze Kartenfeld
% Übergebe jetzt auch Rulerlist
writeField(RootPlace) :-
  writePlace([[1,1,1], []], RootPlace, 0,  [RL|FB2]),
  reverse(RL, RL2),
  formatRows([], FB2, RL2, FB3 ),
  flatten(FB3, FB4),
  writeFB(FB4). 

formatRows(RowBlock, [], _, RowBlock).
%  format is [[ [Lines  Place1], [Lines Place 0]]]
formatRows(RowBlock, [ColBlocks|Columns], Rulers, [RowBlock2 | FB3]) :-
  appendRow(RowBlock, ColBlocks, Rulers, RowBlock2) ,
  formatRows([], Columns, Rulers, FB3).

appendRow(Block, [], _, Block).
appendRow([], [CardBlock|CardBlocks], [RL|Rulers], Block3) :-
  appendLines([], CardBlock, RL, Block2),
  appendRow(Block2, CardBlocks, Rulers, Block3).
appendRow(Block, [CardBlock|CardBlocks], [RL|Rulers], Block3) :-
  appendLines(Block, CardBlock, RL, Block2),
  appendRow(Block2, CardBlocks, Rulers, Block3).

appendLines(Lines, [], _, Lines).
appendLines([], Cols, RL, Lines2) :-
  appendLines([""], Cols, RL, Lines2).

appendLines([L|Lines], [C|Cols], RL, [S|Lines2]) :-
  format(atom(F), '~~s~~|~~s~~` t~~~d+', [RL]),
  format(atom(S), F, [L, C]),
  appendLines(Lines, Cols, RL, Lines2).

% Schreibe das gesamte Kartenfeld
% FB steht für FrameBuffer
writeFB([]) :- nl.
writeFB([H|T]) :-
    write(H), nl,
    writeFB(T).
