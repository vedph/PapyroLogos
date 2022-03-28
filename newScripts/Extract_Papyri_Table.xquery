xquery version "3.1";
declare namespace lo = "http://www.w3.org/2005/xquery-local-functions"; 
declare namespace functx = "http://www.functx.com";
declare namespace TEI = "http://www.tei-c.org/ns/1.0";
declare namespace ns-v4 = "http://www.loc.gov/standards/alto/ns-v4#";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare variable $parameter := doc("/db/PapyroLogos/serialization-parameters.xml")/output:serialization-parameters;
declare variable $inputChar  := "ΌΏΎΊΉᾲᾀᾁᾂᾃᾅᾇέάΐήώίόύϝϛϋϊᾄᾆᾳᾴᾷαβγδεζηθικλμνξοπρστυφχψωἀἄἂἆἁἅἃἇάὰᾶἐἔἒἑἕἓὲέἠἤἢἦἡἥἣἧὴήᾐᾑᾒᾓᾔᾕᾖᾗῂῃῄῆῇἰἴἲἶἱἵἳἷὶίῐῑῒΐῖῗὀὄὂὁὅὃὸόὐὑὒὓὔὕὖὗὺῦύῠῡῢΰῧὠὤὢὦὡὥὣὧώὼᾠᾡᾢᾣᾤᾥᾦᾧῲῳῴῶῷῤῥἈἌἊἎἉἍἋἏᾺΆᾼᾈᾉᾊᾋᾌᾍᾎᾏἘἜἚἙἝἛῈΈἨἬἪἮἩἭἫἯῊΉῌᾘᾙᾚᾛᾜᾝᾞᾟἸἼἺἾἹἽἻἿΊῚῘῙὈὌὊὉὍὋΌῸὙὝὛὟΎῪῨῩὨὬὪὮὩὭὫὯΏῺῼᾨᾩᾪᾫᾬᾭᾮᾯῬςϲϹ";
declare variable $outputChar := "ΟΩΥΙΗΑΑΑΑΑΑΑΕΑΙΗΩΙΟΥϜϚΥΙΑΑΑΑΑΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΑΑΑΑΑΑΑΑΑΑΑΕΕΕΕΕΕΕΕΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΙΙΙΙΙΙΙΙΙΙΙΙΙΙΙΙΟΟΟΟΟΟΟΟΥΥΥΥΥΥΥΥΥΥΥΥΥΥΥΥΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΡΡΑΑΑΑΑΑΑΑΑΑΑΑΑΑΑΑΑΑΑΕΕΕΕΕΕΕΕΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΗΙΙΙΙΙΙΙΙΙΙΙΙΟΟΟΟΟΟΟΟΥΥΥΥΥΥΥΥΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΩΡΣΣΣ";
declare variable $params := 
<output:serialization-parameters 
        xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
  <output:omit-xml-declaration value="yes"/>
  <output:encoding value="utf-8"/>
  <output:method value="text"/>
  <output:indent value="yes"/>
</output:serialization-parameters>;
declare variable $imageList := doc("/db/PapyroLogos/ImageData.xml");

declare function functx:substring-after-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-after($arg,$delim)
   else $arg
 } ;

declare function functx:name-test
  ( $testname as xs:string? ,
    $names as xs:string* )  as xs:boolean {

$testname = $names
or
$names = '*'
or
functx:substring-after-if-contains($testname,':') =
   (for $name in $names
   return substring-after($name,'*:'))
or
substring-before($testname,':') =
   (for $name in $names[contains(.,':*')]
   return substring-before($name,':*'))
 } ;

declare function functx:remove-elements-not-contents
  ( $nodes as node()* ,
    $names as xs:string* )  as node()* {

   for $node in $nodes
   return
    if ($node instance of element())
    then if (functx:name-test(name($node),$names))
         then functx:remove-elements-not-contents($node/node(), $names)
         else element {node-name($node)}
              {$node/@*,
              functx:remove-elements-not-contents($node/node(),$names)}
    else if ($node instance of document-node())
    then functx:remove-elements-not-contents($node/node(), $names)
    else $node
 } ;

