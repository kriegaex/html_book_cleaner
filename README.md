HTML book cleaner
=================

This is a sample script showing how to use the [xml2](http://ofb.net/~egnor/xml2/) package in order to clean up some of the [Galileo Computing openbooks](http://www.galileocomputing.de/openbook) before converting them to *EPUB* or *PDF* format.

Known bug: *2html* (part of the *xml2* package) sometimes forgets to add closing tags for bold print (`</b>`), causing too much bold text on HTML pages. The [Debian package](http://packages.debian.org/squeeze/xml2) maintainer has been notified.
