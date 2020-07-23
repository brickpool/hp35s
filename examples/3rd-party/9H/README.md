9H. Peripherie-Bauteile des IC NE-555
=====================================
Zur Benutzung des integrierten Schaltkreises NE-555 als Timer oder Oszillator werden als Peripheriebauteile ein oder zwei Widerst�nde und ein Kondensator ben�tigt.

Die Dimensionierung dieser Bauteile wird, gem�� der Formeln in der Anlage (siehe Datenblatt [NE555](https://www.st.com/resource/en/datasheet/CD00000479.pdf)), von den beiden Programmteilen `A` (_"TM"_) und `B` (_"OSZ"_) vorgenommen.

Bedienung:
----------

### 1. Programm laden.
_"IC555"_ ist nur ein Massenspeicher-Name. Es gibt keine Marke dieses Namens. Aufruf von der Kommandozeile:

```
perl -Ilib asm2hpc.pl --jumpmark --plain --file=examples/3rd-party/9H/IC555.asm > examples/3rd-party/9H/IC555.txt
perl -Ilib asm2hpc.pl --jumpmark --shortcut --unicode --file=examples/3rd-party/9H/IC555.asm > examples/3rd-party/9H/IC555.35s
```

Wenn sich das Programm im Programmspeicher befindet, kann man eine der folgenden Berechnungen durchf�hren.

### 2.1 Verwendung des NE-555 als Timer:

`XEQ` `A` `ENTER` ausf�hren.
Hier m�ssen zwei der folgenden drei Parameter vorgegeben werden:

- Verweilzeit
- Kondensator
- Widerst�nde, wobei nach der Eingabe jeweils `R/S` gedr�ckt werden muss.

### 2.2 Verwendung der integrierten Schaltung als Oszillator:

`XEQ` `B` `ENTER` ausf�hren.
Bei diesem Teilprogramm sind zwei der folgenden drei Parameter n�tig:

- Frequenz
- Kondensator
- Widerst�nde, wobei ebenfalls `R/S` zu dr�cken ist.

Wenn man bei der Abfrage eines der Parameter `R/S` dr�ckt, ohne eine Eingabe zu Machen, dann interpretiert das Programm dieses so, dass der nicht angegebene Parameter berechnet werden soll.

Eine Ausnahme 1iegt vor, wenn ohne Dateneingabe nach den Abfragen f�r _"T- >M"_ oder _"R2 >B"_ im Oszillatorprogramm `R/S` gedr�ckt wird. In diesem Fall geht das Programm davon aus, dass der zuletzt eingegebene Wert ("T+ >P" bzw. "Rl >A") mit dem gerade erfragten identisch sein soll.

Eine Zusatzabfrage im Oszillatorprogramm bezieht sich auf den Einsatz einer Diode parallel zu _"R2"_. Wenn der Einatz eines solchen Bauelementes vorgesehen ist, antwortet man durch Dr�cken der Taste `Y` (Nummer _"2"_ ohne Umschalt-Taste) und `R/S`, ansonsten nur mit `R/S`.

Falls alle Parameter bis auf einen eingegeben wurden, muss es sich bei diesem um denjenigen handeln, der berechnet werden soll. Deshalb unterdr�ckt das Programm ggf. die Abfrage des letzten Parameters.

Nach Eingabe aller ben�tigten Parameter wird der Wert f�r das fehlende Bauteil bzw. die Frequenz oder die Verweilzeit berechnet und unter Verwendung des Ausgabeformates `ENG 3` angezeigt.

Beim Oszillatorprogramm werden die Werte f�r _"T+"_ und _"T-"_ bzw. _"Rl"_ und _"R2"_ nacheinander, durch Dr�cken von `R/S`, angezeigt.

Wenn festgestellt wird, dass zur Erzielung der gew�nschten Frequenz eine Diode parallel zu _"R2"_ erforderlich ist, wird dies durch Flag _"4"_ signalisiert.

Wird ein Ergebnis errechnet, das au�erhalb der �blichen Grenzwerte elektronischer Bauteile 1iegt, wird _"DATA ERROR"_ angezeigt. Das Programm sollte dann mit anderen Eingangswerten wiederholt werden.

Pr�fsummen:
-----------

"IC555" bzw. "A", "B" und "D"

- LBL A: CK=6244, LN=134
- LBL B: CK=371D, LN=306
- LBL D: CK=7285, LN=204


Quellenangabe:
--------------
Diese Text wurde aus Abschnitt 9H der nicht f�r kommerziellen Verwendung gedachten _Kopie_ "[Eine Programmsammlung f�r den HP-41](https://www.mh-aerotools.de/hp/heldermann/Eine%20Programmsammlung%20fuer%20den%20HP-41.pdf)" entnommen. Die _Kopie_ wurde mit freundlicher Genehmigung des [Heldermann Verlags](http://www.heldermann.de/) bereitgestellt. Sie wurde von [Martin Hepperle](https://www.mh-aerotools.de/airfoils/footer_german.htm) im Jahr 2014 angefertigt.

- **Titel**: Eine Programmsammlung f�r den HP-41
- **Kapitel**: Peripherie-Bauteile des IC NE-555
- **Copyright**: 1989, Heldermann Verlag
- **Autor**: Burkhard Oerttel
