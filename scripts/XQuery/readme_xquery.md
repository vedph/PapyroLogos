# transcriptMultiple_2.6.xquery #
Die XQuery basiert auf der Vorläuferversion, die dafür ausgelegt war, einen vorhandenen Korpus ALTO-Dateien mit den erstellten Transkriptionen zusammen zu führen/zu füllen.
Anstelle des ALTO-Korpus (unter Nutzung der Namenskonvention) liefert nun die Tabelle "Bearbeitete Papyrusabbildungen für NewLineSegmenter" <br/> https://docs.google.com/spreadsheets/d/1kGkPYNpcTaSTe_4ROBwitSlpC0IGNxr4h22p0dZ9VF8/edit#gid=50312864 <br/>
die Grundlage für die Zuordnung von Bilddatei und Transkription per XQuery. 
Bei listPapyri.xml in /documents handelt es sich um eine Kopie dieser Tabelle (Stand 2020-11-09) in XML-Struktur und stellt zusammen mit einem Korpus von TEI-Dateien das Fundament der Query dar. <br/> 
listPapyri.xml muss bei Neuerungen derzeit manuell aktualisiert werden, um z.B. neue Dateien im Korpus zu berücksichtigen. Änderungen der Konventionen in der Tabelle (v.a. in Spalte "TextPart") könnten zu Problemen mit XQuery führen.

## Status des Korpus ##
Eine Dokumentation von Stand und Möglichkeiten der Verarbeitung mit XQuery findet sich in einer lokalen Kopie der verwendeten Tabelle:
https://docs.google.com/spreadsheets/d/1DcbklKxzo9e_rcNUO2e_mxCdBjIy4re_KpKS_Bjz03w/edit?usp=sharing
- Ist in Zeile "XQuery" eine einfache Ziffer (0-3) eingetragen, so ist die Verarbeitung derzeit (nach meinem Wissensstand) erfolgreich und die entsprechenden JSON-Dateien befinden sich im Verzeichnis. Die Ziffer steht dabei für das Verfahren der Zuordnung innerhalb der Query.
- Ist "4\w+" eingetragen, so gibt es Probleme mit der @corresp-custEvent Zuordnung, die optimaler Weise innerhalb der Datei behoben werden müsste. Dennoch wäre in manchen Fällen auch ohne die übliche Konvention eine Verarbeitung mit XQuery möglich, um den Korpus zu erweitern.
- Mit 'X' markierte Zeilen lassen sich nicht sinnvoll von Seiten der XQuery lösen, hierbei handelt es sich um gröbere Fehler in den Dateien oder um Unstimmigkeiten in den Angaben der Metadaten.
- Leere Felder stehen für nicht berücksichtigte Einträge, weil diese in der Liste gestrichen wurden

## Aktualisierung der Dateien – Workflow ##
Unter Nutzung der verschiedenen Ausgabemöglichkeiten der XQuery ergibt sich derzeit folgendes Vorgehen für die Aktualisierung des Korpus:
1. Aktuelle TEI-Dateien in PapyroLogos/XML/TEI/ ablegen bzw. Pfad in Z. 50-55 auf gewünschtes (z.B. DCLP) Verzeichnis ändern
2. (Empfohlen) Zunächst Erstellung der Datei 'documents/corpusTranscript.xml', da höchste Laufzeit und Nachverfolgung evtl. Probleme mit Neuerungen möglich 
    - Dafür Z. 22 $loadTranscriptFile auf false() stellen
    - return-Statement Z. 383-390 aktivieren und Rest der XQuery auskomentieren; Transformation-Szenario anwenden
3. Auf Grundlage von corpusTranscript.xml JSON-Dateien erzeugen und in vorgefertigtes Verzeichnis schreiben:
    - Z. 22 $loadTranscriptFile auf true() stellen 
    - return-Statement Z. 383-390 auskommentieren und Rest der XQuery aktivieren 
### Weitere Möglichkeiten der XQuery
4. (Alternativ) Vorbereitende Dateien, die zu Erzeugung von 3. genutzt werden, ausgeben lassen:
    - return-Statement Z. 715-720 aktivieren und Rest der XQuery auskomentieren
    - 'metaTree.xml', $metaTree: Auflistung der verfügbaren Metadaten nach TM-File
    - 'matchTree.xml', $match: Auflistung der Gefundenen matches, sowie der abgelehnten, unpassenden Zuordnungen
    - 'matchTreeSort.xml', $matchSort: Auflistung der Gefundenen matches
# Offene Fragen
- Wer ist für die aufgeführte Tabelle (original) verantwortlich bzw. wer arbeitet damit? Ist sie als Grundlage der XQuery langfristig überhaupt sinnvoll?
- Wie lässt sich der Prozess zukünftig robuster gestalten, sodass keine Dateien/Informationen unberücksichtigt bleiben?
- Wie sollen die aktuell als problematisch markierten Dateien (lokale Kopie der Tabelle) weiterverarbeitet werden?

