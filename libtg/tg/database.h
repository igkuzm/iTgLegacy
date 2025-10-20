#ifndef TG_DATABASE_H
#define TG_DATABASE_H
#include "tg.h"
sqlite3 * tg_sqlite3_open(tg_t *tg); 
int tg_sqlite3_prepare(
		tg_t *tg, sqlite3 *db, const char *sql, sqlite3_stmt **stmt); 

#define tg_sqlite3_for_each(tg, sql, stmt) \
	sqlite3 *db = tg_sqlite3_open(tg);\
	sqlite3_stmt *stmt;\
	int sqlite_step;\
	if (db != NULL)\
		if (tg_sqlite3_prepare(tg, db, sql, &stmt) == 0)\
			for (sqlite_step = sqlite3_step(stmt);\
					sqlite_step	!= SQLITE_DONE || ({sqlite3_finalize(stmt); sqlite3_close(db); 0;});\
					sqlite_step = sqlite3_step(stmt))\
			 
int tg_sqlite3_exec(tg_t *tg, const char *sql);

#endif /* ifndef TG_DATABASE_H */
