/**
 * File              : alloc.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.02.2022
 * Last Modified Date: 10.09.2024
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

/**
 * alloc.h
 * Copyright (c) 2022 Igor V. Sementsov <ig.kuzm@gmail.com>
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

/* safe memory allocation */

#ifndef ALLOC_H
#define ALLOC_H


#include <stdlib.h>
#include <string.h>

#define MALLOC(size, on_error) \
({\
	void *_p = malloc(size);\
	if (!_p) {\
		on_error;\
	} else { \
		memset(_p,0,size);\
	} \
	_p;\
})

#define REALLOC(ptr, size, on_error) \
({\
	void *_ret = ptr; \
	void *_p = realloc(ptr, size);\
	if (!_p){\
		on_error;\
	} else { \
		_ret = _p; \
	}\
	_ret;\
})

#define NEW(T, on_error)\
	((T *)MALLOC(sizeof(T), on_error))

#endif /* ifndef ALLOC_H */
