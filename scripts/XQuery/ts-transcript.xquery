xquery version "3.1";
module namespace ts = "transcript";
import module namespace to = "tool" at "file:///C:/Datenbanken/OCR/PapyroLogos/scripts/XQuery/to-tool.xquery";     (: UPDATE PATH :)


(: ### Pfade zu Verzeichnissen und Dateien ### :)

(: parent folder containing PapyroLogos :)
declare variable $ts:repository := 'C:/Datenbanken/OCR/';                           (: UPDATE PATH :)

(: # 2. SCHALTER II = false # :)
(: Nur falls im Korpus Verweise auf Drittdateien vorkommen, was nach aktuellen Stand nicht mehr relevant sein sollte
    declare variable $ts:fileCustEvent := concat($ts:repository, 'PapyroLogos/documents/', 'custEvent.xml'); :)

(: Zuordnungstabelle von Griechisch mit Akzenten zu normalisierten Majuskeln :)
declare variable $ts:tableGreek := doc(concat('file:///', $ts:repository, 'PapyroLogos/documents/', 'greek_norm.xml'));   (: UPDATE PATH :)


(: ### Lokale Variablen und Funktionen ### :)

(: Elemente, die in keinem Fall übernommen werden :)
declare variable $ts:ignore := ("del", "ex", "rdg", "corr", "reg", "note"
);

declare function ts:strip-elements($elements as element()*) as element()* {
for $element in $elements return 
if (to:is-value-in-sequence(name($element), $ts:ignore))
    then () else $element 
};   

(: Befreit string von unerwünschten Leer- und Satzzeichen, die in der Transskription der Papyri vorkommen :)
(: Über die Variablen normalize und diplomatic kann eingestellt werden, wann welche Zeichen entfernt werden sollen:
 normalize wird immer angewendet, diplomatic nur für die zweite part des Textparts, sowie zum zählen für Zeichen (z.B. für supplied)
:)
declare function ts:strip-string($string as xs:string*, $diplomatic as xs:boolean) as xs:string*{
let $normalize := "†∙•\n\{\}\(\)\\"
let $diplomatic := "͂“”:̆⏑,᾽᾿῎῞῾\-;`΄’'̓ʽ‘·\s\."
return
if ($diplomatic)
    then string-join(tokenize(
        normalize-space(normalize-unicode($string)), concat("[",$normalize,$diplomatic,"]")))
    else string-join(tokenize(
        normalize-unicode($string), concat("[",$normalize,"]")))
};

(: Normalisiert die Zeichen entsprechend der Zuordnungsdatei 'greek-norm.xml' zu Großbuchstaben ohne Ergänzungen :)
declare function ts:normalize-string($string as xs:string*, $diplomatic as xs:boolean) as xs:string*{
let $stripped := ts:strip-string($string, $diplomatic)
let $norm := 
for $char in to:chars($stripped) return
if (to:is-value-in-sequence($char, $ts:tableGreek//orig//fn:normalize-unicode(string())))
    then for $entry in $ts:tableGreek//orig where fn:normalize-unicode($entry/string())=$char 
    return $entry/following-sibling::maju/string()
else (:if (to:is-value-in-sequence($char, $ts:tableGreek//maju)) then :)             (: zu griechischer Zuordnungstabelle hinzukommende Zeichen befinden sich in additionalCharacter.xml|_distinct.xlsx:)
$char 
(: else concat('additionalCharacter[',$char,']') :)
return string-join($norm)
};

(: Erstellt die umstrukturierten Elemente nach Aufruf von restructure-node() :)
declare function ts:construct-element($node as node(), $s as xs:string, $parent as xs:string) as node()* {
let $siblings := if ($parent='head') 
    then $node//element()[name()=$s][1]//preceding-sibling::node()
    else if ($parent='tail') 
    then $node//element()[name()=$s][1]//following-sibling::node()
    else ()
return 
element {$node/name()} {attribute type {$parent}, 
if ($node/element()[name()=$s])
    then for $child in $siblings       
    return $child
else if ($node//element()[name()=$s])
    then for $element in ts:strip-elements($node/element())
    return ts:restructure-node($element, $s, $parent)
    else ()
}};

(: Restrukturiert Element, in dem <lb/> vorkommt, sodass Element und <lb/> im Output auf sibling-Achse liegen  :)
(: wird von handle-markup() aufgerufen um gesamten Textpart zu homogenisieren und wieder an restructure-lines zu übergeben :)
(: $s ist das Element (lb), das alle ancestor-Elemente bis auf ursprüngliche $node Ebene (rekursiv) aufspaltet/verdoppelt  :)
(: Bei Rekursivaufruf ist $parent entweder 'head' oder 'tail', um Nachkommen entsprechend einzuordnen  :)
declare function ts:restructure-node($node as node(), $s as xs:string, $parent as xs:string) as node()* {
let $restructuredNodes := 
if (exists($node//element()[name()=$s])) 
    then if ($parent = 'head' or $parent = 'tail') 
        then ts:construct-element($node, $s, $parent)
    else if ($parent = '') 
    then 
    (
    ts:construct-element($node, $s, 'head'),
    element {$s} {attribute {'n'} 
        {
        $node//element()[name()=$s]
        [not(to:is-value-in-sequence(true(), for $i in ancestor::element() 
            return to:is-value-in-sequence(name($i), ($ts:ignore))))]/data(@n)  
        }, 
        attribute type {'constructed'}},
    ts:construct-element($node, $s, 'tail')
    )
    else ()
else $node   
return $restructuredNodes 
};

(: wandelt ursprüngliches Markup in angefordertes Markup um :)
(: Je nach übergebenem boolean werden <lb/> ignoriert oder entsprechende ancestor an restructure-node() übergeben :)
declare function ts:handle-markup($node as node(), $restructured as xs:boolean) as node()* {
let $token :=
(:if ($node instance of text() and not(ts:normalize-string(xs:string($node), true())='')) 
    then <token>{ts:normalize-string($node)}</token> #2.0# :)
if ($node instance of text() and not(xs:string($node)='')) 
    then if (not(ts:strip-string($node, false()) = '')) 
        then <token>{ts:strip-string($node, false())}</token> 
        else ()
    
    else if ($node instance of element())
  then 
  if (empty(ts:strip-elements($node)))
      then ()
(: Ggf. müssen zunächst einzelne Elemente umstrukturiert werden, um Nachkommen-<lb/> handhaben zu können :)    
  else if (not($restructured))    
      then if ($node/name()="lb")
          then $node  
      else if (exists($node//element()[name()='lb']) and not(name($node)='add'))
          then for $restructuredNode in ts:restructure-node($node, 'lb', '')
          return ts:handle-markup($restructuredNode, $restructured)  
      else ts:handle-markup($node, not($restructured)) 
(: Außerdem werden bestimmte Elemente gesondert ins neue Markup übertragen :)      
  else if ($restructured)  
    then if (name($node)="unclear" and exists($node//text()))
        then <unclear>{ts:strip-string(string-join($node//text()), false())}</unclear>   (:#2.0# ts:normalize-string(string-join($node//text())):)
    else if (name($node)="add")
        then if (exists($node//text())) 
            then
          <add>
            <place>{$node/data(@place)}</place>
             {if (exists($node//element()[name()='lb']))
             then let $textpart := <asTextpart><ab>{for $i in $node/node() return $i}</ab></asTextpart> 
             return ts:restructure-lines($textpart, false(), true())
             else for $child in $node/node() 
             return ts:handle-markup($child, true()) 
          }</add>  
            else ()    
    else if (name($node)="app")    
        then if (exists($node/element()[name()='lem'])) 
            then for $child in $node/element()[name()='lem']/child::node() 
            return ts:handle-markup($child, true()) else ()        
    else if (name($node)="choice")      
        then if (exists($node/child::element()[name()='sic']) or exists($node/child::element()[name()='orig']))     
            then for $child in $node/child::element()[name()="sic" or name()="orig"]/child::node() 
            return ts:handle-markup($child, true()) else ()
    else if (name($node)="supplied" and not($node/data(@reason)="omitted"))         
        then let $text := for $n in $node/child::node() return ts:handle-markup($n, true())
        let $token := if ($text/name()="token" or $text/name()="unclear")
            then $text/descendant-or-self::element()[name()="token" or name()="unclear"]//text()
            else ()
        let $quant := count(to:chars(ts:strip-string(string-join($text), true()))) (:#2.0# count(to:chars(ts:strip-string(string-join($text)))):)
            return <supplied>
                    <quantity>{$quant}</quantity>
                    <unit>character</unit> 
                   </supplied>  
    else if (name($node)="gap" or name($node)="space")
        then 
            let $quant := if ($node/data(@quantity)) then $node/data(@quantity) 
                else if ($node/data(@extent)) then $node/data(@extent) 
                else concat($node/data(@atLeast), '-',$node/data(@atMost))
            let $unit := $node/data(@unit)
            return 
                element {$node/name()}{
                    <quantity>{$quant}</quantity>,
                    <unit>{$unit}</unit>
                   }
    else if (exists($node//text())) 
        then for $child in $node/child::node() return ts:handle-markup($child, $restructured) else ()   
    else ()
  else ()  
return $token
};

(: Wandelt <lb/>-Elemente in Vorfahren der zwischenliegenden Geschwisterknoten um :)
(: restructure1 behandelt Markup zeilenweise und direkt in Zielhierarchie, restructure2 behandelt zuerst Markup und strukturiert dann um :)
declare function ts:restructure-lines($nodeTextpart as node(), $restructure1 as xs:boolean, $restructure2 as xs:boolean) as node()* {
let $restructured := if ($restructure1) 
    then
    let $lines := count($nodeTextpart/descendant-or-self::element()[name()="ab" or name()="l"][1]/element()[name()="lb"])    
    let $lineNodes :=
    for $line at $posL in $nodeTextpart/descendant-or-self::element()[name()="ab" or name()="l"][1]/element()[name()="lb"]
    return
    element line { attribute n {if (not($line/data(@n)='')) then to:substring-before-match($line/data(@n), '\s') else 0}, 
    if ($line/data(@type)!='') then attribute type {$line/data(@type)} else (),
    for $node at $posN in $line/following-sibling::node()
        [preceding-sibling::element()[name()="lb"][$posL] and following-sibling::element()[name()="lb"][$lines - $posL] or $posL=$lines] 
        return if ($restructure2) 
            then $node
            else ts:handle-markup($node, $restructure1)
    }
    return $lineNodes
        
else let $textpart := <ab>{
    for $node in $nodeTextpart//descendant-or-self::element()[name()='ab']/child::node() where not(to:is-value-in-sequence($node/name(), $ts:ignore))
    return 
        if (exists($node//element()[name()='lb']))
            then if (name($node)='add') then ts:handle-markup($node, not($restructure1))
            else for $i in ts:restructure-node($node, 'lb', '') where not(to:is-value-in-sequence(name($i),($ts:ignore,'add'))) return ts:handle-markup($i, $restructure1) 
        else ts:handle-markup($node, $restructure1)
    }</ab>
    return ts:restructure-lines($textpart, $restructure2, $restructure2) 
return $restructured
};

declare function ts:generate-diplomatic($text as node()*) as node()*{
for $node in $text/node()[name()!='editionType'] return 
(:if ($node instance of text())
    then if (to:is-value-in-sequence($node/parent::element()/name(), ('token', 'unclear')))
        then ts:normalize-string($node/text(), true())
        else $node/text()
    else ts:generate-diplomatic($node):)

if ($node instance of element())
    then if (to:is-value-in-sequence($node/name(), ('token', 'unclear')))
        then if (ts:normalize-string($node/text(), true())!='')
            then element {$node/name()} {ts:normalize-string($node/text(), true())}
            else ()
        else element {$node/name()} {for $a in $node/@* return attribute {$a/name()} {data($a)}, 
            ts:generate-diplomatic($node)}
    else $node
    
};

(: Wandelt XML-Markup in JSON-Struktur um :)
declare function ts:transform-element-to-json($element as node(), $pos as xs:integer,  $count as xs:integer, $recurse as xs:boolean) as xs:string {
(:(: In jedem Textpart befinden sich eine Version 'normalized' und eine Version 'diplomatic' :)
if ($element/name()='editionType')
then concat('{"editionType": "',$element/text(),'"},
')
:)

(: Line ist immer ancestor der übrigen Elemente in Textparts und kommt in manchen add-Elementen vor  :)
if ($element/name()='line') 
then 
concat(
'{"line":', '[{"number": "',$element/data(@n),'"}',
    if (empty($element/element())) 
        then concat(']}',       
        if ($pos = $count)
            then ']'      
            else ',')
        else concat(',
        ',       
        string-join(for $node at $posN in $element/element() 
        return (ts:transform-element-to-json($node, $posN, count($element/element()), $recurse)))           
            ,'}',
            if ($pos = $count)
            then if ($recurse = false()) then ']'
                else if ($recurse and $element/parent::add)
                    then ']}' 
                    else ''
                else ',
                '))           
else 
(: Alle übrigen Elemente werden entweder übernommen, oder in spezielles Format gebracht :)
let $copy := ('token', 'unclear', 'place')
let $gap := ('gap', 'supplied', 'space')
return
concat('{ "',
$element/name(),'": ',
string-join(
    if (to:is-value-in-sequence($element/name(), $copy))
    then ('"',$element,'"','}')
    else if (to:is-value-in-sequence($element/name(), $gap))       
        then             
        ('{ "quantity": "',$element/quantity,'","unit": "',$element//unit,'"}}')
        else if ($element/name() = "add")
            then ('[',
            for $child at $posC in $element/node() 
            return ts:transform-element-to-json($child, $posC, count($element/node()), true()))
        else ''
    ),'',
if ($pos = $count)
    then concat(']',
    if ($element/parent::add) 
        then '}' 
        else '')      
    else ',
')
};