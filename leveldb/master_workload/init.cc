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

int main(int argc, char *argv[]) {
	DB* db;
	Options options;
	Status ret;
	WriteOptions write_options;
	string key, value;


	options.create_if_missing = true;
	options.paranoid_checks = true;
	options.write_buffer_size = WRITE_BUFFER_SIZE;
	write_options.sync = true;

	int i, j, k;
	k = 0;
	
	for(i = 0; i < 2; i++) {
		ret = DB::Open(options, db_path(), &db);
		status_assert(ret);
		for(j = 0; j < 2; j++) {
			key = string(gen_string('a' + k, 5000, 0));
			value = string(gen_string('A' + k, 40000, 1));
			ret = db->Put(write_options, key, value);
			status_assert(ret);
			k++;
		}
		delete db;
	}
}
