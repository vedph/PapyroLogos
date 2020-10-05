xquery version "3.1";
import module namespace to = "tool" at "file:///C:/Datenbanken/OCR/PapyroLogos/scripts/XQuery/to-tool.xquery";                           (: UPDATE PATH :)
import module namespace ts = "transcript" at "file:///C:/Datenbanken/OCR/PapyroLogos/scripts/XQuery/ts-transcript.xquery";               (: UPDATE PATH :)
declare namespace lo = "http://www.w3.org/2005/xquery-local-functions"; 
declare namespace TEI = "http://www.tei-c.org/ns/1.0";
declare namespace ns-v4 = "http://www.loc.gov/standards/alto/ns-v4#";
declare namespace file = "http://expath.org/ns/file";  


(:  ### SCHALTER I ###
1. true(): lässt Einfügungen nur zu wenn Zeilenanzahl in ALTO und TEI übereinstimmen 
2. false(): Zeilen bleiben entweder leer, oder die verbleibenden Transkriptzeilen werden mit Bindestrich (-) 
    als Trennzeichen  in die letzte Zeile der ALTO-Datei geschrieben :)

declare variable $onlyMatchingLines := false();

(:  ### SCHALTER II ###
1. true(): corpusTranscript.xml wird aus angegebenem Verzeichnis geladen (Pfad in globaler Variable $fileTranscript)
2. false(): Daten werden aus den ursprünglichen XML-Dateien in $corpusXML erstellt,
   corpusTranscript wird in Variable $corpusTranscript gespeichert :)
        
declare variable $loadTranscriptFile := true();


(:  ### SCHALTER III ###
    Vier Booleans zur Steuerung der Outputformate – nur eines auf true() setzen, ansonsten wird nur das jeweils erste ausgegeben  :)
declare variable $textOutput := false();
declare variable $jsonOutput := false();
declare variable $xmlOutput  := true();
declare variable $altoOutput := false();

