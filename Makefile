# Paths
OBJDIR := dist
SRCDIR := src
SRC := $(SRCDIR)/pong.asm
PRG := $(OBJDIR)/pong.prg
D64 := $(OBJDIR)/pong.d64

# Commands
MKPRG = tmpx -o $(PRG) -i $(SRC)
RM := rm -rf
MKDIR := mkdir -p
MKD64 = mkd64 -o $(D64) -m cbmdos -d 'PONG' -m separators \
-f $(PRG) -n PONG -w

# Targets
.PHONY: all clean

all: $(D64)

$(PRG): | $(OBJDIR)

$(OBJDIR):
	$(MKDIR) $(OBJDIR)

clean:
	$(RM) $(OBJDIR)

# Rules
$(PRG): $(SRC)
	$(MKPRG)

$(D64): $(PRG) 
	$(MKD64)
