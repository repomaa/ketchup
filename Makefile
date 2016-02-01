OUT        = ketchup ketchup-server
PREFIX    ?= /usr/local
MANPREFIX ?= $(PREFIX)/share/man
VERSION    = $(shell git describe --tags)

MANPAGES = \
	ketchup.1 \
	ketchup-server.1

all: $(OUT) doc

doc: $(MANPAGES)

ketchup.1: man/ketchup.pod
	pod2man --section=1 --center="Ketchup Manual (Client)" --name="KETCHUP" --release="ketchup $(VERSION)" $< $@

ketchup-server.1: man/ketchup-server.pod
	pod2man --section=1 --center="Ketchup Manual (Server)" --name="KETCHUP-SERVER" --release="ketchup $(VERSION)" $< $@

ketchup: src/client_cli.cr
	crystal build --release -o $@ $<

ketchup-server: src/server_cli.cr
	crystal build --release -o $@ $<

strip: $(OUT)
	strip --strip-all $(OUT)

install: all
	install -D -m755 ketchup "$(DESTDIR)$(PREFIX)/bin/ketchup"
	install -D -m755 ketchup-server "$(DESTDIR)$(PREFIX)/bin/ketchup-server"
	install -D -m644 ketchup.1 "$(DESTDIR)$(MANPREFIX)/man1/ketchup.1"
	install -D -m644 ketchup-server.1 "$(DESTDIR)$(MANPREFIX)/man1/ketchup-server.1"
	install -D -m644 misc/config.yml "$(DESTDIR)$(PREFIX)/share/doc/ketchup/config.yml"
	install -D -m644 examples/ledger/README.md "$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/README.md"
	install -D -m644 examples/ledger/vars "$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/vars"
	install -D -m755 examples/ledger/task_started "$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/task_started"
	install -D -m755 examples/ledger/task_stopped "$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/task_stopped"
	install -D -m755 examples/ledger/pomodoro_finished "$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/pomodoro_finished"
	install -D -m755 examples/ledger/pomodoro_interrupted "$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/pomodoro_interrupted"
uninstall:
	$(RM) "$(DESTDIR)$(PREFIX)/bin/ketchup" \
		"$(DESTDIR)$(PREFIX)/bin/ketchup-server" \
		"$(DESTDIR)$(MANPREFIX)/man1/ketchup.1" \
		"$(DESTDIR)$(MANPREFIX)/man1/ketchup-server.1" \
		"$(DESTDIR)$(PREFIX)/share/doc/ketchup/config.yml" \
		"$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/README.md" \
		"$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/vars" \
		"$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/task_started" \
		"$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/task_stopped" \
		"$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/pomodoro_finished" \
		"$(DESTDIR)$(PREFIX)/share/doc/ketchup/examples/ledger/pomodoro_interrupted"

clean:
	$(RM) $(OUT) $(MANPAGES)

.PHONY: clean doc install uninstall
