LEVELDB_SRC = ../leveldb-1.10.0
EXECUTABLES = workload checker
DEPENDENCIES = ../myutils.h Makefile

all: $(EXECUTABLES)

%: %.cc $(LEVELDB_SRC) $(LEVELDB_SRC)/libleveldb.a $(DEPENDENCIES)
	g++ -g -o $@ $< $(LEVELDB_SRC)/libleveldb.a -I$(LEVELDB_SRC)/include -lpthread

clean:
	rm -f $(EXECUTABLES)
