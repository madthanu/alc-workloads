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


int read_and_verify(DB *db) {
	int number_of_entries = 0;
	string key, value;
	ReadOptions read_options;
	read_options.verify_checksums = true;
	Iterator* it = db->NewIterator(read_options);
	status_assert(it->status());
	for (it->SeekToFirst(); it->Valid(); it->Next()) {
		status_assert(it->status());
		key = string(gen_string(number_of_entries % 26 + 'a', 5000, 0));
		value = string(gen_string(number_of_entries % 26 + 'A', 5000, 1));
		if(key != it->key().ToString()) {
			printf("key and it->key() mismatch. Expected: %c, Got: %.20s.\n", number_of_entries % 26 + 'a', it->key().ToString().c_str());
			assert(false);
		}
		if(value != it->value().ToString()) {
			printf("key and it->key() mismatch. Expected: %c, Got: %.20s.\n", number_of_entries % 26 + 'a', it->value().ToString().c_str());
			assert(false);
		}
		status_assert(it->status());
		number_of_entries++;
	}
	delete it;
	return number_of_entries;
}

int main(int argc, char *argv[]) {
	DB* db;
	Options options;
	Status ret;
	WriteOptions write_options;
	string key, value;
	char *replayed_stdout = argv[3];

	options.create_if_missing = true;
	options.paranoid_checks = true;

	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);
	int replayed_entries = read_and_verify(db);
	if(strstr(replayed_stdout, "after") != NULL) {
		// After printing "after"
		printf("Checking after after. ");
		assert(replayed_entries == 3);
	} else if (strstr(replayed_stdout, "before") == NULL) {
		// Before printing "before"
		printf("Checking before before. ");
		assert(replayed_entries == 2);
	} else {
		// After printing "before", but before printing "after"
		printf("Checking between before and after. ");
		assert(replayed_entries == 2 || replayed_entries == 3);
	}
	write_options.sync = true;
	key = string(gen_string('a' + replayed_entries, 5000, 0));
	value = string(gen_string('A' + replayed_entries, 5000, 1));
	ret = db->Put(write_options, key, value);
	status_assert(ret);
	assert(read_and_verify(db) == replayed_entries + 1);
	delete db;

	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);
	assert(read_and_verify(db) == replayed_entries + 1);
	delete db;

	printf("Fully correct.\n");
}
