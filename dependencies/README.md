aBackup
=======

A quick and dirty backup tool for Windows

Dependencies
------------

This directory contains third party libraries and program installers required by
`aBackup` to work. They aren't property of this project's owner and are provided
here just to simplify the installation of them. More specifically:
  * `zip-3.0-setup.exe` and `unzip-5.51-1-bin.zip` are property of [Info-ZIP](http://www.info-zip.org/).
    and their license is:

    This is version 2007-Mar-4 of the Info-ZIP license.
    The definitive version of this document should be available at
    ftp://ftp.info-zip.org/pub/infozip/license.html indefinitely and
    a copy at http://www.info-zip.org/pub/infozip/license.html.


    Copyright (c) 1990-2007 Info-ZIP.  All rights reserved.

    For the purposes of this copyright and license, "Info-ZIP" is defined as
    the following set of individuals:

       Mark Adler, John Bush, Karl Davis, Harald Denker, Jean-Michel Dubois,
       Jean-loup Gailly, Hunter Goatley, Ed Gordon, Ian Gorman, Chris Herborth,
       Dirk Haase, Greg Hartwig, Robert Heath, Jonathan Hudson, Paul Kienitz,
       David Kirschbaum, Johnny Lee, Onno van der Linden, Igor Mandrichenko,
       Steve P. Miller, Sergio Monesi, Keith Owens, George Petrov, Greg Roelofs,
       Kai Uwe Rommel, Steve Salisbury, Dave Smith, Steven M. Schweda,
       Christian Spieler, Cosmin Truta, Antoine Verheijen, Paul von Behren,
       Rich Wales, Mike White.

    This software is provided "as is," without warranty of any kind, express
    or implied.  In no event shall Info-ZIP or its contributors be held liable
    for any direct, indirect, incidental, special or consequential damages
    arising out of the use of or inability to use this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the above disclaimer and the following restrictions:

        1. Redistributions of source code (in whole or in part) must retain
           the above copyright notice, definition, disclaimer, and this list
           of conditions.

        2. Redistributions in binary form (compiled executables and libraries)
           must reproduce the above copyright notice, definition, disclaimer,
           and this list of conditions in documentation and/or other materials
           provided with the distribution.  The sole exception to this condition
           is redistribution of a standard UnZipSFX binary (including SFXWiz) as
           part of a self-extracting archive; that is permitted without inclusion
           of this license, as long as the normal SFX banner has not been removed
           from the binary or disabled.

        3. Altered versions--including, but not limited to, ports to new operating
           systems, existing ports with new graphical interfaces, versions with
           modified or added functionality, and dynamic, shared, or static library
           versions not from Info-ZIP--must be plainly marked as such and must not
           be misrepresented as being the original source or, if binaries,
           compiled from the original source.  Such altered versions also must not
           be misrepresented as being Info-ZIP releases--including, but not
           limited to, labeling of the altered versions with the names "Info-ZIP"
           (or any variation thereof, including, but not limited to, different
           capitalizations), "Pocket UnZip," "WiZ" or "MacZip" without the
           explicit permission of Info-ZIP.  Such altered versions are further
           prohibited from misrepresentative use of the Zip-Bugs or Info-ZIP
           e-mail addresses or the Info-ZIP URL(s), such as to imply Info-ZIP
           will provide support for the altered versions.

        4. Info-ZIP retains the right to use the names "Info-ZIP," "Zip," "UnZip,"
           "UnZipSFX," "WiZ," "Pocket UnZip," "Pocket Zip," and "MacZip" for its
           own source and binary releases.


Project layout
--------------
  * `src`: Here it is where source code is.
    * `main`: Here it is where source code meant to be part of the application
              lives. It is here just in case I want to add a `test` directory
              some day.
  * `cmd`: Useful executables for development.

Technical notes
---------------
In order to simplify user commands, it could be interesting to keep some
configuration files in a global or user dependant path. I'm thinking in wherever
`%USERPROFILE%` points to.

---
Below, a markdown cheatsheet.

Heading
=======
Sub-heading
-----------
### Another deeper heading

---

Paragraphs are separated
by a blank line.

Two spaces at the end of a line leave a  
line break.

Text attributes _italic_, *italic*, __bold__, **bold**, `monospace`.

Bullet list:

  * apples
  * oranges
  * pears

Numbered list:

  1. apples
  2. oranges
  3. pears

A [link](http://example.com).

```javascript
function {
  //Javascript highlighted code block.
}
```

    {
    Code block without highlighting.
    }
