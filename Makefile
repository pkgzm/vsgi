VER   := 0.1
CC    := gcc
VALAC := valac

FEXE := build/valum.fcg
EXE  := build/valum
LIB  := build/libvalum-$(VER).so
GIR  := build/Valum-$(VER).gir
HDR  := build/valum-$(VER).h
VAPI := vapi/valum-$(VER)

USER := $(shell echo $(USER))

FLAGS := --enable-experimental --thread --vapidir=vapi \
         --cc=$(CC) -D BENCHMARK

FLAGS  := --enable-experimental --thread --vapidir=./vapi/ \
	  --cc=$(CC) -D BENCHMARK

LFLAGS := -X -fPIC -X -shared -X -lfcgi --gir=$(GIR) --library=$(VAPI) \
	  --header=$(HDR) --output=$(LIB)

AFLAGS := -X $(LIB) -X -Ibuild --output=$(EXE)

PKGS := --pkg gio-2.0 --pkg json-glib-1.0 --pkg gee-0.8 \
        --pkg libsoup-2.4 --pkg libmemcached --pkg luajit \
        --pkg ctpl --pkg fcgi

LSRC := $(shell find 'src/' -type f -name "*.vala")
CSRC := $(shell find 'src/' -type f -name "*.c")
ASRC := $(shell find 'app/' -type f -name "*.vala")

$(FEXE): $(LIB) $(ASRC)
	$(VALAC) $(FLAGS) $(AFLAGS) -X -lfcgi -D FCGI $(VAPI).vapi $(ASRC) $(PKGS) --output=$@

$(EXE): $(LIB) $(ASRC)
	$(VALAC) $(FLAGS) $(AFLAGS) $(VAPI).vapi $(ASRC) $(PKGS) --output=$@

$(LIB): $(LSRC)
	$(VALAC) $(FLAGS) $(LFLAGS) $(PKGS) $(LSRC) --output=$@

all: $(LIB) $(EXE) $(FEXE)

run: $(EXE)
	$(EXE)

run-fcgi: $(FEXE)
	spawn-fcgi -n -s valum.socket -- $(FEXE) &
	fastcgi --socket valum.socket --port 3003

drun: debug
	gdb $(EXE)

vdrun: debug
	@`which nemiver` --log-debugger-output $(EXE)

valgrind: debug
	G_SLICE=always-malloc G_DEBUG=gc-friendly $(shell which valgrind) --tool=memcheck --leak-check=full \
	--leak-resolution=high --num-callers=20 --log-file=vgdump $(EXE)

debug: clean
	@$(MAKE) "FLAGS=$(FLAGS) --debug --save-temps"

genc:
	@$(MAKE) "FLAGS=$(FLAGS) --ccode"

clean:
	rm -f $(CSRC) build/* vapi/valum-*

builddock:
	docker build -t $(USER)/valum .

rundock:
	docker run -v $(shell pwd):/src -p 127.0.0.1:3003:3003 $(USER)/valum

.PHONY: all clean run drun vdrun valgrind debug genc dock
