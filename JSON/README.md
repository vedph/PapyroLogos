## Dateikorpus JSON
### Transkriptionsversionen
Jeweils 4 Versionen für **D**iplomatische bzw. **N**ormalisierte Transkription
1.  Nur text in "token", d.h. sicher gelesene Zeichen, werden gedruckt. Getrennt durch Leerzeichen, falls durch andere Elemente mit Zeichen unknown/supplied/etc. unterbrochen
2. Zusätzlich zu 1: Jede Zeichensequenz in "unclear" wird durch einen Unterstrich repräsentiert
3. Zusätzlich zu 1: Jedes Zeichen in "unclear" wird mit hinzugefügtem Unterpunkt dargestellt
4. Alle Zeichen in "unclear" werden genau wie sicher gelesene Zeichen in "token" ebenfalls normal dargestellt. "gap" und "supplied" werden als eckige Klammern mit einer Anzahl an Punkten, die der jeweiligen "quantity" entspricht, repräsentiert. Dabei wird keine Unterscheidung zwischen character- und line-gaps vorgenommen, jedoch sollten bei korrektem Markup line-gaps nur in eigenständigen Zeilen vorkommen; unbekannte Anzahl der character-/line-gaps wird durch einzelnen Punkt dargestellt. 
### Dateistruktur 
#### head
* tm-Nummer aus XML_TEI bzw. Namenskonvention aus XML_ALTO
* side: ggf. recto '1' oder verso '2' aus Namenskonvention; sonst '0'  
* noRom: ggf. römische Nummerierung aus Namenskonvention; sonst '0'
* part: ggf. Unterabschnitt eines zusammenhängenden Zeugen mit eigener Grafik, in Namenskonvention z.B. 'A' bei 62580; sonst (bei keiner derartigen Unterteilung) '_' 
* graphicURL: Link zu Grafik
* graphicName: Grafik entspricht letztem Pfadabschnitt von graphicURL
* textparts: Anzahl der in JSON vorhandenen textparts. Textparts (nach TEI-Bezeichnung) sollten TextBlock (in ALTO) entsprechen
* lines: Gesamtanzahl der in JSON vorhandenen Transkriptionszeilen
* version: Kürzel der Transkriptionsversion
#### body
* n: Attribut aus ursprünglichem div in XML_TEI
* subtype: Attribut aus ursprünglichem div in XML_TEI; falls nicht vorhanden 'N/A'
* textpartLines: Zeilenanzahl des betreffenden textparts
* text: Array mit Transkriptionszeilen des betreffenden textparts
