include $(openarc)/make.header

# C compiler
ifeq ($(OPENARC_ARCH),0)
# CUDA target
OPENARCLIB_SUFFIX = cuda
OPENARC_KERNEL = "openarc_kernel.cu"
else
# OpenCL target
OPENARCLIB_SUFFIX = opencl
OPENARC_KERNEL = "openarc_kernel.cl"
endif

COMMONCFLAGS = $(GMACROS) $(GFRONTEND_FLAGS)
COMMONCLIBS = $(GFRONTEND_LIBS)
COMMONCINCLUDE = $(GFRONTEND_INCLUDES)
ifeq ($(OMP),1)
CLIBS = $(COMMONCLIBS) $(GOMP_LIBS)
CC_OMPFLAGS = $(GOMP_FLAGS)
OPENARCRT_BASE = openaccrtomp_$(OPENARCLIB_SUFFIX)
else
CLIBS = $(COMMONCLIBS) -lm 
OPENARCRT_BASE = openaccrt_$(OPENARCLIB_SUFFIX)
endif

MODE ?= normal
ifeq ($(MODE),profile)
CC_FLAGS = $(GPROFILEMACROS) $(CC_OMPFLAGS)
OPENARCRT = $(OPENARCRT_BASE)pf
else
CC_FLAGS = $(CC_OMPFLAGS)
OPENARCRT = $(OPENARCRT_BASE)
endif

LIBS = -L$(OPENARCLIB) -l$(OPENARCRT) $(CLIBS)
INCL = -I../../include -I$(OPENARCLIB) $(COMMONINCLUDE)
CFLAGS = $(COMMONCFLAGS) $(CC_FLAGS)
RunOpenARC = java -classpath $(openarc)/lib/cetus.jar:$(openarc)/lib/antlr.jar openacc.exec.ACC2GPUDriver -gpuConfFile=openarcConf.txt

BIN = ../../bin
SRC_DIR = .
#SRC_FILES := $(foreach DIR, $(SRC_DIR), $(wildcard $(SRC_DIR)/*.c))
SRC_FILES := $(wildcard *.c)
OBJS := $(patsubst %.c, %.o, $(SRC_FILES))
TARGETLIST := $(patsubst %.c, %, $(SRC_FILES))

single:$(APP)

all:$(TARGETLIST)
	@ echo all done


.PHONY: clean purge

$(TARGETLIST): $(SRC_FILES)
	@ echo ""
	@ echo "Target input: $@"
	@ echo ""
	if [ ! -f "openarcConf.txt" ]; then cp "openarcConf_NORMAL.txt" "openarcConf.txt"; fi
	if [ "$(OPENARCLIB)" != "" ]; then mv "openarcConf.txt" "openarcConf.txt_tmp"; cat "openarcConf.txt_tmp" | sed "s|__openarcrt__|${OPENARCLIB}|g" > "openarcConf.txt"; rm "openarcConf.txt_tmp"; fi
	if [ ! -d ../bin ]; then cd ../; mkdir -p bin; cd ./Tests; fi
	if [ ! -f ./cetus_output/$@.cpp ]; then $(RunOpenARC) $@.c; fi
	if [ ! -d ../bin/$@ ]; then cd ../bin; mkdir $@; cd ../Tests; fi
	if [ -f ./cetus_output/$@.cpp ] && [ ! -e $(BIN)/$@/$@ ]; then  cd cetus_output; $(CXX) $(CFLAGS) $(INCL) -o $@ $@.cpp $(LIBS); mv $@ $(BIN)/$@/; mv ./$(OPENARC_KERNEL) $(BIN)/$@/; fi

$(APP): $(APP).c
	@ echo ""
	@ echo "Targt input: $@"
	@ echo ""
	if [ ! -d ../bin ]; then cd ../; mkdir -p bin; cd ./Tests; fi
	if [ ! -d ../bin/$@ ]; then cd ../bin; mkdir -p $@; cd ../Tests; fi
	if [ ! -f "openarcConf.txt" ]; then cp "openarcConf_NORMAL.txt" "openarcConf.txt"; fi
	if [ "$(OPENARCLIB)" != "" ]; then mv "openarcConf.txt" "openarcConf.txt_tmp"; cat "openarcConf.txt_tmp" | sed "s|__openarcrt__|${OPENARCLIB}|g" > "openarcConf.txt"; rm "openarcConf.txt_tmp"; fi
	$(RunOpenARC) $@.c
	cd cetus_output; $(CXX) $(CFLAGS) $(INCL) -o $@ $@.cpp $(LIBS); mv $@ $(BIN)/$@/; cp ./$(OPENARC_KERNEL) $(BIN)/$@/

compile: $(APP).c
	@ echo ""
	@ echo "Targt input: $(APP)"
	@ echo ""
	if [ ! -d ../bin ]; then cd ../; mkdir -p bin; cd ./Tests; fi
	if [ ! -d ../bin/$(APP) ]; then cd ../bin; mkdir -p $(APP); cd ../Tests; fi
	cd cetus_output; $(CXX) $(CFLAGS) $(INCL) -o $(APP) $(APP).cpp $(LIBS); mv $(APP) $(BIN)/$(APP)/; cp ./$(OPENARC_KERNEL) $(BIN)/$(APP)/

cleanAPP:
	@ if [ "$(APP)" != "" ]; then rm -fr ../bin/$(APP) ../temp/* $(APP).cu ./cetus_output/$(APP).cpp; fi
	@ if [ "$(APP)" != "" ]; then echo clean bin/$(APP) done; fi

clean:
	@ rm -fr ../bin/* ../temp/* *.cu ./cetus_output/*
	@ echo clean bin done
	@ cp batchTest.bash ../bin/

purge: clean
	@ rm -f *.log openarcConf.txt
