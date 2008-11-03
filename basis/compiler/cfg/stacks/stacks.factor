! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: math sequences kernel cpu.architecture
compiler.cfg.instructions compiler.cfg.registers
compiler.cfg.hats ;
IN: compiler.cfg.stacks

: ds-drop ( -- )
    -1 ##inc-d ;

: ds-pop ( -- vreg )
    D 0 ^^peek -1 ##inc-d ;

: ds-push ( vreg -- )
    1 ##inc-d D 0 ##replace ;

: ds-load ( n -- vregs )
    [ <reversed> [ <ds-loc> ^^peek ] map ] [ neg ##inc-d ] bi ;

: ds-store ( vregs -- )
    <reversed> [ length ##inc-d ] [ [ <ds-loc> ##replace ] each-index ] bi ;

: rs-load ( n -- vregs )
    [ <reversed> [ <rs-loc> ^^peek ] map ] [ neg ##inc-r ] bi ;

: rs-store ( vregs -- )
    <reversed> [ length ##inc-r ] [ [ <rs-loc> ##replace ] each-index ] bi ;

: 2inputs ( -- vreg1 vreg2 )
    D 1 ^^peek D 0 ^^peek -2 ##inc-d ;

: 3inputs ( -- vreg1 vreg2 vreg3 )
    D 2 ^^peek D 1 ^^peek D 0 ^^peek -3 ##inc-d ;
