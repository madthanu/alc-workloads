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

const char *small_description(string str) {
	static char buffers[5][100];
	static int count = 0;
	char *toret = buffers[count];
	count = (count + 1) % 5;
	if(str.length() > 5) {
		sprintf(toret, "%.5s(%d chars, last char: %d)%.5s", str.c_str(), str.length(), int(str.c_str()[str.length() - 1]), str.c_str() + (str.length() - 5));
	} else {
		sprintf(toret, "%.5s(%d chars)", str.c_str(), str.length());
	}
	return toret;
}

int read_and_verify(DB *db) {
	int number_of_entries = 0;
	string key, value;
	ReadOptions read_options;
	read_options.verify_checksums = true;
	Iterator* it = db->NewIterator(read_options);
	status_assert(it->status());
	int character_present[256];
	memset(character_present, 0, 256 * sizeof(int));
	for (it->SeekToFirst(); it->Valid(); it->Next()) {
		status_assert(it->status());
		assert(it->key().ToString().length() != 0);
		unsigned char row_character = it->key().ToString().c_str()[0];
		key = string(gen_string(row_character, 5000, 0));
		value = string(gen_string(row_character - 'a' + 'A', 40000, 1));
		if(key != it->key().ToString()) {
			printf("key and it->key() mismatch. Expected: %c, Got: %s\n", number_of_entries % 26 + 'a', small_description(it->key().ToString()));
			assert(false);
		}
		if(value != it->value().ToString()) {
			printf("value and it->value() mismatch. Expected: %c, Got: %s\n", number_of_entries % 26 + 'A', small_description(it->value().ToString()));
			assert(false);
		}
		status_assert(it->status());
		character_present[(unsigned int) row_character] = 1;
		number_of_entries++;
	}
	delete it;
	unsigned int i;
	for(i = 0; i < number_of_entries; i++) {
		assert(character_present[i + 'a'] == 1);
	}
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
	if (strstr(replayed_stdout, "before 0") == NULL) {
		// printf("Checking before before. ");
		assert(replayed_entries == 2);
	} else if(strstr(replayed_stdout, "after 0") == NULL) {
		// printf("Checking between before and after. ");
		assert(replayed_entries == 2 || replayed_entries == 3);
	} else if (strstr(replayed_stdout, "before 1") == NULL) {
		// printf("Checking before before. ");
		assert(replayed_entries == 3);
	} else if(strstr(replayed_stdout, "after 1") == NULL) {
		// printf("Checking between before and after. ");
		assert(replayed_entries == 3 || replayed_entries == 4);
	} else if (strstr(replayed_stdout, "before 2") == NULL) {
		// printf("Checking before before. ");
		assert(replayed_entries == 4);
	} else if(strstr(replayed_stdout, "after 2") == NULL) {
		// printf("Checking between before and after. ");
		assert(replayed_entries == 4 || replayed_entries == 5);
	} else {
		assert(replayed_entries == 5);
	}

	write_options.sync = true;
	key = string(gen_string('a' + replayed_entries, 5000, 0));
	value = string(gen_string('A' + replayed_entries, 40000, 1));
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
