#include <cstring>
#include <unistd.h>
#include <cassert>

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
