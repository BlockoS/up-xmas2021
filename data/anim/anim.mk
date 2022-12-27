frames := $(patsubst $(INDIR)/ScreenCharacterData_Layer_0_%.bin, %.bin, $(wildcard $(INDIR)/ScreenCharacterData_Layer_0_*.bin))

all: $(frames)

.PHONY: all

$(OUTDIR):
	@mkdir -p $(OUTDIR)

%.bin: $(OUTDIR)
	@echo "creating $@"
	@./build_frame $(INDIR)/ScreenCharacterData_Layer_0_$@ $(INDIR)/ScreenColorData_Layer_0_$@ $(OUTDIR)/$@
