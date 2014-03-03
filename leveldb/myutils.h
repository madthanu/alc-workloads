#include <cstring>
#include <unistd.h>
#include <cassert>
#include "leveldb/db.h"

using namespace std;
using namespace leveldb;

#define status_assert(status) 	if(!status.ok()) { \
					cout << status.ToString() << ". "; \
					cout.flush(); \
				} \
				assert(status.ok());

static const char *gen_string(char c, int size, int randomize) {
	#define MAX_SIZE 100000
	#define REENTRY_MAX 5
	static char answers[REENTRY_MAX][MAX_SIZE + 1];
	assert(size <= MAX_SIZE);
	static int cnt = 0;
	int i;
	char *toret = answers[cnt];
	cnt = (cnt + 1) % REENTRY_MAX;
	int x = 0;
	for(i = 0; i < size; i++) {
		if(randomize) {
			toret[i] = c + x;
			x = (x + 1) % ('z' - 'a');
		} else {
			toret[i] = c;
		}
	}
	toret[i] = '\0';
	return toret;
}

static const char *small_description(string str) {
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

static int read_and_verify(DB *db, int key_length = 5000, int value_length = 5000) {
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
		key = string(gen_string(row_character, key_length, 0));
		value = string(gen_string(row_character - 'a' + 'A', value_length, 1));
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


static const char *db_path() {
	static int initialized = 0;
	static char db[1001];
	if(!initialized) {
		const char *workload_dir = getenv("workload_dir");
		const char *dbname = "/testdb";
		assert(workload_dir != NULL);
		strncpy(db, workload_dir, 1000);
		int len = strlen(db);
		assert(len > 0);
		assert(len < 1000 - strlen(dbname));
		if(db[len - 1] == '/') {
			db[len - 1] == '\0';
			len--;
		}
		strcat(db, dbname);
		initialized = 1;
	}
	return db;
}

static bool env_bool_decode(const char *s, bool optional) {
	char *trace_only = getenv(s);
	if(!optional) {
		assert(trace_only != NULL);
	}
	if(trace_only == NULL || strcmp(trace_only, "") == 0 || trace_only[0] == 'n' || trace_only[0] == 'N' || trace_only[0] == '0' || trace_only[0] == 'f' || trace_only[0] == 'F')
		return false;
	return true;
}
