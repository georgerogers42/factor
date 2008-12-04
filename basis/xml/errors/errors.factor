! Copyright (C) 2005, 2006 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: xml.data xml.writer kernel generic io prettyprint math 
debugger sequences state-parser accessors summary
namespaces io.streams.string xml.backend ;
IN: xml.errors

ERROR: multitags ;

M: multitags summary ( obj -- str )
    drop "XML document contains multiple main tags" ;

ERROR: pre/post-content string pre? ;

M: pre/post-content summary ( obj -- str )
    [
        "The text string:" print
        dup string>> .
        "was used " write
        pre?>> "before" "after" ? write
        " the main tag." print
    ] with-string-writer ;

TUPLE: no-entity < parsing-error thing ;

: no-entity ( string -- * )
    \ no-entity parsing-error swap >>thing throw ;

M: no-entity summary ( obj -- str )
    [
        dup call-next-method write
        "Entity does not exist: &" write thing>> write ";" print
    ] with-string-writer ;

TUPLE: xml-string-error < parsing-error string ; ! this should not exist

: xml-string-error ( string -- * )
    \ xml-string-error parsing-error swap >>string throw ;

M: xml-string-error summary ( obj -- str )
    [
        dup call-next-method write
        string>> print
    ] with-string-writer ;

TUPLE: mismatched < parsing-error open close ;

: mismatched ( open close -- * )
    \ mismatched parsing-error swap >>close swap >>open throw ;

M: mismatched summary ( obj -- str )
    [
        dup call-next-method write
        "Mismatched tags" print
        "Opening tag: <" write dup open>> print-name ">" print
        "Closing tag: </" write close>> print-name ">" print
    ] with-string-writer ;

TUPLE: unclosed < parsing-error tags ;

: unclosed ( -- * )
    \ unclosed parsing-error
        xml-stack get rest-slice [ first name>> ] map >>tags
    throw ;

M: unclosed summary ( obj -- str )
    [
        dup call-next-method write
        "Unclosed tags" print
        "Tags: " print
        tags>> [ "  <" write print-name ">" print ] each
    ] with-string-writer ;

TUPLE: bad-uri < parsing-error string ;

: bad-uri ( string -- * )
    \ bad-uri parsing-error swap >>string throw ;

M: bad-uri summary ( obj -- str )
    [
        dup call-next-method write
        "Bad URI:" print string>> .
    ] with-string-writer ;

TUPLE: nonexist-ns < parsing-error name ;

: nonexist-ns ( name-string -- * )
    \ nonexist-ns parsing-error swap >>name throw ;

M: nonexist-ns summary ( obj -- str )
    [
        dup call-next-method write
        "Namespace " write name>> write " has not been declared" print
    ] with-string-writer ;

TUPLE: unopened < parsing-error ; ! this should give which tag was unopened

: unopened ( -- * )
    \ unopened parsing-error throw ;

M: unopened summary ( obj -- str )
    [
        call-next-method write
        "Closed an unopened tag" print
    ] with-string-writer ;

TUPLE: not-yes/no < parsing-error text ;

: not-yes/no ( text -- * )
    \ not-yes/no parsing-error swap >>text throw ;

M: not-yes/no summary ( obj -- str )
    [
        dup call-next-method write
        "standalone must be either yes or no, not \"" write
        text>> write "\"." print
    ] with-string-writer ;

! this should actually print the names
TUPLE: extra-attrs < parsing-error attrs ;

: extra-attrs ( attrs -- * )
    \ extra-attrs parsing-error swap >>attrs throw ;

M: extra-attrs summary ( obj -- str )
    [
        dup call-next-method write
        "Extra attributes included in xml version declaration:" print
        attrs>> .
    ] with-string-writer ;

TUPLE: bad-version < parsing-error num ;

: bad-version ( num -- * )
    \ bad-version parsing-error swap >>num throw ;

M: bad-version summary ( obj -- str )
    [
        "XML version must be \"1.0\" or \"1.1\". Version here was " write
        num>> .
    ] with-string-writer ;

ERROR: notags ;

M: notags summary ( obj -- str )
    drop "XML document lacks a main tag" ;

TUPLE: bad-prolog < parsing-error prolog ;

: bad-prolog ( prolog -- * )
    \ bad-prolog parsing-error swap >>prolog throw ;

M: bad-prolog summary ( obj -- str )
    [
        dup call-next-method write
        "Misplaced XML prolog" print
        prolog>> write-prolog nl
    ] with-string-writer ;

TUPLE: capitalized-prolog < parsing-error name ;

: capitalized-prolog ( name -- capitalized-prolog )
    \ capitalized-prolog parsing-error swap >>name throw ;

M: capitalized-prolog summary ( obj -- str )
    [
        dup call-next-method write
        "XML prolog name was partially or totally capitalized, using" print
        "<?" write name>> write "...?>" write
        " instead of <?xml...?>" print
    ] with-string-writer ;

TUPLE: versionless-prolog < parsing-error ;

: versionless-prolog ( -- * )
    \ versionless-prolog parsing-error throw ;

M: versionless-prolog summary ( obj -- str )
    [
        call-next-method write
        "XML prolog lacks a version declaration" print
    ] with-string-writer ;

TUPLE: bad-instruction < parsing-error instruction ;

: bad-instruction ( instruction -- * )
    \ bad-instruction parsing-error swap >>instruction throw ;

M: bad-instruction summary ( obj -- str )
    [
        dup call-next-method write
        "Misplaced processor instruction:" print
        instruction>> write-xml-chunk nl
    ] with-string-writer ;

TUPLE: bad-directive < parsing-error dir ;

: bad-directive ( directive -- * )
    \ bad-directive parsing-error swap >>dir throw ;

M: bad-directive summary ( obj -- str )
    [
        dup call-next-method write
        "Unknown directive:" print
        dir>> write
    ] with-string-writer ;

TUPLE: bad-doctype-decl < parsing-error ;

: bad-doctype-decl ( -- * )
    \ bad-doctype-decl parsing-error throw ;

M: bad-doctype-decl summary ( obj -- str )
    call-next-method "\nBad DOCTYPE" append ;

TUPLE: bad-external-id < parsing-error ;

: bad-external-id ( -- * )
    \ bad-external-id parsing-error throw ;

M: bad-external-id summary ( obj -- str )
    call-next-method "\nBad external ID" append ;

TUPLE: misplaced-directive < parsing-error dir ;

: misplaced-directive ( directive -- * )
    \ misplaced-directive parsing-error swap >>dir throw ;

M: misplaced-directive summary ( obj -- str )
    [
        dup call-next-method write
        "Misplaced directive:" print
        dir>> write-xml-chunk nl
    ] with-string-writer ;

UNION: xml-parse-error multitags notags extra-attrs nonexist-ns
       not-yes/no unclosed mismatched xml-string-error expected no-entity
       bad-prolog versionless-prolog capitalized-prolog bad-instruction
       bad-directive ;
