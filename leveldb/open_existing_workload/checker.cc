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

#define status_assert(status) 	if(!status.ok()) { \
					cout << status.ToString() << endl; \
				} \
				assert(status.ok());


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
		assert(key == it->key().ToString());
		assert(value == it->value().ToString());
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

	options.create_if_missing = true;
	options.paranoid_checks = true;

	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);
	assert(read_and_verify(db) == 2);
	write_options.sync = true;
	key = string(gen_string('c', 5000, 0));
	value = string(gen_string('C', 5000, 1));
	ret = db->Put(write_options, key, value);
	status_assert(ret);
	assert(read_and_verify(db) == 3);
	delete db;

	ret = DB::Open(options, db_path(), &db);
	status_assert(ret);
	assert(read_and_verify(db) == 3);
	delete db;

	printf("Fully correct.\n");
}
