
Unfortunately, some fiddling is necessary to get this to work as we have to generate the
PLplot smoke bindings ourselves. A future goal is to get the smoke bindings for PLplot 
included in the PLplot project so that you can just use them, but this will probably take
a while. The only reference I could find for how to do this is here:

https://techbase.kde.org/Development/Languages/Smoke


The process (all these steps need to be executed in the cl-plplot/commonqt-plot directory).

1. Create a symbolic link to the qt.h file that is part of PLplot. On linux systems this
   is typically located in the /usr/local/include/plplot directory.

   > ln -s /usr/local/include/plplot/qt.h

   Note: I don't understand why smoke can't just find this header file in its default 
     location using 'include <plplot/qt>' instead of 'include "qt.h"', but this did not 
     work for me.


2. Run smokegen to create the smokedata.cpp and x_1.cpp files.

   > smokegen -config /usr/share/smokegen/qt-config.xml -smokeconfig smokeconfig.xml -- plplotqt.h


3. Run qmake to generate a make file.

   > qmake plplotqt


4. Run make to generate the libsmokeplplotqt.so library.

   > make


Relevant files:
  Smoke related:
    plplotqt.h - The "all inclusive" header file that smokegen needs.
    plplotqt.pro - The lib template that qmake uses to create the make file.
    smokeconfig.xml - The smoke XML configuration file.

  Lisp:
    commonqt-plot.asd - The system definition file.
    package.lisp - Configures the commonqt-plot package. This also takes care of
      loading the PLplot smoke bindings so that you can use them.
    qt-example.lisp - This is a Lisp version of the standard PLplot qt example.

    