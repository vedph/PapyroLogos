xquery version "3.1";
import module namespace to = "tool" at "file:///F:/PapyroLogos/scripts/XQuery/to-tool.xquery";                           (: UPDATE PATH :)
import module namespace ts = "transcript" at "file:///F:/PapyroLogos/scripts/XQuery/ts-transcript.xquery";               (: UPDATE PATH :)
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
declare variable $jsonOutput := true();
declare variable $xmlOutput  := false();

(:  ### Pfade zu Verzeichnissen und Dateien ###  :)
declare variable $repository := 'F:/'; (: 'C:/Datenbanken/OCR/'; :)      (: UPDATE PATH :)

(: ## Vorstrukturierung der Transkriptionen ## :)
(: # 1. SCHALTER II = true # :)
declare variable $fileTranscript := concat($repository,'PapyroLogos/documents/corpusTranscript.xml'); (: aus alto-Version 3.4:)

(: # 2. SCHALTER II = false # :)
(: Zuordnungstabelle von Griechisch mit Akzenten zu normalisierten Majuskeln ist im transcript-Modul zu definieren, falls $loadTranscriptFile = false() :)
declare variable $tableGreek := $ts:tableGreek; 

(: Kopie der Tabelle der relevanten Papyri aus GoogleSpreadsheet https://docs.google.com/spreadsheets/d/1kGkPYNpcTaSTe_4ROBwitSlpC0IGNxr4h22p0dZ9VF8/edit#gid=50312864 :)
(: Liste der Dateinamen ersetzt die vorherige Erstellung eines Korpus in $corpusXML :)
declare variable $tablePapyri := concat($repository,'PapyroLogos/documents/listPapyri.xml');

(: Ordner oder Verzeichnis der ursprünglichen XML-Dateien, aus denen Transkript-Daten extrahiert werden sollen 
 Wenn gesamtes Verzeichnis angegeben ist, kann auch ab Zeile 245 auskommentiert werden, um davor den gefilterten Korpus zu erstellen :)

declare variable $corpusXML := concat($repository,'papyri.info/DCLP_2020-12-10'); 
(:declare variable $corpusXMLFiltered := concat($repository,"PapyroLogos/XML/TEI/DCLP@imaged");
:)

(: declare variable $corpusXML := concat($repository,"PapyroLogos/XML/TEI/DCLP@imaged");    :)
(:declare variable $corpusXML := concat($repository,"PapyroLogos/XML/TEI/DCLP_test"); :)


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
                for $iPos in $remainingPos return $insertLines//line[$iPos]//text()
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
    <line>{string-join(replace($line//token//text(), '[\r\n]', ''), ' ')}</line>

(: Wie I; jede Zeichensequenz "unclear" wird durch einen Unterstrich repräsentiert :)
else if ($format=2)
    then for $line in $textpart//line return
    <line>{normalize-space(string-join(
    for $element in $line/element() return 
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
    for $element in $line/element() return 
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
    for $element in $line/element() return 
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
declare function lo:add-dot($n as xs:integer, $iInt as xs:integer, $string as xs:string*) as xs:string* {
if ($iInt < $n)
    then lo:add-dot($n, $iInt+1, concat($string,'.'))
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

(: Kopie der Tabelle der relevanten Papyri aus GoogleSpreadsheet https://docs.google.com/spreadsheets/d/1kGkPYNpcTaSTe_4ROBwitSlpC0IGNxr4h22p0dZ9VF8/edit#gid=50312864 :)
let $tableImagedPapyri := doc(concat('file:///', $tablePapyri))
let $listPapyri := $tableImagedPapyri//TM/text()
let $dataTranscript := collection(concat('file:///', $corpusXML ,'?recurse=yes' )) 

    (: XML-Dokument der $custEventDoc Variable; Sammlung der Elemente mit Link zur Grafik 
        Nur nötig falls Verweise auf Drittdatein vorkommen :)
    (: let $custEventDoc := doc(concat('file:///', $ts:fileCustEvent)) :)

(:  Sammlung der custEvent Einträge des gesamten Verzeichnisses in custEvent.xml -                       
    falls textparts mit ihren @corresp auf custEvents in anderen Dateien zeigen     :)     
    
(: Beinhaltet alle Transkriptionen, um diese anschließend an passender Stelle in die alto-Dateien einfügen zu können 
   Kann in einem Skriptaufruf erzeugt und abgerufen werden, oder die zuerst erzeugte Datei corpusTranscript.xml wird in zweitem Lauf abgerufen
   globale Variable $createCorpusTranscript = true/false einstellen, um diese Varianten zu steuern :)   

(:
(: Um gesamten DCLP Korpus vorher auf die relevanten Listeneinträge zu reduzieren und in :)
for $file in $dataTranscript 
    let $name := to:substring-before-match(to:substring-after-last-match(xs:string(document-uri($i)),'/'),'\.')
    where to:is-value-in-sequence($name, $listPapyri)
    and $i//TEI:custEvent[data(@type="imaged")] 
    return
file:write(concat("file:///", $repository, $corpusXMLFiltered, $name, '.xml'), $file)
:)


let $corpusTranscriptPrep :=

if ($loadTranscriptFile = true())
then doc(concat('file:///',$fileTranscript))/root

else

<root>{
<list>{for $iDataName in $dataTranscript return string-join(to:substring-before-match(to:substring-after-last-match(xs:string(document-uri($iDataName)),'/'),'\.'),'-')}</list>,


for $iData in $dataTranscript 
    where to:is-value-in-sequence(to:substring-before-match(to:substring-after-last-match(xs:string(document-uri($iData)),'/'),'\.'), $listPapyri) 
    and $iData//TEI:custEvent[data(@type="imaged")]   (: generelle Vorsortierung nur imaged :)
let $name := $iData/TEI:TEI/data(@xml:id)
let $textpart := $iData//TEI:div[@type="textpart" or @type="edition"][child::element()/name()='ab' or child::element()/name()='lg'](:[exists(@corresp)]:)
let $target := if($iData//TEI:bibl[@type="online"]) 
    then $iData//TEI:bibl[@type="online"]//TEI:ptr/data(@target) 
    else $iData//TEI:bibl//TEI:ptr/data(@target) 
where not(empty($textpart))               (: Dateien ohne Textpart werden ignoriert :)

return 
(:
file:write(concat("file:///", 'F:/PapyroLogos/XML/TEI/DCLP@imaged_2020-12-10/', to:substring-after-last-match(document-uri($iData),'/')), $iData)
:)

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

(:
return
file:write(concat("file:///", $destinationAUX, 'corpusTranscriptPrep',".xml"), $corpusTranscriptPrep)


:)

(: ### Zur besseren Handhabung von Kolumnen wird in corpusTranscript eine Zwischenebene <cohesiveTextparts> eingezogen (zwischen <file> und <textpart>s) in denen alle textparts gesammelt sind, 
die zur selben Grafik-URL zugeordnet sind. Nach aktueller Kenntnis des Korpus trifft dies bei allen Dateien mit Kolumnen zu. ### :)


let $corpusTranscript := 
if ($loadTranscriptFile = true())
then doc(concat('file:///',$fileTranscript))/root

else 
<root>{
<list>{$corpusTranscriptPrep//list}</list>,
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



let $metaTree :=
<metaTree>{

(: ### Implementierung für eScriptorium Python Script ### :)

for $TM at $posTM in distinct-values($listPapyri)

(: In match geschriebene textparts orientieren sich an GrafikURL-match und ZeilenAnzahl-match :)
let $transcriptTextpart :=
<transcriptTextpart n='{$TM}'>{
(:
    for $textpart at $pos in $transcriptFile//textpart 
    where not($textpart//type = '')
    let $graphicTEI := to:substring-after-last-match($textpart/graphic/text(),'/')
:)   
(: ### Grafik-URL wird anhand der vorher zusammengefassten Parent-Elemente <textGraphik> betrachtet ### :)
    
(: Innerhalb der ersten Zuordnung nach TM-Nummer wird über die zusammenhängenden Textparts iteriert :)  
  for $cohesive at $posC in $corpusTranscript//file[data(@name)=$TM]//cohesiveTextparts
    where not($cohesive/data(@graphic) = 'N/A' or $cohesive/data(@graphic) = '')
    
    let $graphicTEI := to:substring-after-last-match($cohesive/data(@graphic),'/')
    
(: Aus dem Dateinamen der Grafik-URL extrahierte Metadaten in Struktur, die Vergleich zu Metadaten der Alto-Dateien zulässt :)    
    let $metaTEI :=
<metaTEI source="{$graphicTEI}" n="{$posC}" subdiv="{count($cohesive//textpart)}">
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
            let $romValues := 
            if (matches($romBody, '[IVX]+'))
                then for $m in to:get-matches($romBody, '[IVX]+') where not($m='') return to:roman-numeral-to-integer($m)
                else for $m in to:get-matches($romBody, '[0123456789]+') where not($m='') return xs:string(xs:int(($m)))
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
    (:,
    let $subtypes := distinct-values($cohesive//textpart/data(@subtype))
    let $nTEI := distinct-values($cohesive//textpart/data(@n))
    return
    <subtype>
        {for $subtype in $subtypes return <data>{$subtype}</data>}
        {for $n in $nTEI return <n>{$n}</n>}
     </subtype>:)
)}    
</metaTEI>    
    
    
let $metaName :=
let $fileNameOutput := for $fileName in $tableImagedPapyri//FileName 
    where $fileName/preceding-sibling::TM/text() = xs:string($TM) and (not(exists($fileName//following-sibling::Status))    (: wenn Status vorhanden wäre, dann ist dieser Eintrag veraltet :)
            or matches($fileName//following-sibling::Status/text(), 'to be replaced'))         (: vorläufige Einschränkung: "deleted / to be replaced" wird erlaubt :)
    return $fileName
 for $fileName at $posName in $fileNameOutput
 let $fileNameBlank := to:substring-before-match($fileName/text(),'\.') 
 
  return
<metaName source="{$fileNameBlank}" n="{$posName}">
{
(: $tmAlto(_$pos1)?(_$pos2)?__[$tail2(.+_$pos3_R.xml)?] :)
let $tail1 := to:substring-after-match($fileName, '_')
let $pos1 := to:substring-before-match($tail1,'_')              (: to:chars($tail1)[1] unsinniger Ausdruck, auf mögliche bugs achten, falls SOnderfälle nur mit diesem Ausdruck funktioniert haben :)
let $tail2 := to:substring-after-match($fileName, '__')
let $body3 := to:substring-before-last-match($tail2, '_R') 
let $pos3 := to:substring-after-last-match($body3, '_')
let $info := $fileName//following-sibling::TextPart/text()
return (
    <side>{
    if (matches($pos1,'[rv]'))
        then if(matches($pos1,'r'))
            then 1
            else 2
        else if (matches($tail2, '_\d_\d+'))
            then xs:integer(to:substring-before-match(to:substring-after-match($tail2, '_'), '_'))
            else if (matches($info, '(recto|verso)'))
                then if (matches($info, 'recto'))
                    then '1' 
                    else '2'
                else '0'
            
    }</side>,
    <noRom>{
    if (matches($pos1,'i+'))
    then to:roman-numeral-to-integer($pos1)
  (:  Funktioniert mit der Papyri Tabelle als Grundlage nicht mehr
  else if (matches($pos3, '\d+'))
        then xs:integer($pos3)  :)
    else 0
    }</noRom>,
(:    <sectionArab>{
    if (matches($pos1,'\d+-\d+'))
    then 
    <section from="{to:substring-before-match($pos1,'-')}" to="{to:substring-after-match($pos1,'-')}">{$pos1}</section>
    else 0
    }</sectionArab>, :)
    
    <part>{
    if (matches($pos1,'[ABCDEFGH]{1}?'))
    then $pos1
    else if (matches($pos3, '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]{1}?'))
        then if (not(matches($pos3,'\w+\d+')))
            then $pos3
            else '0'
    else '0'
    }</part>,
    
    let $subtype := if (matches($info, '(column|fragment|folio|page)')) 
        then to:get-matches($info, '(column|fragment|folio|page) [ABC\d]+[/\-]?[ABC\d]*')
        else 'undefined' 
    let $n := to:get-matches(to:substring-after-match($info, '(column|fragment|folio|page)'),'[ABC\d]+[/\-]?[ABC\d]*')
    for $match in $subtype where not($match='')
    let $type := for $m in to:get-matches($match, '(column|fragment|folio|page)') where not($m='') return normalize-space($m)
    let $nT := to:substring-after-match($match, '(column|fragment|folio|page) ')
    return 
    (<subtype n='{count($subtype)}'><data>{$type}</data><n>{if (matches($nT,'-')) 
        then (<from>{to:substring-before-match($nT,'-')}</from>,<to>{to:substring-after-match($nT,'-')}</to>)
        else if (matches($nT,'/'))
            then  
                (<div n='1'>{to:substring-before-match($nT,'/')}</div>,<div n='2'>{to:substring-after-match($nT,'/')}</div>)
            else to:get-matches($nT,'[\w\d]+')
    }</n></subtype>)
    
    (:
    return 
    (<subtype n="{count(to:get-matches($info, '(column|fragment|folio|page)'))}">{$subtype}</subtype>,       (: @n ist hier die Anzahl der Angaben in Spalte 'TextPart' der Tabelle :)
    for $i at $posN in $n where not($i='') 
    let $nInfo := normalize-space($i)
    return <n n="{$posN}">{if (matches($nInfo,'-')) 
        then (<from>{to:substring-before-match($nInfo,'-')}</from>,<to>{to:substring-after-match($nInfo,'-')}</to>)
        else if (matches($nInfo,'/'))
            then  
                (<div n='1'>{to:substring-before-match($nInfo,'/')}</div>,<div n='2'>{to:substring-after-match($nInfo,'/')}</div>)
            else $nInfo
   
    }</n>  :)            (: @n ist hier die Position/Anzahl der n-Angaben in der Spalte 'TextPart' der Tabelle (falsche Angabe, wegen empty-strings) :)
    
)}    
</metaName> 
 

    
(: transcriptTextpart wird mit seinen ursprünglichen Textparts und den dazugehörigen Metadaten gefüllt :)   

return (:(
$metaTEI,:)
(: for $textpart in $cohesive//textpart  :)  (:###:)
(:
for $alto in $dataAlto 
    return (:$textpart :)
:)
<textpartMeta>{ 
    $metaTEI,
    $metaName,
    $cohesive
    
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


return
$transcriptTextpart
}</metaTree>

let $match := 

(:
let $graphics := distinct-values($transcriptTextpart/textpartMeta//metaTEI/data(@source))
(:let $altoNo := $metaAlto/noRom/xs:integer(node()):)
:)    

(:for $t in $transcriptTextpart/textpartMeta         :)        (:### $transcriptTextpart ###:)
(:let $textparts := for $tT in $transcriptTextpart/textpartMeta[to:is-value-in-sequence(metaTEI/data(@source), $graphics)][1] return $tT
for $t in $textparts :)


<matchTree>{

for $t in $metaTree/transcriptTextpart(:[to:is-value-in-sequence(metaTEI/data(@source), $graphics)]:)
let $totalTextparts := count($t//textpartMeta)
let $totalTextpartN := $t//textpart//data(@n)
let $existingSides := distinct-values($t//textpartMeta/metaTEI/side/text())
let $matchEntry :=
    (:if (count($t//textpartMeta)=1)    Diese Ebene sollte nicht nötig sein, da kein Unterschied gemacht werden müsste, ob nur ein oder mehrere TEI's gematched werden müssen, immer ist erweitertes Match notwendig
    then:) 
    if (empty($t/element()))
        then <match source='{$t/data(@n)}' type='_'/>
        
    else if (count($t//textpartMeta//metaTEI)=1 and count($t//textpartMeta//metaName)=1)     (: 0: singularMatch :)
        then let $name := $t//metaName/data(@source) 
             let $type := '0' 
             let $textparts := $t//textpart
             return <match source='{$t/data(@n)}' name='{$name}' n='{$totalTextparts}' type='{$type}'><meta>{$t//metaTEI,$t//metaName}</meta>{$textparts}</match>
             
        else 
        for $cohesive in $t//textpartMeta return  
            for $metaName in $cohesive//metaName return
                if (matches(to:substring-after-last($metaName/data(@source),'_'),'\d+\-\d+')        (: Kriterium true, wenn Bild aufgesplittet wurde und dem Dateinamen die Zeilenanzahl im Stil "0-1900" hinzugefügt wurde :)
                   or ($totalTextparts > 1 and to:is-value-in-sequence('2', $existingSides) and $metaName/side/text()='0')
                   (: or $metaName/data(@source)='69389_B__POxy_69_4712_B' :)
                   
                   or (matches($metaName/part/text(),'[A-Z]') and not($metaName/part/text()=$cohesive//metaTEI/part/text()))     (: betrifft v.a. 62580 und 69389; wie bei 62580 wird jedoch match über Part bevorzugt und deshalb mit letzter Ausschlussbedingung an 1.1 weitergereicht :)
                   or $metaName//count(subtype)>1      (:data(@source)='64276__PBerol9917':)  
                   )     (: hier ist dasvon auszugehen, dass sonstige match-Funktionen aufgrund unzureichender Datengrundlage scheitern :)  
                (: ordnet Textpart anhand <div @n> und Metadaten in TextPart Spalte zu :)
                    then let $name := $metaName/data(@source) 
                         let $type := '2' 
                         let $textparts := 
                         if (not(empty($metaName//n/text()))) 
                          then if (count($metaName//subtype)=1 
                            and count(index-of($totalTextpartN,$metaName//n/text()))>1
                            (:count($cohesive//textpart[data(@n)=$metaName//n/text()])>1:)(:    cross-cohesive    and
                         not(exists($cohesive//textpart[(to:is-value-in-sequence(data(@n),$metaName//n/text()) 
                                or (data(@n)>=xs:int($metaName//n/from/text()) and data(@n)<=xs:int($metaName//n/to/text())))
                                and data(@subtype)!=distinct-values($metaName//data)])):))
                                
                            then $cohesive//textpart[((data(@n)=$metaName//n/text() 
                                or data(@n)>=xs:int($metaName//n/from/text()) and data(@n)<=xs:int($metaName//n/to/text()))
                                and data(@subtype)=distinct-values($metaName//data)) 
                              (:  or ($metaName//data/text()=$cohesive//metaTEI//data/text() and $metaName//n/text()=$cohesive//metaTEI//n/text()):)] 
                         
                            else $cohesive//textpart[data(@n)=$metaName//n/text() 
                                or (data(@n)>=xs:int($metaName//n/from/text())) and data(@n)<=xs:int($metaName//n/to/text())] (:[xs:int($metaName/data(@n))]:)
                        else $cohesive//textpart[data(@n)=$metaName//n/text() 
                            or (data(@n)>=xs:int($metaName//n/from/text())) and data(@n)<=xs:int($metaName//n/to/text())] (:[xs:int($metaName/data(@n))]:)
                         
                         return <match source='{$t/data(@n)}' name='{$name}' n='{$totalTextparts}' type='{$type}'><meta>{$cohesive//metaTEI,$metaName}</meta>{$textparts}</match>
                  
        (:    if ($metaName/subtype/data/text()!='undefined')
                then 
          :)    
              
            else if ($metaName//side/text() = $cohesive//metaTEI/side/text()        (: recto|verso :)
            and $metaName//noRom/text() = $cohesive//metaTEI/noRom/text()     (: römische Nummerierung :)
            and $metaName//part/text() = $cohesive//metaTEI/part/text())     
            then let $name := $metaName/data(@source)                           (: 1.0: default metaMatch :)
                 let $type := '1' 
                 let $textparts := $cohesive//textpart
                 return <match source='{$t/data(@n)}' name='{$name}' n='{$totalTextparts}' type='{$type}'><meta>{$cohesive//metaTEI,$metaName}</meta>{$textparts}</match>
                 
            else if (($metaName/side/text() = $cohesive//metaTEI/side/text() or $metaName/side/text()=0 or $cohesive//metaTEI/side/text()=0)        (: mindestens auf einer Seite keine Angabe, match wird zugelassen :)
                    and ($metaName//noRom/text() = $cohesive//metaTEI/noRom/text() or to:is-value-in-sequence($cohesive//metaTEI/noRom/text(),$metaName//n/text()))
                    and ($metaName/part/text() = $cohesive/metaTEI/part/text()))               
            then let $name := $metaName/data(@source)                               (: 1.1 extended metaMatch :)
                 let $type := '3' 
                 let $textparts := $cohesive//textpart
                 return <match source='{$t/data(@n)}' name='{$name}' n='{$totalTextparts}' type='{$type}'><meta>{$cohesive//metaTEI,$metaName}</meta>{$textparts}</match>     
     
             else if ($metaName/subtype/data/text()=$cohesive/subtype/data/text())
                then let $name := $metaName/data(@source)                               (: 1.1 extended metaMatch :)
                 let $type := '4' 
                 let $textparts := $cohesive//textpart
                 return <match source='{$t/data(@n)}' name='{$name}' n='{$totalTextparts}' type='{$type}'><meta>{$cohesive//metaTEI,$metaName}</meta>{$textparts}</match>
           
           
             else  let $name := $metaName/data(@source) 
                  let $type := 'X' 
                  (:let $textparts := $cohesive//textpart:)
                  return <match source='{$t/data(@n)}' name='{$name}' n='{$totalTextparts}' type='{$type}'></match> 
            (:else ():)
return $matchEntry
}</matchTree>    
 
let $matchSort := 
<matchTreeSort>{ 
let $entryNames := distinct-values($match//match/data(@name))   
return 
(
for $entryName in $entryNames order by xs:int(to:substring-before-match($entryName,'_'))
    let $tryMatch := for $entry in $match//match[data(@name)=$entryName] where $entry//textpart order by $entry/data(@type) return $entry
    return $tryMatch[1]
    
,$match//match[not(exists(@name))]
)
}</matchTreeSort>
 

(:  Ausgabe von matchTreeSort, matchSort, metaTree um Zuordnung der Textparts anhand der MetaDaten zu überprüfen    :)

(:
return
file:write(concat("file:///", $destinationAUX, 'transcriptTextpart/', 'matchTreeSort', '.xml'), $matchSort)

:)


(: Iteration um Output zu erzeugen :)

for $match in $matchSort//match where not($match/data(@type)='_')

let $fileName := $match/data(@name)

(: Sammlung der Zeilen aus den beiden Transkriptionsformen :)
(: Zeilen, die ausschließlich "gap" mit @unit=line beinhalten, werden ausgeschlossen. Bzw. nur falls (auch) token/unknown/supplied vorhanden ist, wird sie verarbeitet. :) (: ehemelas, um supplied/lost/illegible etc. in JSON mit aufzunehmen or child::supplied or child::gap[child::unit/text()='character' and child::reason/text()!='lost']:)
let $Normalised := <norm>{<textpart>{for $textpartN in $match//text[data(@editionType)='normalized']//line[child::token or child::unclear] return $textpartN}</textpart>}</norm>     
let $Diplomatic := <dipl>{<textpart>{for $textpartD in $match//text[data(@editionType)='diplomatic']//line[child::token or child::unclear] return $textpartD}</textpart>}</dipl>


(: für Parameter der Insert-Funktion benötigt :)
let $startValue := 0
let $lineNo := count($Normalised//line)

let $transcriptionI := 1
let $transcriptionII := 2
let $transcriptionIII := 3
let $transcriptionIV := 4

let $outputVersions := ('D1','D2','D3','D4','N1','N2','N3','N4')

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
for $version at $posOV in $outputVersions 
let $textFile := string-join(for $line in $raw[$posOV]//line//text()
return concat($line,'
'))

return file:write-text(concat("file:///", $repository, $destinationTXT, $version, '/', $fileName, '.txt'), $textFile)


else if ($jsonOutput or $xmlOutput) then
for $version at $pos in $outputVersions 
let $jsonFile := string-join((
'{
','
"head": {   
    "tm": "', $match/data(@source), '",
    "side": "', $match//metaTEI/side/text(), '",
    "noRom": "', $match//metaTEI/noRom/text(), '",
    "part": "', $match//metaTEI/part/text(),(: '",
    "graphicURL": "', $match/graphic/text(),:) '",
    "graphicName": "', $match//metaTEI/data(@source), '",
    "textparts": "', count($raw[$pos]//textpart), '",
    "lines": "', count($raw[$pos]//line), '",
    "version": "', $version, '"
    },
','
"body": [
    {
    "textpart": [',
    for $textpart at $posT in $raw[$pos]//textpart return (
    '{
        "n": "', $match//textpart[$posT]/data(@n),'",
        "subtype": "', if (exists($match//textpart[$posT]/@subtype)) then $match//textpart[$posT]/data(@subtype) else 'N/A','",
        "textpartLines": "', count($textpart//line),'",
        "text": [
            ',
        for $line at $posL in $textpart//line return (  (:if ($line//text()!='') then ((:let $skip := true() return :):)
        '"', $line//text(), '"',     (: doc: replace($line//text(), '[\r\n]', '') in transcription-format angewendet; aus unbekannten Gründen ist (nur in N1) z.B. in 59099_7 innerhalb mancher Zeilen ein \n aufgetaucht, der die JSON zerstört hat:)
        if ($posL < count($textpart//line) (:and not($skip):))
            then ', 
            '
            else ']'
            )(:else ()):),
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
    then file:write-text(concat("file:///", $repository, $destinationJSON, $version, '/', $fileName, '.json'), $jsonFile)
    else file:write(concat("file:///", $repository, $destinationXML, $version, '/', $fileName, '.xml'), $xmlFile)

else ()


 
