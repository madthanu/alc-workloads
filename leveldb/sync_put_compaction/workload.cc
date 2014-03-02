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
	WriteOptions write_options;
	string key, value;
	Status ret;

	options.create_if_missing = true;
	ret = DB::Open(options, db_path(), &db);

	write_options.sync = true;
	key = string(gen_string('c', 5000, 0));
	value = string(gen_string('C', 5000, 1));
	printf("before\n");
	ret = db->Put(write_options, key, value);
	printf("after\n");
	status_assert(ret);
	delete db;
}

