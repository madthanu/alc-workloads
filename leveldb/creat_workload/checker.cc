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

string key, value;

#define status_assert(status) 	if(!status.ok()) { \
					cout << status.ToString() << endl; \
				} \
				assert(status.ok());


void read_and_verify(DB *db) {
	int number_of_entries = 0;
	ReadOptions read_options;
	read_options.verify_checksums = true;
	Iterator* it = db->NewIterator(read_options);
	status_assert(it->status());
	for (it->SeekToFirst(); it->Valid(); it->Next()) {
		status_assert(it->status());
		assert(key == it->key().ToString());
		assert(value == it->value().ToString());
		status_assert(it->status());
		number_of_entries++;
	}
	delete it;
	assert(number_of_entries == 1);
}

int main(int argc, char *argv[]) {
	DB* db;
	Options options;
	Status ret;
	WriteOptions write_options;

	options.create_if_missing = true;
	options.paranoid_checks = true;

	key = string(gen_string('a', 5000, 0));
	value = string(gen_string('A', 5000, 1));

	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);
	write_options.sync = true;
	ret = db->Put(write_options, key, value);
	status_assert(ret);
	read_and_verify(db);
	delete db;

	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);
	read_and_verify(db);
	delete db;

	printf("Fully correct.\n");
}
