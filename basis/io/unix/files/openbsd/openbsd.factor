! Copyright (C) 2008 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.c-types alien.strings alien.syntax
combinators io.backend io.files io.unix.files kernel math
sequences system unix unix.getfsstat.openbsd grouping
unix.statfs.openbsd unix.statvfs.openbsd unix.types ;
IN: io.unix.files.openbsd

TUPLE: freebsd-file-system-info < unix-file-system-info
io-size sync-writes sync-reads async-writes async-reads 
owner ;

M: openbsd new-file-system-info freebsd-file-system-info new ;

M: openbsd file-system-statfs
    "statfs" <c-object> tuck statfs io-error ;

M: openbsd statfs>file-system-info ( file-system-info statfs -- file-system-info' )
    {
        [ statfs-f_flags >>flags ]
        [ statfs-f_bsize >>block-size ]
        [ statfs-f_iosize >>io-size ]
        [ statfs-f_blocks >>blocks ]
        [ statfs-f_bfree >>blocks-free ]
        [ statfs-f_bavail >>blocks-available ]
        [ statfs-f_files >>files ]
        [ statfs-f_ffree >>files-free ]
        [ statfs-f_favail >>files-available ]
        [ statfs-f_syncwrites >>sync-writes ]
        [ statfs-f_syncreads >>sync-reads ]
        [ statfs-f_asyncwrites >>async-writes ]
        [ statfs-f_asyncreads >>async-reads ]
        [ statfs-f_fsid >>id ]
        [ statfs-f_namemax >>name-max ]
        [ statfs-f_owner >>owner ]
        ! [ statfs-f_spare >>spare ]
        [ statfs-f_fstypename alien>native-string >>type ]
        [ statfs-f_mntonname alien>native-string >>mount-point ]
        [ statfs-f_mntfromname alien>native-string >>device-name ]
    } cleave ;

M: openbsd file-system-statvfs ( normalized-path -- statvfs )
    "statvfs" <c-object> tuck statvfs io-error ;

M: openbsd statvfs>file-system-info ( file-system-info statvfs -- file-system-info' )
    {
        [ statvfs-f_frsize >>preferred-block-size ]
    } cleave ;

M: openbsd file-systems ( -- seq )
    f 0 0 getfsstat dup io-error
    "statfs" <c-array> dup dup length 0 getfsstat io-error 
    "statfs" heap-size group 
    [ statfs-f_mntonname alien>native-string file-system-info ] map ;
