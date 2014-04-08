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
	char *replayed_stdout = argv[2];

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
	int replayed_entries = read_and_verify(db, 5000, 40000);
	if (strstr(replayed_stdout, "before 0") == NULL) {
		// printf("Checking before before. ");
		assert(replayed_entries == 4);
	} else if(strstr(replayed_stdout, "after 4") == NULL) {
		// printf("Checking between before and after. ");
		assert(replayed_entries >= 4 and replayed_entries <= 9);
	} else {
		assert(replayed_entries == 9);
	}

	write_options.sync = true;
	key = string(gen_string('a' + replayed_entries, 5000, 0));
	value = string(gen_string('A' + replayed_entries, 40000, 1));
	ret = db->Put(write_options, key, value);
	status_assert(ret);
	assert(read_and_verify(db, 5000, 40000) == replayed_entries + 1);
	delete db;

	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);
	assert(read_and_verify(db, 5000, 40000) == replayed_entries + 1);
	delete db;

	printf("Fully correct\n");
}
