#include <cassert>
#include <iostream>
#include "leveldb/db.h"
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <unistd.h>
#include "../myutils.h"
#include "common.h"

using namespace std;
using namespace leveldb;

string key, value;

int main(int argc, char *argv[]) {
	DB* db;
	Options options;
	Status ret;
	WriteOptions write_options;

	options.create_if_missing = true;
	options.paranoid_checks = true;
	options.write_buffer_size = WRITE_BUFFER_SIZE;

	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);

	key = string(gen_string('a', 5000, 0));
	value = string(gen_string('A', 40000, 1));
	ret = db->Put(write_options, key, value);
	status_assert(ret);

	key = string(gen_string('b', 5000, 0));
	value = string(gen_string('B', 40000, 1));
	ret = db->Put(write_options, key, value);
	status_assert(ret);

	delete db;
}