declare function local:lbToP( $nodes as node()* ) as node()*{
for $each in $nodes return
typeswitch ( $each )
case element() return
    if( $each/TEI:lb ) then (
        if( $each/TEI:lb[1]/preceding-sibling::node() ) then element { node-name($each) } {$each/@*,local:lbToP( $each/TEI:lb[1]/preceding-sibling::node() )}
            else (), for $lb in $each/TEI:lb[preceding-sibling::TEI:lb] return element { node-name($each) } {$each/@*, local:lbToP( $lb/preceding-sibling::node()[.>>$lb/preceding-sibling::TEI:lb[1]] )},
            if( $each/TEI:lb[last()]/following-sibling::node() ) then element { node-name($each) } {$each/@*, local:lbToP($each/TEI:lb[last()]/following-sibling::node() )}
                else ())
     else element { node-name($each) } { $each/@*, local:lbToP( $each/node() ) }
default return $each};

declare function local:gtype($node as node()) as item() {
 switch($node/@type)
    case "anti-sigma" return "&#0891;"
    case "apostrophe" return "&#2019;"
    case "asteriskos" return "&#0042;"
    case "backslash" return "&#0092;"
    case "backtick" return "&#0891;"
    case "check" return "/"
    case "chi-periestigmenon" return "&#0183;&#0935;&#0183;"
    case "chirho" return "&#2627;"
    case "coronis" return "&#11790;"
    case "cross" return "†"
    case "dagger" return "&#8224;"
    case "dash" return "&#2014;"
    case "di-punctus" return "&#2236;"
    case "diastole" return "’"
    case "diple" return "›"
    case "diple-obelismene" return "⤚"
    case "dipunct" return "∶"
    case "dot" return "•"
    case "dotted-obelos" return "⸓"
    case "downwards-ancora" return "⸔"
    case "filled-circle" return "⦿"
    case "filler" return "&#2015;"
    case "high-puctus" return "˙"
    case "high-punctus" return "˙"
    case "high-puncuts" return "˙"
    case "hyphen" return "-"
    case "hypodiastole" return "⸒"
    case "long-vertical-bar" return "&#0124;"
    case "low-punctus" return "."
    case "middot" return "&#0183;"
    case "obelos" return "―"
    case "parens-deletion-closing" return "&#9132;"
    case "parens-deletion-opening" return "&#9128;"
    case "parens-lower-closing" return "&#9120;"
    case "parens-lower-opening" return "&#9117;"
    case "parens-middle-closing" return "&#9119;"
    case "parens-middle-opening" return "&#9116;"
    case "parens-upper-closing" return "&#9118;"
    case "parens-upper-opening" return "&#9115;"
    case "parens-punctuation-closing" return "&#9132;"
    case "parens-punctuation-opening" return "&#9128;"
    case "parent-punctuation-opening" return "&#9128;"
    case "percent" return "%"
    case "reverse-dotted-obelos" return "&#0183;&#0092;&#0183;"
    case "rho-cross" return "&#11496;"
    case "s-etous" return "&#65913;"
    case "short-vertical-bar" return "&#0712;"
    case "sinusoid-stroke" return "&#57751;"
    case "slanting-stroke" return "&#0047;"
    case "slashed-N" return "N"
    case "stauros" return "&#8224;"
    case "tetrapunct" return "&#8280;"
    case "tilde" return "&#0126;"
    case "tripunct" return "&#8942;"
    case "upward-pointing-arrowhead" return "&#8599;"
    case "upwards-ancora" return "⸕"
    case "x" return "&#2613;"
    case "xs" return "&#2613;"
    default return ""
};

declare function local:gap($node as node()) as item() {
 if ($node[@unit="line"]) then "" else
 if ($node[@reason = "illegible"]) then (if ($node/@quantity) then string-join(for $i in 1 to (data($node/@quantity)) return "-") else string-join(for $i in 1 to (data($node/@atLeast)) return "-")) else
 if ($node[@extent="unknown"]) then "[-  -]" else
 if ($node[@quantity]) then concat("[", string-join((for $i in 1 to data($node/@quantity) return "-")), "]") else
 if ($node[@atLeast]) then concat("[", string-join((for $i in 1 to (data($node/@atLeast)) return "-")), "]")
 else "[  ]"
};

