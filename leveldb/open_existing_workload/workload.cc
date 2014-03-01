#include <cassert>
#include <iostream>
#include "leveldb/db.h"
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <unistd.h>
#include "../myutils.h"

using namespace std;
using namespace leveldb;


int main(int argc, char *argv[]) {
	DB* db;
	Options options;
	Status ret;

	options.create_if_missing = true;
	ret = DB::Open(options, db_path(), &db);
	delete db;
}

