#!/bin/bash

# Download Galileo Press Openbooks and convert them to EPUB
#
# (c) Alexander Kriegisch (http://scrum-master.de), 2012-04-10
#
# Required Debian/Ubuntu packages: wget, unzip, sed, grep, tidy, xml2, calibre


# ========================================================
# == Usage help, command line parsing, global variables ==
# ========================================================

SELF=$(basename $0)
BOOK=$1

usage()
{
	cat << EOF
$SELF option | book_type
  Options:
    --help|-?  display this help text
  Book types (part of download archive name "galileocomputing_<book_type>.zip"):
    ubuntu
    shell_programmierung
EOF
}

case $BOOK in
	--help|-\?)
		usage
		exit
		;;
	ubuntu)
		COVER_DL_IMG=9783836216548.jpg
		;;
	shell_programmierung)
		COVER_DL_IMG=9783898426831.jpg
		ARCHIVE_SUBDIR=$BOOK
		;;
	*)
		usage >&2
		exit 1
		;;
esac

BOOK_DIR=$BOOK
BOOK_URL=http://download2.galileo-press.de/openbook
COVER_URL=http://cover.galileo-press.de
BOOK_ARCHIVE=galileocomputing_$BOOK.zip
COVER_IMG=$BOOK.jpg

# =================================================
# == Phase 1: download book + cover, unpack book ==
# =================================================

if ! [ -r $BOOK_ARCHIVE -a -s $BOOK_ARCHIVE ]; then
	echo "Downloading book archive $BOOK_ARCHIVE"
	wget -q $BOOK_URL/$BOOK_ARCHIVE || exit 1
fi

if ! [ -r $BOOK_DIR/index.htm -a -s $BOOK_DIR/index.htm ]; then
	echo "Unpacking book archive to $BOOK_DIR"
	if [ "$ARCHIVE_SUBDIR" ]; then
		unzip -qq $BOOK_ARCHIVE || exit 1
		if [ "$ARCHIVE_SUBDIR" != "$BOOK_DIR" ]; then
			mv $ARCHIVE_SUBDIR $BOOK_DIR || exit 1
		fi
	else
		unzip -qq -d $BOOK_DIR $BOOK_ARCHIVE || exit 1
	fi
fi

if ! [ -r $COVER_IMG -a -s $COVER_IMG ]; then
	echo "Downloading cover image $COVER_IMG"
	wget -q -O $COVER_IMG $COVER_URL/$COVER_DL_IMG || exit 1
fi

cd $BOOK_DIR

# ==============================
# == Phase 2: fix index + CSS ==
# ==============================

fix_ubuntu()
{
	if grep -Eq '_001.*>[0-9A]+\.2[ .]' index.htm; then
		echo "Fixing links for sub-chapters x.2 in table of contents"
		sed -ri 's/_001(.*>[0-9A]+\.2[ .])/_002\1/' index.htm || exit 1
	fi

	if ! grep -q 'Stichwortverzeichnis' index.htm; then
		echo "Inserting glossary link in table of contents"
		sed -ri '/Fragen und Antworten.*$/{
			N
			s/$/  <div align="center"><a href="#top"><img src="common\/jupiters.gif" alt="Galileo Computing - Zum Seitenanfang" border="0"><\/a><\/div>\
  <h2 class="inhalt1">\
    <a href="stichwort.htm">Stichwortverzeichnis<\/a>\
  <\/h2>/
		}' index.htm || exit 1
	fi

	if grep -q 'back_blau_weiss.gif' common/galileo_open.css; then
		echo "Removing light-blue background column on the left"
		sed -ri 's/; background: white url\(back_blau_weiss.gif\) repeat-y//' common/galileo_open.css || exit 1
	fi
}

fix_shell_programmierung()
{
	if grep -q 'back_blau_weiss.gif' common/galileo_open.css; then
		echo "Removing light-blue background column on the left"
		sed -ri 's/; background: white url\(back_blau_weiss.gif\) repeat-y//' common/galileo_open.css || exit 1
	fi
}

echo
fix_$BOOK

# ===============================
# == Phase 3: clean HTML files ==
# ===============================

