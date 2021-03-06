VERSION = 0.2.0-beta.2

CC = gcc
CXX = g++

COMPILER_CFLAGS = -c -Wall -std=c++11 -g -Ofast -iquote . -iquote EmojicodeReal-TimeEngine/ -iquote EmojicodeCompiler/
COMPILER_LDFLAGS =

COMPILER_SRCDIR = EmojicodeCompiler
COMPILER_SOURCES = $(wildcard $(COMPILER_SRCDIR)/*.cpp)
COMPILER_OBJECTS = $(COMPILER_SOURCES:%.cpp=%.o)
COMPILER_BINARY = emojicodec

ENGINE_CFLAGS = -Ofast -iquote . -iquote EmojicodeReal-TimeEngine/ -iquote EmojicodeCompiler -std=gnu11 -Wall -Wno-unused-result -g $(if $(HEAP_SIZE),-DheapSize=$(HEAP_SIZE))
ENGINE_LDFLAGS = -lm -ldl -rdynamic

ENGINE_SRCDIR = EmojicodeReal-TimeEngine
ENGINE_SOURCES = $(wildcard $(ENGINE_SRCDIR)/*.c)
ENGINE_OBJECTS = $(ENGINE_SOURCES:%.c=%.o)
ENGINE_BINARY = emojicode

PACKAGE_CFLAGS = -O3 -iquote . -std=c11 -Wno-unused-result -g -fPIC
PACKAGE_LDFLAGS = -shared -fPIC
ifeq ($(shell uname), Darwin)
PACKAGE_LDFLAGS += -undefined dynamic_lookup
endif

PACKAGES_DIR=DefaultPackages
PACKAGES=files SDL sqlite

DIST_NAME=Emojicode-$(VERSION)-$(shell $(CC) -dumpmachine)
DIST_BUILDS=builds
DIST=$(DIST_BUILDS)/$(DIST_NAME)

.PHONY: builds

all: builds $(COMPILER_BINARY) $(ENGINE_BINARY) $(addsuffix .so,$(PACKAGES)) dist

$(COMPILER_BINARY): $(COMPILER_OBJECTS) EmojicodeReal-TimeEngine/utf8.o
	$(CXX) $(COMPILER_LDFLAGS) $^ -o $(DIST)/$(COMPILER_BINARY)

$(COMPILER_OBJECTS): %.o: %.cpp
	$(CXX) $(COMPILER_CFLAGS) -c $< -o $@

$(ENGINE_BINARY): $(ENGINE_OBJECTS)
	$(CC) $(ENGINE_LDFLAGS) $^ -o $(DIST)/$(ENGINE_BINARY)

$(ENGINE_OBJECTS): %.o: %.c
	$(CC) $(ENGINE_CFLAGS) -c $< -o $@ 

define package
PKG_$(1)_LDFLAGS = $$(PACKAGE_LDFLAGS)
ifeq ($(1), SDL)
PKG_$(1)_LDFLAGS += -lSDL2
endif
PKG_$(1)_SOURCES = $$(wildcard $$(PACKAGES_DIR)/$(1)/*.c)
PKG_$(1)_OBJECTS = $$(PKG_$(1)_SOURCES:%.c=%.o)
$(1).so: $$(PKG_$(1)_OBJECTS)
	$$(CC) $$(PKG_$(1)_LDFLAGS) $$^ -o $(DIST)/$$@ -iquote $$(<D)
$$(PKG_$(1)_OBJECTS): %.o: %.c
	$$(CC) $$(PACKAGE_CFLAGS) -c $$< -o $$@
endef

$(foreach pkg,$(PACKAGES),$(eval $(call package,$(pkg))))

clean:
	rm -f $(ENGINE_OBJECTS) $(COMPILER_OBJECTS) $(PACKAGES_DIR)/*/*.o

builds:
	mkdir -p $(DIST)

dist:
	cp install.sh $(DIST)/install.sh
	cp -r headers/ $(DIST)/headers
	tar -czf $(DIST).tar.gz -C $(DIST_BUILDS) $(DIST_NAME)