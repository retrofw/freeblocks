#
# FreeBlocks for the RetroFW
#
# by pingflood; 2019
#


TARGET = freeblocks/freeblocks.dge

CHAINPREFIX 	:= /opt/mipsel-RetroFW-linux-uclibc
CROSS_COMPILE 	:= $(CHAINPREFIX)/usr/bin/mipsel-linux-

CC 		:= $(CROSS_COMPILE)gcc
CXX 	:= $(CROSS_COMPILE)g++
LD  	:= $(CC)

SYSROOT		:= $(shell $(CC) --print-sysroot)
SDL_LIBS 	:= $(shell $(SYSROOT)/usr/bin/sdl-config --libs)
SDL_FLAGS 	:= $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)

# change compilation / linking flag options
F_OPTS		= -DHOME_SUPPORT -DHALF_GFX -D__GCW0__
CC_OPTS		= -O2 -mips32 -fdata-sections -ffunction-sections $(F_OPTS)
CFLAGS		= $(SDL_CFLAGS) $(CC_OPTS)
CXXFLAGS	= $(CFLAGS)
LDFLAGS     = $(SDL_LIBS) -lm -lSDLmain -lSDL -lSDL_mixer -lSDL_ttf -lSDL_image -Wl,--as-needed -Wl,--gc-sections -flto -s

# Files to be compiled
SRCDIR    = ./src ./src/dork
VPATH     = $(SRCDIR)
SRC_C   = $(foreach dir, $(SRCDIR), $(wildcard $(dir)/*.c))
SRC_CP   = $(foreach dir, $(SRCDIR), $(wildcard $(dir)/*.cpp))
OBJ_C   = $(notdir $(patsubst %.c, %.o, $(SRC_C)))
OBJ_CP   = $(notdir $(patsubst %.cpp, %.o, $(SRC_CP)))
OBJS     = $(OBJ_C) $(OBJ_CP)

# Rules to make executable
all: $(OBJS)
	$(LD) $(CFLAGS) -o $(TARGET) $^ $(LDFLAGS)

$(OBJ_C) : %.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJ_CP) : %.o : %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	rm -f $(TARGET) *.o

ipk: all
	@rm -rf /tmp/.freeblocks-ipk/ && mkdir -p /tmp/.freeblocks-ipk/root/home/retrofw/games/freeblocks /tmp/.freeblocks-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@cp -r freeblocks/freeblocks.elf freeblocks/freeblocks.png freeblocks/res /tmp/.freeblocks-ipk/root/home/retrofw/games/freeblocks
	@cp freeblocks/freeblocks.lnk /tmp/.freeblocks-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" freeblocks/control > /tmp/.freeblocks-ipk/control
	@cp freeblocks/conffiles /tmp/.freeblocks-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.freeblocks-ipk/control.tar.gz -C /tmp/.freeblocks-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.freeblocks-ipk/data.tar.gz -C /tmp/.freeblocks-ipk/root/ .
	@echo 2.0 > /tmp/.freeblocks-ipk/debian-binary
	@ar r freeblocks/freeblocks.ipk /tmp/.freeblocks-ipk/control.tar.gz /tmp/.freeblocks-ipk/data.tar.gz /tmp/.freeblocks-ipk/debian-binary

opk: all
	@mksquashfs \
	freeblocks/default.retrofw.desktop \
	freeblocks/freeblocks.dge \
	freeblocks/res \
	freeblocks/freeblocks.png \
	freeblocks/freeblocks.opk \
	-all-root -noappend -no-exports -no-xattrs
