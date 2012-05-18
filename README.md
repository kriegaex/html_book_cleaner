html_book_cleaner
=================

Sample script showing how to use the xml2 package in order to clean up some of Galileo Computing's openbooks before converting them to EPUB or PDF format

Known bug: 2html (part of xml2 package) sometimes forgets to add closing tags for bold print (</b>), causing too much bold text on HTML pages. The Debian package maintainer has been notified.
