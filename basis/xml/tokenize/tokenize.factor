! Copyright (C) 2005, 2006 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: xml.errors xml.data xml.utilities xml.char-classes sets
xml.entities kernel state-parser kernel namespaces make strings
math math.parser sequences assocs arrays splitting combinators
unicode.case accessors fry ascii ;
IN: xml.tokenize

! XML namespace processing: ns = namespace

! A stack of hashtables
SYMBOL: ns-stack

: attrs>ns ( attrs-alist -- hash )
    ! this should check to make sure URIs are valid
    [
        [
            swap dup space>> "xmlns" =
            [ main>> set ]
            [
                T{ name f "" "xmlns" f } names-match?
                [ "" set ] [ drop ] if
            ] if
        ] assoc-each
    ] { } make-assoc f like ;

: add-ns ( name -- )
    dup space>> dup ns-stack get assoc-stack
    [ nip ] [ nonexist-ns ] if* >>url drop ;

: push-ns ( hash -- )
    ns-stack get push ;

: pop-ns ( -- )
    ns-stack get pop* ;

: init-ns-stack ( -- )
    V{ H{
        { "xml" "http://www.w3.org/XML/1998/namespace" }
        { "xmlns" "http://www.w3.org/2000/xmlns" }
        { "" "" }
    } } clone
    ns-stack set ;

: tag-ns ( name attrs-alist -- name attrs )
    dup attrs>ns push-ns
    [ dup add-ns ] dip dup [ drop add-ns ] assoc-each <attrs> ;

! Parsing names

: version=1.0? ( -- ? )
    prolog-data get version>> "1.0" = ;

! version=1.0? is calculated once and passed around for efficiency

: (parse-name) ( -- str )
    version=1.0? dup
    get-char name-start? [
        [ dup get-char name-char? not ] take-until nip
    ] [
        "Malformed name" xml-string-error
    ] if ;

: parse-name ( -- name )
    (parse-name) get-char CHAR: : =
    [ next (parse-name) ] [ "" swap ] if f <name> ;

!   -- Parsing strings

: (parse-entity) ( string -- )
    dup entities at [ , ] [ 
        prolog-data get standalone>>
        [ no-entity ] [
            dup extra-entities get at
            [ , ] [ no-entity ] ?if
        ] if
    ] ?if ;

: parse-entity ( -- )
    next CHAR: ; take-char next
    "#" ?head [
        "x" ?head 16 10 ? base> ,
    ] [ (parse-entity) ] if ;

: (parse-char) ( ch -- )
    get-char {
        { [ dup not ] [ 2drop ] }
        { [ 2dup = ] [ 2drop next ] }
        { [ dup CHAR: & = ] [ drop parse-entity (parse-char) ] }
        [ , next (parse-char) ]
    } cond ;

: parse-char ( ch -- string )
    [ (parse-char) ] "" make ;

: parse-quot ( ch -- string )
    parse-char get-char
    [ "XML file ends in a quote" xml-string-error ] unless ;

: parse-text ( -- string )
    CHAR: < parse-char ;

! Parsing tags

: start-tag ( -- name ? )
    #! Outputs the name and whether this is a closing tag
    get-char CHAR: / = dup [ next ] when
    parse-name swap ;

: parse-attr-value ( -- seq )
    get-char dup "'\"" member? [
        next parse-quot
    ] [
        "Attribute lacks quote" xml-string-error
    ] if ;

: parse-attr ( -- )
    [ parse-name ] with-scope
    pass-blank CHAR: = expect pass-blank
    [ parse-attr-value ] with-scope
    2array , ;

: (middle-tag) ( -- )
    pass-blank version=1.0? get-char name-start?
    [ parse-attr (middle-tag) ] when ;

: middle-tag ( -- attrs-alist )
    ! f make will make a vector if it has any elements
    [ (middle-tag) ] f make pass-blank ;

: end-tag ( name attrs-alist -- tag )
    tag-ns pass-blank get-char CHAR: / =
    [ pop-ns <contained> next ] [ <opener> ] if ;

: take-comment ( -- comment )
    "--" expect-string
    "--" take-string
    <comment>
    CHAR: > expect ;

: take-cdata ( -- string )
    "[CDATA[" expect-string "]]>" take-string ;

: take-element-decl ( -- element-decl )
    pass-blank " " take-string pass-blank ">" take-string <element-decl> ;

