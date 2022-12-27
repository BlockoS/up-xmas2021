CC   = gcc
CXX  = g++
RASM = rasm
ECHO = echo

CCFLAGS = -W -Wall
RASMFLAGS =-s -I${RASM_DIR} -I.

ALL = bin2m12 build_frame frames up-xmas2021.bin up-xmas2021.m12 up-xmas2021.2.bin up-xmas2021.2.m12 

all: $(ALL)

.PHONY: all

bin2m12: tools/bin2m12.c
	@$(ECHO) "CC    $@"
	@$(CC) $(CCFLAGS) -o $@ $<

build_frame: tools/build_frame.c
	@$(ECHO) "CC    $@"
	@$(CC) $(CCFLAGS) -g -o $@ $<

frames: build_frame
	@$(ECHO) "creating $@"
	@make -f ./data/anim/anim.mk INDIR=./data/anim/uprough OUTDIR=./_data/anim/uprough
	@make -f ./data/anim/anim.mk INDIR=./data/anim/santa OUTDIR=./_data/anim/santa
	@make -f ./data/anim/anim.mk INDIR=./data/anim/ball OUTDIR=./_data/anim/ball
	@make -f ./data/anim/anim.mk INDIR=./data/anim/end OUTDIR=./_data/anim/end
	@make -f ./data/anim/anim.mk INDIR=./data/anim/scroller OUTDIR=./_data/anim/scroller
	@make -f ./data/anim/anim.mk INDIR=./data/anim/tunnel OUTDIR=./_data/anim/tunnel

up-xmas2021.bin: up-xmas2021.asm frames
	@$(ECHO) "RASM $@"
	$(RASM) $(RASMFLAGS) $< -o $(basename $@)

up-xmas2021.2.bin: up-xmas2021.2.asm frames
	@$(ECHO) "RASM	$@"
	@$(RASM) $(RASMFLAGS) $< -o $(basename $@)

%.m12: %.bin bin2m12
	@$(ECHO) "M12	$@"
	@./bin2m12 $< $@ UP-XMAS2021

clean:
	@$(ECHO) "CLEANING UP..."
	@rm -f *.m12 *.bin build_frame bin2m12
	@find $(BUILD_DIR) -name "*.o" -exec rm -f {} \;
