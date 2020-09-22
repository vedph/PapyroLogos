xquery version "3.0";
module namespace to = "tool";
declare namespace TEI = "http://www.tei-c.org/ns/1.0";
declare namespace ar = "https://beatechnologies.wordpress.com/2008/09/25/stripping-namespace-from-an-xml-using-xquery/";
declare namespace functx = "http://www.functx.com";
declare namespace ex = "http://www.ex.com";
declare namespace r = "http://joewiz.org/ns/xquery/roman-numerals";
(:
declare function to:shorten-link
($link as xs:string, $regex as xs:string, $n as xs:integer,             (: call parameter :)
    $tail as xs:string?, $recurse as xs:boolean?) as xs:string? {    (: recurse parameter :)
let $n := $n - 1 
return
if (not(exists($recurse))) 
    then ch:shorten-link($link, $regex, $n, to:substring-after-match($link, $regex), true())
    else if ($n ne 0)
        then ch:shorten-link($link, $regex, $n, to:substring-after-match($tail, $regex), true())
        else to:substring-before-match($link, $tail)

};:)

declare function to:extract-numeral($text as xs:string) { 
    let $ana := analyze-string($text, '\d+')
    let $match := $ana/fn:match[1]/text()
    let $no := to:substring-before-if-contains(to:substring-after-if-contains($match, '\D'), '\D')
    return
        if (exists($no))
        then
            $no
        else
            "0"
};
(: wandelt übergebene Reihe von Strings in Initialien um :)
declare function to:get-initials
($stringSequence as xs:string*) as xs:string {
    if ($stringSequence)
    then
        let $tokens := for $string in $stringSequence
        return
            if (matches($string, '\s'))
            then
                tokenize($string, '\s')
            else
                $string
        return
            string-join(for $token in $tokens
            return
                concat(upper-case(to:chars($token)[1]), "."))
    else
        ""
};

declare function to:roman-numeral-to-integer(: imported from r: :)
($input as xs:string) as xs:integer {
    let $characters := string-to-codepoints(upper-case($input)) ! codepoints-to-string(.)
    let $character-to-integer :=
    function ($character as xs:string) {
        switch ($character)
            case "I"
                return
                    1
            case "V"
                return
                    5
            case "X"
                return
                    10
            case "L"
                return
                    50
            case "C"
                return
                    100
            case "D"
                return
                    500
            case "M"
                return
                    1000
            default return
                error(xs:QName('roman-numeral-error'), concat('Invalid input: ', $input, '. Valid Roman numeral characters are I, V, X, L, C, D, and M. This function is case insensitive.'))
}
let $numbers := $characters ! $character-to-integer(.)
let $values :=
for $number at $n in $numbers
return
    if ($number < $numbers[position() = $n + 1]) then
        (0 - $number) (: Handles subtractive principle of Roman numerals. :)
    else
        $number
return
    sum($values)
};
declare variable $to:romanAlpha as xs:string* :=
("M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I");
declare variable $to:romanNums as xs:integer* :=
(1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1); (:~
converts arabic number to a roman numeral
~:)
declare function to:number-to-roman($num as xs:integer) {
    if ($num = 0) then
        ""
    else
        if ($num > 3999) then
            error(xs:QName("INVALID_ARGUMENT"), "Cannot Convert Number Larger than 3999")
        else
            to:recursive-roman($num, "", $to:romanNums)
};
(:~
Recursion Method used to calculate the roman numeral
~:)
declare function to:recursive-roman(
$num as xs:integer,
$alpha as xs:string,
$sequences as xs:integer*) {
    let $i := $sequences[1]
    let $rom-a := $to:romanAlpha[index-of($to:romanNums, $i)]
    return
        if ($num = 0) then
            $alpha
        else
            if ($num > $i) then
                to:recursive-roman($num - $i, concat($alpha, $rom-a), $sequences)
            else
                if ($num < $i) then
                    to:recursive-roman($num, $alpha, remove($sequences, 1))
                else
                    if ($num = $i) then
                        concat($alpha, $rom-a)
                    else
                        $alpha
};