clean_ubuntu()
{
	for FILE in index.htm* stichwort.htm*; do
		cat $FILE |
			tidy -q --show-errors 0 -asxhtml -n -c -w 0 --ascii-chars 1 |
			xml2 |
			#tee ${FILE%.*}.ori.txt |
			grep -v '/html/head/script=' |
			sed -r 's/(title=)Galileo.*GNU\/Linux [^ ]+ /\1/' |
			sed -r '/\/body\/@onload=prettyPrint\(\)/,/@class=t1$/{/\/body\/@onload=prettyPrint\(\)/!{/@class=t1$/!d}}' |
			sed -r '/\/body\/table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\/div\/hr$/,$ d' |
			sed -r '/\/body\/table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\/div\/(div\/)?@(class=c3|align=center)$/,/Zum Seitenanfang$/d' |
			sed -r '/\/body\/table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\/div\/(div\/)?@class=c4$/,/\/body\/table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\/div\/a\/img\/@border=0$/d' |
			sed -r 's/(\/body\/)table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\//\1/' |
			sed -r '/\/body\/table\//,$ d' |
			#tee ${FILE%.*}.txt |
			2html |
			tidy -q --show-errors 0 -ashtml -c -w 0 -i --input-encoding utf8 --output-encoding latin0 |
			grep -v '^$' > $FILE.tmp
		mv $FILE.tmp $FILE
	done

	for FILE in *[0-9].htm*; do
		cat "$FILE" |
			tidy -q --show-errors 0 -asxhtml -n -c -w 0 --ascii-chars 1 |
			xml2 |
			grep -v '/html/head/script=' |
			#tee ${FILE%.*}.ori.txt |
			sed -r 's/(title=)Galileo.*GNU\/Linux [^ ]+ /\1/' |
			sed -r '/\/body\/@onload=prettyPrint\(\)/,/@class=main$/{/\/body\/@onload=prettyPrint\(\)/!{/@class=main$/!d}}' |
			sed -r '/\/body\/table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\/div\/hr$/,$ d' |
			sed -r '/\/body\/table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\/div\/(div\/)?@(class=c3|align=center)$/,/Zum Seitenanfang$/d' |
			sed -r 's/(\/body\/)table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\/(div\/)/\1\2/' |
			#tee ${FILE%.*}.txt |
			2html |
			tidy -q --show-errors 0 -ashtml -c -w 0 -i --input-encoding utf8 --output-encoding latin0 |
			grep -v '^$' > $FILE.tmp
		mv $FILE.tmp $FILE
	done
}

clean_shell_programmierung()
{
	for FILE in index.htm* stichwort.htm*; do
		cat $FILE |
			tidy -q --show-errors 0 -asxhtml -n -c -w 0 --ascii-chars 1 |
			xml2 |
			#tee ${FILE%.*}.ori.txt |
			grep -v '/html/head/script=' |
			sed -r 's/(title=)Galileo.*Shell-Programmierung [^ ]+ /\1/' |
			sed -r '/@class=c1/,/@class=c4/d' |
			sed -r '/@width=100%/,/@border=0/d' |
			sed -r 's/(\/body\/)table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\//\1/' |
			{
				if [ "$FILE" == "${FILE#index}" ]; then
					sed -r '/\/body\/table\/tr\/td\/div\/table\/tr$/,$ d' |
					grep -v '/body/div/'
				else
					sed -r '/\/body\/table\//,$ d' |
					sed -r '/@href=#top/,/@alt=Galileo/d'
				fi
			} |
			#tee ${FILE%.*}.txt |
			2html |
			tidy -q --show-errors 0 -ashtml -c -w 0 -i --input-encoding utf8 --output-encoding latin0 |
			grep -v '^$' > $FILE.tmp
		mv $FILE.tmp $FILE
	done

	for FILE in *[0-9].htm*; do
		cat $FILE |
			tidy -q --show-errors 0 -asxhtml -n -c -w 0 --ascii-chars 1 |
			xml2 |
			#tee ${FILE%.*}.ori.txt |
			grep -v '/html/head/script=' |
			sed -r 's/(title=)Galileo.*Shell-Programmierung [^ ]+ /\1/' |
			sed -r '/background-color: #000000/d' |
			sed -r '/@class=c1/,/\/body\/table\/tr\/td\/div\/table\/tr\/td\/table$/d' |
			sed -r '/\/body\/table\/tr\/td\/div\/table\/tr$/,$ d' |
			sed -r '/@class=c[567]/,/@border=0/d' |
			sed -r 's/(\/body\/)table\/tr\/td\/div\/table\/tr\/td\/table\/tr\/td\//\1/' |
			sed -r '/@href=#top/,/@alt=Galileo/d' |
			#tee ${FILE%.*}.txt |
			2html |
			tidy -q --show-errors 0 -ashtml -c -w 0 -i --input-encoding utf8 --output-encoding latin0 |
			grep -v '^$' > $FILE.tmp
		mv $FILE.tmp $FILE
	done
}

echo
echo "Cleaning and simplifying HTML files"
clean_$BOOK

# ===================================
# == Phase 4: create e-book (EPUB) ==
# ===================================

# Tips für Calibre:
#  - Sprache auf Deutsch einstellen
#  - Aus dem Verzeichnis BOOK_DIR (galileo_ubuntu) die Datei index.htm als
#    neues Buch importieren. Danach ggf. den langen Titel ändern in etwas Kürzeres,
#    z.B. "Ubuntu 11.04".
#  - Einstellungen -> Konvertierung -> Allgemeine Einstellungen ->
#    Inhaltsverzeichnis -> Filter für Inhaltsverzeichnis: "Unbekannt" eintragen,
#    um überflüssige Index-Einträge dieses Namens zu unterdrücken
#  - Einstellungen -> Konvertierung -> Allgemeine Einstellungen ->
#    Struktur Erkennung -> Seitenumbrüche einfügen vor: "//*[name()='h1']"
#    eintragen, also den Teil mit "or name()='h2'" löschen
#  - Einstellungen -> Konvertierung -> Ausgabeoptionen -> EPUB-Ausgabe ->
#    Seitenverhältnis des Umschlagbildes beibehalten: aktivieren. Für die
#    PDF-Ausgabe gibt es eine ähnliche Einstellung. Beim Konvertieren als
#    Umschlagbild das heruntergeladene COVER_IMG (galileo_ubuntu/cover.jpg)
#    auswählen, um ein hübsches Cover zu erhalten.

#echo
#echo "Starting Calibre for e-book conversion..."
#calibre >/dev/null 2>&1 &
