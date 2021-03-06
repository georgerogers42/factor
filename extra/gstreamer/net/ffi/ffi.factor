! Copyright (C) 2010 Anton Gorenko.
! See http://factorcode.org/license.txt for BSD license.
USING: alien alien.libraries alien.syntax combinators
gobject-introspection kernel system vocabs.loader ;
IN: gstreamer.net.ffi

<<
"gstreamer.ffi" require
>>

LIBRARY: gstreamer.net

<<
"gstreamer.net" {
    { [ os winnt? ] [ drop ] }
    { [ os macosx? ] [ drop ] }
    { [ os unix? ] [ "libgstnet-0.10.so" cdecl add-library ] }
} cond
>>

GIR: vocab:gstreamer/net/GstNet-0.10.gir

