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
	int i;

	options.create_if_missing = true;
	ret = DB::Open(options, db_path(), &db);

	for(i = 0; i < 2; i++) {
		key = string(gen_string('c' + i, 5000, 0));
		value = string(gen_string('C' + i, 5000, 1));
		printf("before %d\n", i);
		ret = db->Put(write_options, key, value);
		printf("after %d\n", i);
	}
	status_assert(ret);
	delete db;
}