: take-attlist-decl ( -- doctype-decl )
    pass-blank " " take-string pass-blank ">" take-string <attlist-decl> ;

: take-until-one-of ( seps -- str sep )
    '[ get-char _ member? ] take-until get-char ;

: only-blanks ( str -- )
    [ blank? ] all? [ bad-doctype-decl ] unless ;

: take-system-literal ( -- str )
    pass-blank get-char next {
        { CHAR: ' [ "'" take-string ] }
        { CHAR: " [ "\"" take-string ] }
    } case ;

: take-system-id ( -- system-id )
    take-system-literal <system-id>
    ">" take-string only-blanks ;

: take-public-id ( -- public-id )
    take-system-literal
    take-system-literal <public-id>
    ">" take-string only-blanks ;

DEFER: direct

: (take-internal-subset) ( -- )
    pass-blank get-char {
        { CHAR: ] [ next ] }
        [ drop "<!" expect-string direct , (take-internal-subset) ]
    } case ;

: take-internal-subset ( -- seq )
    [ (take-internal-subset) ] { } make ;

: (take-external-id) ( token -- external-id )
    pass-blank {
        { "SYSTEM" [ take-system-id ] }
        { "PUBLIC" [ take-public-id ] }
        [ bad-external-id ]
    } case ;

: take-external-id ( -- external-id )
    " " take-string (take-external-id) ;

: take-doctype-decl ( -- doctype-decl )
    pass-blank " >" take-until-one-of {
        { CHAR: \s [
            pass-blank get-char CHAR: [ = [
                next take-internal-subset f swap
                ">" take-string only-blanks
            ] [
                " >" take-until-one-of {
                    { CHAR: \s [ (take-external-id) ] }
                    { CHAR: > [ only-blanks f ] }
                } case f
            ] if
        ] }
        { CHAR: > [ f f ] }
    } case <doctype-decl> ;

: take-entity-def ( -- entity-name entity-def )
    " " take-string pass-blank get-char {
        { CHAR: ' [ take-system-literal ] }
        { CHAR: " [ take-system-literal ] }
        [ drop take-external-id ]
    } case ;

: take-entity-decl ( -- entity-decl )
    pass-blank get-char {
        { CHAR: % [ next pass-blank take-entity-def ] }
        [ drop take-entity-def ]
    } case
    ">" take-string only-blanks <entity-decl> ;

: take-directive ( -- directive )
    " " take-string {
        { "ELEMENT" [ take-element-decl ] }
        { "ATTLIST" [ take-attlist-decl ] }
        { "DOCTYPE" [ take-doctype-decl ] }
        { "ENTITY" [ take-entity-decl ] }
        [ bad-directive ]
    } case ;

: direct ( -- object )
    get-char {
        { CHAR: - [ take-comment ] }
        { CHAR: [ [ take-cdata ] }
        [ drop take-directive ]
    } case ;

: yes/no>bool ( string -- t/f )
    {
        { "yes" [ t ] }
        { "no" [ f ] }
        [ not-yes/no ]
    } case ;

: assure-no-extra ( seq -- )
    [ first ] map {
        T{ name f "" "version" f }
        T{ name f "" "encoding" f }
        T{ name f "" "standalone" f }
    } diff
    [ extra-attrs ] unless-empty ; 

: good-version ( version -- version )
    dup { "1.0" "1.1" } member? [ bad-version ] unless ;

: prolog-attrs ( alist -- prolog )
    [ T{ name f "" "version" f } swap at
      [ good-version ] [ versionless-prolog ] if* ] keep
    [ T{ name f "" "encoding" f } swap at
      "UTF-8" or ] keep
    T{ name f "" "standalone" f } swap at
    [ yes/no>bool ] [ f ] if*
    <prolog> ;

: parse-prolog ( -- prolog )
    pass-blank middle-tag "?>" expect-string
    dup assure-no-extra prolog-attrs
    dup prolog-data set ;

: instruct ( -- instruction )
    (parse-name) dup "xml" =
    [ drop parse-prolog ] [
        dup >lower "xml" =
        [ capitalized-prolog ]
        [ "?>" take-string append <instruction> ] if
    ] if ;

: make-tag ( -- tag )
    {
        { [ get-char dup CHAR: ! = ] [ drop next direct ] }
        { [ CHAR: ? = ] [ next instruct ] } 
        [
            start-tag [ dup add-ns pop-ns <closer> ]
            [ middle-tag end-tag ] if
            CHAR: > expect
        ]
    } cond ;