declare function to:strip-namespace($inputRequest as element()) as element()
{
element {xs:QName(local-name($inputRequest ))}
{
for $child in $inputRequest /(@*,node())
return
if ($child instance of element())
then to:strip-namespace($child)
else $child
}

};
(: imported from functx: :)
declare function to:escape-for-regex
  ( $arg as xs:string? )  as xs:string {

   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;
declare function to:index-of-match-first
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer? {

  if (matches($arg,$pattern))
  then string-length(tokenize($arg, $pattern)[1]) + 1
  else ()
 } ; 
declare function to:replace-first
  ( $arg as xs:string? ,
    $pattern as xs:string ,
    $replacement as xs:string )  as xs:string {

   replace($arg, concat('(^.*?)', $pattern),
             concat('$1',$replacement))
 } ; 
declare function to:get-matches-and-non-matches
  ( $string as xs:string? ,
    $regex as xs:string )  as element()* {

   let $iomf := to:index-of-match-first($string, $regex)
   return
   if (empty($iomf))
   then <non-match>{$string}</non-match>
   else
   if ($iomf > 1)
   then (<non-match>{substring($string,1,$iomf - 1)}</non-match>,
         to:get-matches-and-non-matches(
            substring($string,$iomf),$regex))
   else
   let $length :=
      string-length($string) -
      string-length(to:replace-first($string, $regex,''))
   return (<match>{substring($string,1,$length)}</match>,
           if (string-length($string) > $length)
           then to:get-matches-and-non-matches(
              substring($string,$length + 1),$regex)
           else ())
 } ;
declare function to:get-matches
  ( $string as xs:string? ,
    $regex as xs:string )  as xs:string* {

   to:get-matches-and-non-matches($string,$regex)/
     string(self::match)
 } ;

declare function to:substring-before-match
( $arg as xs:string? ,
    $regex as xs:string )  as xs:string {

   tokenize($arg,$regex)[1]
 } ;
declare function to:substring-before-last-match
($arg as xs:string?,
$regex as xs:string) as xs:string? {
    
    replace($arg, concat('^(.*)', $regex, '.*'), '$1')
};
declare function to:substring-after-match
($arg as xs:string?,
$regex as xs:string) as xs:string? {
    
    replace($arg, concat('^.*?', $regex), '')
};
declare function to:substring-after-last-match
($arg as xs:string?,
$regex as xs:string) as xs:string {
    
    replace($arg, concat('^.*', $regex), '')
};
declare function to:index-of-string
($arg as xs:string?,
$substring as xs:string) as xs:integer* {
    
    if (contains($arg, $substring))
    then
        (string-length(substring-before($arg, $substring)) + 1,
        for $other in
        to:index-of-string(substring-after($arg, $substring),
        $substring)
        return
            $other +
            string-length(substring-before($arg, $substring)) +
            string-length($substring))
    else
        ()
};
declare function to:substring-before-if-contains
($arg as xs:string?,
$delim as xs:string) as xs:string? {
    
    if (contains($arg, $delim))
    then
        substring-before($arg, $delim)
    else
        $arg
};
declare function to:substring-after-if-contains
($arg as xs:string?,
$delim as xs:string) as xs:string? {
    
    if (contains($arg, $delim))
    then
        substring-after($arg, $delim)
    else
        $arg
};
declare function to:substring-before-if-match
($arg as xs:string?,
$regex as xs:string) as xs:string {
    
    if (matches($arg, $regex))
    then
        tokenize($arg, $regex)[1]
    else
        $arg
};
declare function to:substring-before-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   if (matches($arg, to:escape-for-regex($delim)))
   then replace($arg,
            concat('^(.*)', to:escape-for-regex($delim),'.*'),
            '$1')
   else ''
 } ;
declare function to:substring-after-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   replace ($arg,concat('^.*',to:escape-for-regex($delim)),'')
 } ; 
declare function to:is-value-in-sequence
($value as xs:anyAtomicType?,
$seq as xs:anyAtomicType*) as xs:boolean {
    
    $value = $seq
};
declare function to:chars
($arg as xs:string?) as xs:string* {
    
    for $ch in string-to-codepoints($arg)
    return
        codepoints-to-string($ch)
};

