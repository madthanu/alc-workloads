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
	WriteOptions write_options;
	string key, value;

	options.create_if_missing = true;

	if(env_bool_decode("repairdb", true)) {
		ret = RepairDB(db_path(), options);
		status_assert(ret);
		exit(0);
	}

	if(env_bool_decode("checksums_verify", true)) {
		options.paranoid_checks = true;
	}


	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);
	int replayed_entries = read_and_verify(db);
	assert(replayed_entries == 0);

	write_options.sync = true;
	key = string(gen_string('a', 5000, 0));
	value = string(gen_string('A', 5000, 1));
	ret = db->Put(write_options, key, value);
	status_assert(ret);
	assert(read_and_verify(db) == replayed_entries + 1);
	delete db;

	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);
	assert(read_and_verify(db) == replayed_entries + 1);
	delete db;

	printf("Fully correct\n");
}