declare function local:milestone($node as node()) as item() {
    switch($node/@rend)
    case "paragraphos" return "&#10;——"
    case "horizontal-rule" return "&#10;————————"
    case "diple-obelismene" return "&#10;>---"
    case "wavy-line" return "&#10;~~~~~~~~"
    case "box" return ""
    default return ""
};
declare function local:hi($nodes as node()*) as xs:string* {
    for $node in $nodes return
    switch($node/@rend)
    case "diaeresis" return concat(string-join(local:transform($node/node())), "&#0776;")
    case "asper" return concat(string-join(local:transform($node/node())), "&#0788;")
    case "acute" return concat(string-join(local:transform($node/node())), "&#0769;")
    case "circumflex" return concat(string-join(local:transform($node/node())), "&#0834;")
    case "grave" return concat(string-join(local:transform($node/node())), "&#0768;")
    case "lenis" return concat(string-join(local:transform($node/node())), "&#0787;")
    case "overdot" return concat(string-join(local:transform($node/node())), "&#0775;")
    case "underlined" return for $i in 1 to string-length(string-join($node//text())) return concat(substring(string-join($node//text()), $i,1), "&#0818;")
    case "underline" return for $i in 1 to string-length(string-join($node//text())) return concat(substring(string-join($node//text()), $i,1), "&#0818;")
    case "supraline" return for $i in 1 to string-length(string-join($node//text())) return concat(substring(string-join($node//text()), $i,1), "&#0773;")
    case "supraline-underline" return for $i in 1 to string-length(string-join($node//text())) return concat(substring(string-join($node//text()), $i,1), "&#0773;&#0818;")
    case "tall" return local:transform($node/node())
    case "subscript" return local:transform($node/node())
    case "pause" return local:transform($node/node())
    case "superscript" return local:transform($node/node())
    case "above" return local:transform($node/node())
    default return local:transform($node/node())
};

declare function local:transform($nodes as node()*) as item()* {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return replace($node, "[ʼ†∙·•\n\{\}\(\)\\',;:\.\-⏑̆͂᾽᾿῎῞῾`΄“”’̓ʽ‘\s]", "") 
            case element(TEI:p) return element {"p"} {local:transform($node/node())}
            case element(TEI:gap) return local:gap($node)
            case element(TEI:supplied) return concat("[", string-join(for $i in 1 to string-length(replace(string-join(local:transform($node//text())), "\s","")) return "-"), "]")
            case element(TEI:space) return " "
      (:To switch between D2 and D4 chose the first or second option in case element(TEI:unclear) and replace D2 with D4 (and vice versa) in lines 254 and 279 :)     
            case element(TEI:unclear) return replace(string-join(local:transform($node/text())), concat("[", $inputChar, "]"), "-") (:for $i in 1 to string-length(string-join($node//text())) return concat(substring($node/text(), $i,1), "&#0803;"):) 
            case element(TEI:lb) return if ($node/@n = "1") then "" else "&#10;"
            case element(TEI:div) return local:transform($node/node())
            case element(TEI:g) return local:gtype($node)
            case element(TEI:milestone) return local:milestone($node)
            case element(TEI:hi) return local:hi($node)
            case element(TEI:num) return if ($node[rend="tick"]) then concat(local:transform($node/node()),"'") else local:transform($node/node())
            case element(TEI:subst) return local:transform($node/TEI:add/node())
            case element(TEI:app) return local:transform($node/TEI:lem)
            case element(TEI:lem) return local:transform($node/node())
            case element(TEI:certainty) return ""
            case element(TEI:q) return local:transform($node/node())
            case element(TEI:orig) return local:transform($node/node())
            case element(TEI:sic) return local:transform($node/node())
            case element(TEI:expan) return if ($node/text()) then local:transform($node/node()) else concat("(", string-join($node//text()) , ")")
            case element(TEI:ex) return ""
            case element(TEI:figure) return ""
            case element(TEI:figDesc) return ""
            case element(TEI:surplus) return local:transform($node/node())
            case element(TEI:foreign) return local:transform($node/node())
            case element(TEI:handShift) return ""
            case element(TEI:desc) return ""
            case element(TEI:abbr) return local:transform($node/node())
            case element(TEI:note) return ""
            case element(TEI:w) return ""
            case element(TEI:seg) return local:transform($node/node())
            case element(TEI:locus) return ""
            case element(TEI:ref) return ""
            case element(TEI:del) return ""
            case element(TEI:ex) return ""
            case element(TEI:rdg) return ""
            case element(TEI:corr) return ""
            case element(TEI:reg) return ""
            case element(TEI:note) return ""
            case element(TEI:add) return ""
            case element(TEI:choice) return local:transform($node/TEI:orig)
            case element(TEI:app) return concat(string-join(local:transform($node/TEI:lem)), string-join(local:transform($node/TEI:orig))) 
            case comment() return ""
            default return local:transform($node/node())
            };



for $papyrus in distinct-values(data($imageList/root/row/TM))
(: chose here the corpus to search: it is much quicker to limit the script to either DCLP (first, literary papyri) or DDbDP (second, documentary papyri) :)
let $corpus := collection("/db/DCLP/DCLP") (: union collection("/db/DDB_EpiDoc_XML") :)
let $file := $corpus/TEI:TEI[data(TEI:teiHeader/TEI:fileDesc/TEI:publicationStmt/TEI:idno[@type="TM"][1])=$papyrus]
let $text := functx:remove-elements-not-contents($file/TEI:text/TEI:body/TEI:div[@type="edition" and @xml:lang="grc"], 'q')
let $imageGroup := $imageList/root/row[TM=$papyrus]/fileName/text()
let $imageNumber := count($imageGroup)
let $correspLinks := $file/TEI:TEI/TEI:teiHeader/TEI:fileDesc/TEI:sourceDesc/TEI:msDesc/TEI:additional/TEI:adminInfo/TEI:custodialHist/TEI:custEvent[@type="imaged" and @corresp=$text//TEI:div/@corresp]/TEI:graphic/@url
let $textParts := if (count(distinct-values($correspLinks))=$imageNumber) then $text//TEI:div[@corresp] else
                        if (count($text//TEI:ab) = $imageNumber) then $text//TEI:ab/parent::TEI:div else
                        if (count($text//TEI:ab/parent::TEI:div/parent::TEI:div) = $imageNumber) then $text//TEI:ab/parent::TEI:div/parent::TEI:div else
                        $text/TEI:div
for $image at $pos in $imageGroup
let $fragment := $textParts[$pos]
let $fileName := concat(substring($image, 1, (string-length($image)-3)), "json")
(:return concat($papyrus, "  ", $image, "  ", $fileName, "  ",$pos, "  ", string-join($fragment/@n), "&#10;"):)
let $graphic := tokenize(data($file/TEI:TEI/TEI:teiHeader/TEI:fileDesc/TEI:sourceDesc/TEI:msDesc/TEI:additional/TEI:adminInfo/TEI:custodialHist/TEI:custEvent[@type="imaged" and @corresp=$fragment/@corresp]/TEI:graphic/@url), '/')[last()]
let $jsonHead :=
            concat('{ 
        "head": { 
        "tm": "', $papyrus, '",
        "graphicName": "', $image, '",
        "textparts": "', count($fragment//TEI:ab), '",&#10;
        "lines": "', sum($fragment//TEI:lb[last()]/@n), '",
        "version": "', 'D2', '"
            },&#10;
        "body": [')
let $jsonTexts := 
string-join(
for $textpart in $fragment//TEI:ab
let $lines := (
for $line in (local:lbToP($textpart))
let $lineContent := translate(replace(string-join(local:transform($line)), "\]\[", ""), $inputChar, $outputChar)
where not($lineContent="")
return <p xmlns="http://www.tei-c.org/ns/1.0">{replace($lineContent, "\[(-+)  (-+)\]", "[? ?]")}</p>)
return
        concat('{
            "textpart": [{
        "n": "', data($textpart/parent::TEI:div/@n), '",
        "subtype": "', data($fragment/ancestor::TEI:div[@subtype][1]/@subtype), '",
        "textpartLines": "', count($lines), '",
        "text": [&#10;', string-join(for $l in $lines[position() < last()] return (concat('"', $l/text(),'",&#10;'))), 
        '"', $lines[last()]/text(),'"]}]&#10;
        },')
        )
let $output := <a>{concat($jsonHead, substring($jsonTexts,1, string-length($jsonTexts)-1), ']&#10;}&#10;')}</a>


return
file:serialize($output, (concat("file:///C:/test/json/D2/", $fileName)), $params)