(:  ### Pfade zu Verzeichnissen und Dateien ###  :)
declare variable $repository := 'C:/Datenbanken/OCR/';      (: UPDATE PATH :)

(: ## Vorstrukturierung der Transkriptionen ## :)
(: # 1. SCHALTER II = true # :)
declare variable $fileTranscript := concat($repository,'PapyroLogos/documents/corpusTranscript.xml'); (: aus alto-Version 3.4:)

(: # 2. SCHALTER II = false # :)
(: Zuordnungstabelle von Griechisch mit Akzenten zu normalisierten Majuskeln ist im transcript-Modul zu definieren, falls $loadTranscriptFile = false() :)
declare variable $tableGreek := $ts:tableGreek; 

(: Ordner oder Verzeichnis der ursprünglichen XML-Dateien, aus denen Transkript-Daten extrahiert werden sollen :)
declare variable $corpusXML := concat($repository,"PapyroLogos/XML/TEI/DCLP@imaged") ;  

(: Umstrukturierung der Transkriptionen wird by default in Variable $corpusTranscript gespeichert, 
   kann jedoch auch (ab Zeile 364) als Datei ausgegeben werden, um sie bei zwetem Durchlauf per SCHALTER II = true abzurufen :)
(: Zielverzeichnis für corpusTranscript.xml, die alle Transkript-Dateien des Korpus enthält:)
declare variable $destinationAUX := concat($repository, 'PapyroLogos/documents/');


(: ## Generierung der XML-Alto Dateien ## :)
(: Ordner oder Verzeichnis der ursprünglichen XML-Alto Dateien :)
declare variable $corpusAlto := concat($repository,'PapyroLogos/XML/ALTO/input_test');                                                        
declare variable $destinationAlto := "PapyroLogos/XML/ALTO/output_xquery/";     


declare variable $destinationTXT := 'PapyroLogos/TEXT/';
declare variable $destinationJSON := 'PapyroLogos/JSON/';
declare variable $destinationXML := 'PapyroLogos/XML/JSON_structure/';


(: Kopiert alle Elemente, die keine String-Elemente enthalten;
  Baut alle Elemente, die String-Elemente enthalten neu auf und, falls es TextBlock ist, sorgt für Iterierung über alle Zeilen, sodass dort Inhalte eingefügt werden können :)
  (: Parameter: 1. Zu kopierende Root/Element-Knoten (ursprüngliche Alto-Datei); 2. Liste der einzufügenden Transkriptionszeilen; 
    3. aktueller Iterationsstand; 4. Anzahl der Zeilen in Alto; 5. Anzahl der Zeilen in Transkription :)
declare function lo:copy-or-insert-node($node as node()*, $insertLines as node()*, $n as xs:integer*, $ceiling as xs:integer*, $linesTEI as xs:integer*) as node()* {
for $element in $node/element() 
return 
if ($element//ns-v4:String)
    then    
    if (name($element)='alto')
    then 
    element {name($element)}{
        (:namespace ns-v4 {"http://www.loc.gov/standards/alto/ns-v4#"},:)
        for $a in $element/attribute() return $a,
        lo:copy-or-insert-node($element, $insertLines, $n, $ceiling, $linesTEI)
        }
    
    (: In PrintSpace werden die TextBlöcke der Reihe nach eingefügt und dabei anhand der Position mit dem Inhalt der jeweiligen textparts aus TEI versehen :)
    else if (name($element)='PrintSpace')
        then 
        element {name($element)}{for $a in $element/attribute() return $a,
        let $blockNo := count($element/ns-v4:TextBlock)
        for $block at $posB in $element/ns-v4:TextBlock 
        return
            element {name($block)}{for $a in $block/attribute() return $a,
            let $textpartNo := count($insertLines//textpart)
            let $lineNo := count($block/ns-v4:TextLine)
            let $textpartLines := count($insertLines//textpart[$posB]/line)
            for $line at $posL in $block/ns-v4:TextLine 
                return 
                (: Wenn die Anzahl der textparts in TEI mit der Anzahl der TextBlöcke in Alto übereinstimmt, :)
                (: if ($textpartNo = $blockNo)
                then :)
                element {name($line)}{for $a in $line/attribute() return $a,
                lo:copy-or-insert-node($line, $insertLines//textpart[$posB], $posL, $lineNo, $linesTEI)  
                }
                (: Wenn es weniger oder mehr Alto-TextBlöcke gibt (aber evtl. dennoch die richtige Zeilenanzahl wegen abweichender Unterteilung bei der Segmentierung) 
                 könnten die überschüssigen textparts auch in den letzten TextBlock eingefügt werden :)
                (:else ():)
            }
        }           
        else
        element {name($element)}{
        for $a in $element/attribute() return $a,
        lo:copy-or-insert-node($element, $insertLines, $n, $ceiling, $linesTEI)
        }
    else if (name($element)='String')
        then       
        element {name($element)}{
        for $a in $element/attribute() return (
        if (name($a)='CONTENT')
            then if ($n = $ceiling and $ceiling < $linesTEI)
                then let $remainingPos := lo:generate-sequence($n, $linesTEI) 
                return
                attribute {name($a)}{string-join(
                for $i in $remainingPos return $insertLines//line[$i]//text()
                ,'-')} 
                else attribute {name($a)}{$insertLines//line[$n]//text()}
            else $a     
            ),
        lo:copy-or-insert-node($element, $insertLines, $n, $ceiling, $linesTEI)
        }          
    else to:strip-namespace($element)
    
};


(: Übergebene XML-Knoten mit Transkription wird nach 4 verschiedenen Formatierungsszenarien interpretiert und auf entsprechenden Text pro Zeile reduziert :)
declare function lo:transcription-format($source as node()*, $format as xs:integer) as node()* {
<root>{
for $textpart in $source//textpart return <textpart>{

(: Nur text in "token", getrennt durch Leerzeichen, falls durch andere Elemente unterbrochen :)
if ($format=1)
    then for $line in $textpart//line return 
    <line>{string-join($line//token//text(), ' ')}</line>

(: Wie I; jede Zeichensequenz "unclear" wird durch einen Unterstrich repräsentiert :)
else if ($format=2)
    then for $line in $textpart//line return
    <line>{normalize-space(string-join(
    for $element at $pos in $line/element() return 
    if (name($element)='token')
        then $element/text()
    else if (name($element)='unclear')
        then '_'
    else ' '      
    ))}</line>

(: Wie I; jedes Zeichen in "unclear" wird mit hinzugefügtem Unterpunkt dargestellt :)
    else if ($format=3)
    then for $line in $textpart//line return 
    <line>{normalize-space(string-join(
    for $element at $pos in $line/element() return 
    if (name($element)='token')
        then $element/text()
    else if (name($element)='unclear')
        then for $character in tokenize($element) 
        return concat('&#803;', $character)
    else ' '      
    ))}</line>

(: Wie I; alle Zeichen in "unclear" werden ebenfalls normal dargestellt; 
   "gap" und "supplied" als eckige Klammern mit "quantity"-entsprechender Anzahl Punkten 
   Keine Unterscheidung zwischen character/line-gaps; unbekannte Anzahl durch einzelnen Punkt dargestellt :)
else if ($format=4)
    then for $line in $textpart//line return 
     <line>{normalize-space(string-join(
    for $element at $pos in $line/element() return 
    if (name($element)='token' or name($element)='unclear')
        then $element/text()
    else if (name($element)='gap' or name($element)='supplied')
        then let $quantity := if ($element/quantity/text() != 'unknown')
            then xs:integer(to:substring-before-if-contains($element/quantity/text(), '-'))
            else 1
        return concat('[',lo:add-dot($quantity,0,''),']')
    else ' '      
    ))}</line>
else ()

}</textpart>}</root>

};

(: Rekursive Funktion, die eine ganzzahlige Menge an Punkten (.) erzeugt; Startwerte für Parameter 2 u. 3 jeweils 0 u. '' :)
declare function lo:add-dot($n as xs:integer, $i as xs:integer, $string as xs:string*) as xs:string* {
if ($i < $n)
    then lo:add-dot($n, $i+1, concat($string,'.'))
    else $string
};

(: Rekursive Funktion, die eine Sequenz fortlaufender Ganzzahlen erzeugt; Startwert für Parameter 1 ist int(0 :)
declare function lo:generate-sequence($sequence as xs:integer*, $end as xs:integer) as xs:integer* {
if ($sequence[last()] < $end)
    then lo:generate-sequence(($sequence, $sequence[last()]+1), $end)
    else $sequence
};

(:
declare function lo:save-files($content as xs:string, $destination as xs:string, $fileName as xs:string, $extension as xs:string, $version as xs:string  ){


file:write(concat("file:///", $repository, $destination, $version, '/', $fileName, $extension), $content)
};
:)
(: Ende Prolog :)


(: Stellt graphic-URL und entsprechende Textparts mit angepasstem Markup (und ggf. target-URL) in XML zusammen :) 
(: Aufbau der Datei je Ausgangs-XML: {Dateiname,{textpart{@graphic-URL?,text+},@target-URL?}+}  :)


let $dataTranscript := collection(concat('file:///', $corpusXML ,'?recurse=yes' )) 

    (: XML-Dokument der $custEventDoc Variable; Sammlung der Elemente mit Link zur Grafik 
        Nur nötig falls Verweise auf Drittdatein vorkommen :)
    (: let $custEventDoc := doc(concat('file:///', $ts:fileCustEvent)) :)

(:  Sammlung der custEvent Einträge des gesamten Verzeichnisses in custEvent.xml -                       
    falls textparts mit ihren @corresp auf custEvents in anderen Dateien zeigen     :)     
    
(: Beinhaltet alle Transkriptionen, um diese anschließend an passender Stelle in die alto-Dateien einfügen zu können 
   Kann in einem Skriptaufruf erzeugt und abgerufen werden, oder die zuerst erzeugte Datei corpusTranscript.xml wird in zweitem Lauf abgerufen
   globale Variable $createCorpusTranscript = true/false einstellen, um diese Varianten zu steuern :)   


let $corpusTranscriptPrep :=


if ($loadTranscriptFile = true())
then doc(concat('file:///',$fileTranscript))/root

else 
<root>{
for $i in $dataTranscript where $i//TEI:custEvent[data(@type="imaged")]   (: generelle Vorsortierung nur imaged :)
let $name := $i/TEI:TEI/data(@xml:id)
let $textpart := $i//TEI:div[@type="textpart"][child::element()/name()='ab' or child::element()/name()='lg'](:[exists(@corresp)]:)
let $target := if($i//TEI:bibl[@type="online"]) 
    then $i//TEI:bibl[@type="online"]//TEI:ptr/data(@target) 
    else $i//TEI:bibl//TEI:ptr/data(@target) 
where not(empty($textpart))               (: Dateien ohne Textpart werden ignoriert :)

return 
<file>{



for $x at $pos in $textpart          
let $root := $x//ancestor::TEI:TEI 
let $name := $root/data(@xml:id)
let $custEvent := if (not(empty($root//TEI:custEvent[data(@corresp)=$x/data(@corresp)])))
    then $root//TEI:custEvent[data(@corresp)=$x/data(@corresp)]                                         (: findet corresp in gleicher Datei :)
    else () (: $custEventDoc//custEvent[data(@corresp)=$x/data(@corresp)]   :)                                  (: greift auf Variable bzw. XML-Dokument zurück; ggf. auskommentieren, falls nicht benötigt :)
let $typeCE := if (not(empty($custEvent))) then "" (:$custEvent[child::TEI:graphic]/data(@type):) else ""   (: custEvent nur nötig, falls Verweise auf Drittdateien vorkommen:)
let $graphicCE := if (not(empty($custEvent))) then $custEvent//TEI:graphic/data(@url) else "N/A"
let $namePrefix :=             (: Anfang des Dateinamens 1. @type des custEvents :)
    if (not($typeCE=''))
    then if ($typeCE='engraved' or $typeCE='MSI' or $typeCE='sketched')
        then 'exclude'
        else distinct-values($typeCE)
    else if (not(empty($target)))
        then 'target'
    else 'empty'

(: Es werden immer lineBeginnings <lb/>node() zu <line>node()</line> umgewandelt  
 In anonymousBlock-Markup, sowie lineGroup-Markup ohne nummerierte lines sind diese lb-Elemente die einzige Zeileneinteilung (default) 
 In manchen lg-Markups kommen nummerierte l- und lb-Elemente nebeneinander vor, dennoch wird nur nach lb's umstrukturiert (not(default));
 dafür wird der textpart zunächst normalisiert und in die Form des default-Falls gebracht (betrifft ca. 10% der Textparts) :)
let $default := exists($x//TEI:ab) or not(exists($x//TEI:lg//TEI:l/@n))

(: Wenn "versteckte" lineBeginning-Elemente (unterhalb der sibling-Ebene von textpartParent/child in anderen Markup-Elementen) vorkommen
 muss Umstrukturierungsstrategie geändert werden; add-Elemente sind davon jedoch ausgenommen, diese werden ggf. wie selbstständiger textpart behandelt:)
let $hiddenLB := count($x//TEI:lb[not(parent::element()[name()='ab' or name()='l'])])

(: Restrukturierung1 nur wenn versteckte lineBeginning-Elemente nicht oder ausschließlich in add vorkommen:
 Hier wird direkt über lb's iteriert und alle restlichen Markup-nodes in neue Zeilenhierarchie geschrieben;
 ansonsten wird zuerst das Markup verarbeitet, ggf. Elemente um versteckte <lb/> umstrukturiert 
 und erst danach unter die Hierarchie der Zeilen eingeordnet :)
let $restructure1 := ($hiddenLB = 0) or ($hiddenLB = count($x//TEI:lb[parent::TEI:add]))

let $text :=
    <text default="{$default}" restructure1="{$restructure1}" editionType="normalized">
    { 
if (not($default))
    then   
        let $textpart := <ab>{
        for $node in $x//TEI:l/child::node() where not(to:is-value-in-sequence($node/name(), $ts:ignore))
            return $node
        }</ab>
        return ts:restructure-lines($textpart, $restructure1, not($restructure1))    
(: Normalerweise werden jedoch <lb/> Elemente zu hierarchisch übergeordneten line-Elementen umstrukturiert :)        
    else ts:restructure-lines($x, $restructure1, not($restructure1))  
    }</text>

let $textDiplomatic := <text default="{$default}" restructure1="{$restructure1}" editionType="diplomatic">
    {ts:generate-diplomatic($text)}</text>        

return 
element textpart {
for $attribute in $x/@* return attribute {$attribute/name()} {data($attribute)},
(
   <name prefix="{$namePrefix}">{
    to:substring-after-match($name,'m')
    }</name>,
if (not(empty($graphicCE))) 
    then <graphic n="{$pos}">{$graphicCE}</graphic> 
    else <graphic n="{$pos}"/>,
if (not(empty($typeCE))) 
    then <type>{$typeCE}</type> 
    else <type/>,
if (not(empty($text))) 
    then ($text, $textDiplomatic) 
    else ''
    )
},
if (not(empty($target))) 
    then <target>{
    for $URL in $target return <URL>{$URL}</URL>
}</target> else <target/>
}</file> 
}</root>




(: ### Zur besseren Handhabung von Kolumnen wird in corpusTranscript eine Zwischenebene <cohesiveTextparts> eingezogen (zwischen <file> und <textpart>s) in denen alle textparts gesammelt sind, 
die zur selben Grafik-URL zugeordnet sind. Nach aktueller Kenntnis des Korpus trifft dies bei allen Dateien mit Kolumnen zu. ### :)


let $corpusTranscript := 
if ($loadTranscriptFile = true())
then doc(concat('file:///',$fileTranscript))/root

else 
<root>{
for $file in $corpusTranscriptPrep//file
return 
<file name="{distinct-values($file//name)}">{
let $graphics := distinct-values($file//graphic/text())  
for $graphic in $graphics return
(: Ebene für Alto-Interpretation mit Grafik-Bezug als Elternelement :)
<cohesiveTextparts graphic="{$graphic}">{
for $textpart in $file//textpart 
 where ($textpart/graphic/text() = $graphic)    (: aussortierung über match-struktur ist quatsch, weil hier doch erstmal nur die apriorisch zusammenhängenden Textparts gesammelt werden :)
return $textpart
}</cohesiveTextparts>
}</file>
}</root>

(:  Falls ($loadTranscriptFile := false()) kann hier die Variable $corpusTranscript als Datei ausgegeben werden
    Statements vor der Variablendeklaration entsprechend auskommentieren    :) 

(:
return 
file:write(concat("file:///", $destinationAUX, 'corpusTranscript',".xml"), $corpusTranscript)
:)

(: ### Implementierung für ALTO-XML ### :)


let $dataAlto := collection(concat('file:///', $corpusAlto ,'?recurse=no' )) 
let $imagedFiles := fn:distinct-values($corpusTranscript//name/text()) 
let $insertFiles := distinct-values(for $i in $dataAlto order by $i return 
    to:substring-before-match(to:substring-after-last-match(xs:string(document-uri($i)), '/'), '_'))


(:
let $insertTree :=
<root>{ 
:)


(: Iterierung über Alto-Korpus primär um Metadaten aus Dateinamen auszulesen – kann auch durch Liste etc. erreicht werden :)
(: Sekundär um in die Dateien den Textinhalt zu schreiben – nur relevant in zu ersetzendem Ansatz wenn $altoOutput=true() :)
(: Liste der insertFiles muss in neuer Version dementsprechend anders generiert werden :)

for $TM at $posTM in $insertFiles 

(:
let $file :=
<file n="{$TM}">{
:)

for $i in $dataAlto
let $fileNameAlto := to:substring-after-last-match(xs:string(document-uri($i)),'/')
let $jpgNameAlto := $i//ns-v4:fileName/text()
let $jpgAlto := to:substring-after-match($jpgNameAlto, '__')
let $linesAlto := count($i//ns-v4:TextLine)
let $tmAlto := to:substring-before-match($fileNameAlto, '_')

(: where to:is-value-in-sequence($tmAlto, $imagedFiles)     alto-Dateien, für die keine TEIs mit imaged-Transkriptionen vorliegen werden ausgeklammert, unnötig bei vorsortierem Korpus:)

(: für jede TM-Nummer wird ein Eintrag generiert mit entsprechenden Dateien aus ALTO- und TEI-Korpus :)
where matches($tmAlto, $TM)

(: Aus dem Dateinamen extrahierte Metadaten in Struktur, die Vergleich zu Metadaten der Transkript-Dateien zulässt :)
let $metaAlto :=
<metaAlto source="{$jpgNameAlto}">
{
(: $tmAlto(_$pos1)?(_$pos2)?__[$tail2(.+_$pos3_R.xml)?] :)
let $tail1 := to:substring-after-match($fileNameAlto, '_')
let $pos1 := to:chars($tail1)[1]
let $tail2 := to:substring-after-match($fileNameAlto, '__')
let $body3 := substring-before($tail2, '_R.xml') 
let $pos3 := to:substring-after-last-match($body3, '_')
return (
    <side>{
    if (matches($pos1,'[rv]'))
        then if(matches($pos1,'r'))
            then 1
            else 2
        else if (matches($tail2, '_\d_\d+'))
            then xs:integer(to:substring-before-match(to:substring-after-match($tail2, '_'), '_'))
            else 1        
    }</side>,
    <noRom>{
    if (matches($pos1,'i+'))
    then to:roman-numeral-to-integer($pos1)
    else if (matches($pos3, '\d+'))
        then xs:integer($pos3)
    else 0
    }</noRom>,
(:    <sectionArab>{
    if (matches($pos1,'\d+-\d+'))
    then 
    <section from="{to:substring-before-match($pos1,'-')}" to="{to:substring-after-match($pos1,'-')}">{$pos1}</section>
    else 0
    }</sectionArab>, :)
    <part>{
    if (matches($pos1,'[ABCDEFGH]'))
    then $pos1
    else if (matches($pos3, '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]'))
        then $pos3
    else '0'
    }</part>
)}    
</metaAlto>

(: Alto- und TEI-Dateien werden zunächst anhand der TM Nummer zugeordnet :) 

let $transcriptFile := for $file in $corpusTranscript//file 
    where matches(distinct-values($file//name/text()), $tmAlto)       
    return (:<file n="{$posTM}" name="{$TM}">{:)
     if (matches(distinct-values($file//name/text()), $tmAlto))
     then $file
     else ()(:}</file>:)

(:  (: Zusammenhängende Teile der Transkription der einzelnen Dateien :)
let $fileNameVersion := to:substring-before-match($fileNameAlto,'.xml')
return 
file:write(concat("file:///", $destinationAUX, $fileNameVersion, '_tF_3.4',".xml"), $transcriptFile)
:)



(: In match geschriebene textparts orientieren sich an GrafikURL-match und ZeilenAnzahl-match :)
let $transcriptTextpart :=
<transcriptTextpart>{
(:
    for $textpart at $pos in $transcriptFile//textpart 
    where not($textpart//type = '')
    let $graphicTEI := to:substring-after-last-match($textpart/graphic/text(),'/')
:)   
(: ### Grafik-URL wird anhand der vorher zusammengefassten Parent-Elemente <textGraphik> betrachtet ### :)
    
  
  for $cohesive at $pos in $transcriptFile//cohesiveTextparts
    where not($cohesive/data(@graphic) = 'N/A' or $cohesive/data(@graphic) = '')
    
    let $graphicTEI := to:substring-after-last-match($cohesive/data(@graphic),'/')
    
(: Aus dem Dateinamen der Grafik-URL extrahierte Metadaten in Struktur, die Vergleich zu Metadaten der Alto-Dateien zulässt :)    
    let $metaTEI :=
<metaTEI source="{$graphicTEI}" n="{$pos}">
{

(: $tmAlto(_$pos1)?(_$pos2)?__[$tail2(.+_$pos3_R.xml)?] :)
let $graphicNo := (for $m in to:get-matches($graphicTEI, '\d+') where not($m='') return $m)[1] 
let $tail := to:substring-after-match($graphicTEI, $graphicNo)
let $body := substring-before($tail, '.jpg')

return (
    <side>{
    if (matches($tail,'_'))
        then let $sideInfo := 
            to:substring-before-if-contains(to:substring-after-match($body, '_'), '_')
            return if (matches($sideInfo,'[rRvV]'))
            then if (matches($sideInfo,'[rR]'))
                then 1
                else 2
            else if (matches($sideInfo,'\d'))
                then xs:string(to:extract-numeral($sideInfo))
                else 0
        else if (matches($tail,'v.jpg'))
        then 2
    else 1
    }</side>,
    <noRom>{ 
    if (matches($body,'-Kol-'))
        then let $romBody := to:substring-before-if-contains(to:substring-after-match($body,'-Kol-'), '_')
            let $romValues := for $m in to:get-matches($romBody, '[IVX]+') where not($m='') return to:roman-numeral-to-integer($m)
        return if(not(exists($romValues[2])))
            then $romValues
            else (:string-join($romValues,'-'):)(
        <from>{$romValues[1]}</from>,
        <to>{$romValues[2]}</to>
        )        
     else 0 
    
    }</noRom>,
(:    <sectionArab/>, :)
    <part>{
    if (matches($body,'Pl-\w_R'))
        then substring-before(substring-after($body, 'Pl-'), '_')
        else '0'
    }</part>
)}    
</metaTEI>    
    
(: transcriptTextpart wird mit seinen ursprünglichen Textparts und den dazugehörigen Metadaten gefüllt :)   

return (:(
$metaTEI,:)
(: for $textpart in $cohesive//textpart  :)  (:###:)
(:
for $alto in $dataAlto 
    return (:$textpart :)
:)
<textpartMeta>{    
    $metaAlto,
    $metaTEI(:,
    $cohesive:)
    
    (:$textpart:)
    (:<mode>{
    (: if (matches($metaTEI/data(@source), $jpgAlto))
        then 'URL' :)
    if (for $t in $textpart//text 
    where count($t//line)=$linesAlto return $t)
        then 'COUNT'
    else 'N/A'  
    }</mode>:)
}</textpartMeta>

(:):)
}</transcriptTextpart>

(: anhand der Metadaten werden die Textparts ermittelt, die auf die aktuelle Grafik der Alto-Datei passen :)
let $match := 

let $graphics := distinct-values($transcriptTextpart/textpartMeta//metaTEI/data(@source))
let $altoNo := $metaAlto/noRom/xs:integer(node())
    

(:for $t in $transcriptTextpart/textpartMeta         :)        (:### $transcriptTextpart ###:)
(:let $textparts := for $tT in $transcriptTextpart/textpartMeta[to:is-value-in-sequence(metaTEI/data(@source), $graphics)][1] return $tT
for $t in $textparts :)
for $t in $transcriptTextpart/textpartMeta(:[to:is-value-in-sequence(metaTEI/data(@source), $graphics)]:)
  
    let $text := $corpusTranscript//cohesiveTextparts[to:substring-after-last-match(data(@graphic),'/') = $t//metaTEI/data(@source)]
    let $name := distinct-values($text//textpart/name/text())
    where 
    $t/metaTEI/side = $metaAlto/side and 
    ($t/metaTEI/noRom = $metaAlto/noRom or 
        ($t/metaTEI/noRom/from/xs:integer(node()) <= $altoNo and 
        $t/metaTEI/noRom/to/xs:integer(node()) >= $altoNo))                 (: and xs:integer($t//textpart/data(@n)) = $altoNo):)  
    and $t/metaTEI/part = $metaAlto/part 
    
    return    
        (:for $i in $text return :)
  <match name="{$name}">
    {$metaAlto}
    <linesAlto>{$linesAlto}</linesAlto>
    <altoGraphic>{$jpgAlto}</altoGraphic>
    {(
    <lines>{count($text//text[1]//line)}</lines>,
    <graphic>{distinct-values($text//graphic/text())}</graphic>,
    <name>{$name}</name>,
    $text//textpart
    )}
  </match>


(:  (: Liste der engeren Auswahl passender Zuordnungen von Alto und TEI Dateien in $transcriptTextpart und abgeschlossene Zuordnung in $match :)
let $fileNameVersion := to:substring-before-match($fileNameAlto,'.xml')
return (
file:write(concat("file:///", $destinationAUX, $fileNameVersion, '_tT_3.4',".xml"), $transcriptTextpart),
file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '_match', '.xml'), $match)
)
:)

(:  (: Sammlung aller Textparts des Korpus, die in Alto einzufügen sind. Variablendeklaration von $insertTree (Zeile 330) ist zu aktivieren. 
     Jeder match-Eintrag mit x Textparts ist für eine Alto-Datei bestimmt :)
return if (exists($match//textpart)) 
then $match 
else ()
}</root>

return
file:write(concat("file:///", $destinationAUX, 'insertTree_3.5',".xml"), $insertTree) 

:)

(: Sammlung der Zeilen aus den beiden Transkriptionsformen :)

(: Zeilen, die ausschließlich "gap" beinhalten, werden ausgeschlossen. Bzw. nur wenn (auch) token/unknown/supplied vorhanden ist, wird sie verarbeitet. :)

let $Normalised := <norm>{for $textpart in $match//textpart return <textpart>{for $i in $textpart//text[data(@editionType)='normalized']//line[child::token or child::unclear or child::supplied] return $i}</textpart>}</norm>     
let $Diplomatic := <dipl>{for $textpart in $match//textpart return <textpart>{for $i in $textpart//text[data(@editionType)='diplomatic']//line[child::token or child::unclear or child::supplied] return $i}</textpart>}</dipl>

let $fileNameVersion := to:substring-before-match($fileNameAlto,'.xml')


(: für Parameter der Insert-Funktion benötigt :)
let $startValue := 0
let $lineNo := count($Normalised//line)

let $transcriptionI := 1
let $transcriptionII := 2
let $transcriptionIII := 3
let $transcriptionIV := 4

let $fileVersions := ('D1','D2','D3','D4','N1','N2','N3','N4')

(:
return
file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '_normTransII_3.5.xml'), lo:transcription-format($Normalised, $transcriptionII))

:)

let $raw := (lo:transcription-format($Diplomatic, $transcriptionI),
            lo:transcription-format($Diplomatic, $transcriptionII),
            lo:transcription-format($Diplomatic, $transcriptionIII),
            lo:transcription-format($Diplomatic, $transcriptionIV),
            lo:transcription-format($Normalised, $transcriptionI),
            lo:transcription-format($Normalised, $transcriptionII),
            lo:transcription-format($Normalised, $transcriptionIII),
            lo:transcription-format($Normalised, $transcriptionIV))      

return

if ($textOutput) then
for $version at $pos in $fileVersions 
let $textFile := string-join(for $line in $raw[$pos]//line//text()
return concat($line,'
'))

return file:write-text(concat("file:///", $repository, $destinationTXT, $version, '/', $fileNameVersion, '.txt'), $textFile)


else if ($jsonOutput or $xmlOutput) then
for $version at $pos in $fileVersions 
let $jsonFile := string-join((
'{
"head": {
    "tm": "', $match/data(@name), '",
    "side": "', $metaAlto/side/text(), '",
    "noRom": "', $metaAlto/noRom/text(), '",
    "part": "', $metaAlto/part/text(), '",
    "graphicURL": "', $match/graphic/text(), '",
    "graphicName": "', $metaAlto/data(@source), '",
    "textparts": "', count($raw[$pos]//textpart), '",
    "lines": "', count($raw[$pos]//line), '",
    "version": "', $version, '"
    },
    
"body": [
    {
    "textpart": [',
    for $textpart at $posT in $raw[$pos]//textpart return (
    '{
        "n": "', $match//textpart[$posT]/data(@n),'",
        "subtype": "', if (exists($match//textpart[$pos]/@subtype)) then $match//textpart[$pos]/data(@subtype) else 'N/A','",
        "textpartLines": "', count($textpart//line),'",
        "text": [
            ',
        for $line at $posL in $textpart//line return (
        '"', $line//text(), '"',
        if ($posL < count($textpart//line))
            then ', 
            '
            else ']'
            ),
    if ($posT < count($raw[$pos]//textpart))
        then '}, 
        '
        else '}]'
        ),'
    }]
}'       
)) 

let $xmlFile := fn:json-to-xml($jsonFile)

return if ($jsonOutput)
    then file:write-text(concat("file:///", $repository, $destinationJSON, $version, '/', $fileNameVersion, '.json'), $jsonFile)
    else file:write-text(concat("file:///", $repository, $destinationXML, $version, '/', $fileNameVersion, '.xml'), $xmlFile)

else if ($altoOutput) then

(: Boolean, true wenn die Zeilenanzahl übereinstimmt, oder Schalter I deaktiviert ist :)
let $q := ($linesAlto = xs:integer(count($match//textpart/text[1]//line))) or not($onlyMatchingLines) 

(: Beide Quelltranskriptionen (Normalisiert und diplomatisch) werden jeweils in 4 Formate übertragen :)
return if ($q) then
for $version at $pos in $fileVersions 
(:let $alto := lo:copy-or-insert-node($i, 
        $raw[$pos],
        $startValue, $startValue, $lineNo)
:)
let $alto := (

lo:copy-or-insert-node($i, 
        $raw[1]
        , $startValue, $startValue, $lineNo),
    
lo:copy-or-insert-node($i, 
        $raw[2]
        , $startValue, $startValue, $lineNo),
    
lo:copy-or-insert-node($i, 
        $raw[3]
        , $startValue, $startValue, $lineNo),

lo:copy-or-insert-node($i,  
        $raw[4]
        , $startValue, $startValue, $lineNo), 

lo:copy-or-insert-node($i, 
        $raw[5]
        , $startValue, $startValue, $lineNo),

lo:copy-or-insert-node($i, 
        $raw[6]
        , $startValue, $startValue, $lineNo),

lo:copy-or-insert-node($i, 
        $raw[7]
        , $startValue, $startValue, $lineNo),

lo:copy-or-insert-node($i, 
        $raw[8]
        , $startValue, $startValue, $lineNo)
        )

where exists($alto[$pos]/element())


return 

file:write(concat("file:///", $repository, $destinationAlto, $version, '/', $fileNameVersion, '.xml'), $alto[$pos])

(:file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '(d1)', '.xml'), $copyD1), :)

(: Enthält die TEI-textparts mit reduziertem Markup, Metadaten und zusätzlicher Ebene der cohesiveTextparts, 
in der zusammanhängende Textparts nach Grafik-Zugehörigkeit gebündelt sind. Diese Bündelung entspricht dem Inhalt einer Alto-Datei :)
(:file:write(concat("file:///", $destinationAUX, 'corpusTranscript_3.3',".xml"), $corpusTranscript),

(: enthält für jede Alto-Datei der Iteration eine Vergleichstabelle mit möglicherweise passenden Textparts der TEI-Dateien, 
aus denen anschließend die Übereinstimmungen ausgewählt werden. Nur für Fälle mit mehreren Kolumnen notwendig :)
file:write(concat("file:///", $destinationAUX, 'transcriptTextpart_3.3',".xml"), $transcriptTextpart),
file:write(concat("file:///", $destinationAUX, 'match_3.3',".xml"), $match) 
:)


(:
(
file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '(d2)', '.xml'), $copyD2),
file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '(d3)', '.xml'), $copyD3), 
file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '(d4)', '.xml'), $copyD4), 
file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '(n1)', '.xml'), $copyN1),
file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '(n2)', '.xml'), $copyN2),
file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '(n3)', '.xml'), $copyN3),
file:write(concat("file:///", $repository, $destinationAlto, $fileNameVersion, '(n4)', '.xml'), $copyN4)  
)
:)
else ()

else ()
