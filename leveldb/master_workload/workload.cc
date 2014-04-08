#include <cassert>
#include <iostream>
#include "leveldb/db.h"
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <unistd.h>
#include "common.h"
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

	options.write_buffer_size = WRITE_BUFFER_SIZE;
	options.create_if_missing = true;
	ret = DB::Open(options, db_path(), &db);

	printf("opened\n");
	for(i = 0; i < 5; i++) {
		key = string(gen_string('e' + i, 5000, 0));
		value = string(gen_string('E' + i, 40000, 1));
		write_options.sync = false;
		if(i == 4) {
			write_options.sync = true;
		}
		printf("before %d\n", i);
		ret = db->Put(write_options, key, value);
		printf("after %d\n", i);
		status_assert(ret);
	}
	printf("closing\n");
	delete db;
}
