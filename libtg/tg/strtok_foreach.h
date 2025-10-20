/**
 * File              : strtok_foreach.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 27.08.2024
 * Last Modified Date: 27.08.2024
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

/**
 * alloc.h
 * Copyright (c) 2024 Igor V. Sementsov <ig.kuzm@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/* restartable string tokinizer */

#ifndef STRTOK_FOREACH_H
#define STRTOK_FOREACH_H

#include <string.h>
#include <stdlib.h>

#define strtok_foreach(str, delim, token)\
	char *_s = strdup(str), *token, *_p;\
	for (token=strtok_r(_s, delim, &_p);\
			 token || ({if(_s) free(_s); 0;});\
			 token=strtok_r(NULL, delim, &_p))

#endif /* ifndef STRTOK_FOREACH_H */
