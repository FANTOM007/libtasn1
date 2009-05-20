# Copyright (C) 2006, 2007, 2008, 2009 Free Software Foundation
# Author: Simon Josefsson
#
# This file is part of LIBTASN1.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

WFLAGS ?= --enable-gcc-warnings
ADDFLAGS ?=
CFGFLAGS ?= --enable-gtk-doc $(ADDFLAGS) $(WFLAGS)

INDENT_SOURCES = `find . -name \*.[ch]|grep -v -e ^./gl -e ^./lib/gl -e ^./build-aux/ -e ^./lib/ASN1.c -e ^./tests/Test_tree_asn1_tab.c`

ifeq ($(.DEFAULT_GOAL),abort-due-to-no-makefile)
.DEFAULT_GOAL := bootstrap
endif

local-checks-to-skip = sc_prohibit_strcmp sc_prohibit_have_config_h	\
	sc_require_config_h sc_require_config_h_first			\
	sc_trailing_blank sc_GPL_version sc_immutable_NEWS		\
	sc_copyright_check

autoreconf:
	test -f ./configure || autoreconf --install

bootstrap: autoreconf
	./configure $(CFGFLAGS)

web-coverage:
	rm -fv `find $(htmldir)/coverage -type f | grep -v CVS`
	cp -rv $(COVERAGE_OUT)/* $(htmldir)/coverage/

upload-web-coverage:
	cd $(htmldir) && \
		cvs commit -m "Update." coverage

W32ROOT ?= $(HOME)/gnutls4win/inst

mingw32: autoreconf 
	./configure --enable-gtk-doc --host=i586-mingw32msvc --build=`./config.guess` --prefix=$(W32ROOT)

ChangeLog:
	git2cl > ChangeLog
	cat .clcopying >> ChangeLog

htmldir = ../www-$(PACKAGE)
tag = $(PACKAGE)_`echo $(VERSION) | sed 's/\./_/g'`

release: prepare upload web upload-web

prepare:
	! git-tag -l $(tag) | grep $(PACKAGE) > /dev/null
	rm -f ChangeLog
	$(MAKE) ChangeLog distcheck
	git commit -m Generated. ChangeLog
	git-tag -u b565716f! -m $(VERSION) $(tag)

upload:
	git-push
	git-push --tags
	gnupload --to ftp.gnu.org:gnutls $(distdir).tar.gz
	scp $(distdir).tar.gz $(distdir).tar.gz.sig igloo.linux.gr:~ftp/pub/gnutls/libtasn1/
	ssh igloo.linux.gr 'cd ~ftp/pub/gnutls/libtasn1/ && sha1sum *.tar.gz > CHECKSUMS'
	cp $(distdir).tar.gz $(distdir).tar.gz.sig ../releases/gnutls/$(PACKAGE)/

web:
	cd doc && ../build-aux/gendocs.sh --html "--css-include=texinfo.css" \
		-o ../$(htmldir)/manual/ $(PACKAGE) "$(PACKAGE_NAME)"
	cp -v doc/reference/html/*.html doc/reference/html/*.png doc/reference/html/*.devhelp doc/reference/html/*.css $(htmldir)/reference/
	cp -v doc/cyclo/cyclo-$(PACKAGE).html $(htmldir)/cyclo/index.html

upload-web:
	cd $(htmldir) && cvs commit -m "Update." manual/ reference/
