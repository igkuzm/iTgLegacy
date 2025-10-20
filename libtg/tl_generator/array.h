/**
 * File              : array.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.02.2022
 * Last Modified Date: 13.10.2024
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

/**
 * array.h
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

/*
 * C library for dynamic arrays
 * 
 * array_t * array_new(T, on_error) - allocate and return 
 * new array of types T
 * 
 * void array_append(array_t * array, T, T item, on_error)
 * - add item to array with type T
 * 
 * T item * array_at(struct array_t * array, T, int i) - 
 * return item from arrayat position i
 * 
 * array_for_each(struct array_t * array, T, T item){} - 
 * iterate the array
 * 
 * void array_free(struct array_t * array) - free array
 */

#ifndef ARRAY_H
#define ARRAY_H

#include <stdlib.h>
#include <string.h>

// Dynamyc array
typedef struct array {
  void *data;    
  int len;      // number of items in array
	int mem;      // number of allocated items
} array_t;

#define array_new(T, on_error)\
({\
  array_t *_a = malloc(sizeof(array_t));\
  if (!_a) {\
		on_error; \
	} else { \
		_a->data = malloc(sizeof(T));\
		if (!_a->data) {\
			on_error; \
		} \
		_a->len = 0;\
		_a->mem = 1;\
	}\
  _a;\
})

#define array_append(a, T, item, on_error)\
({\
	((T*)(a->data))[a->len++] = item; \
	if (a->len + 1>= a->mem){ \
		a->data = realloc(a->data, sizeof(T) * (a->len + 1));\
		if (!a->data){ on_error;} \
		a->mem = a->len + 1;\
  } \
})

#define array_at(a, T, index)\
({\
 if(index >= a->len && index < 0) return NULL;\
 return ((T*)(a->data))[index];\
})

#define array_insert(a, T, item, index, on_error) \
({\
	int r = 1; \
	if (index >= 0 && index < a->len) { \
		memmove(&(((T*)(a->data))[index+1]), &(((T*)(a->data))[index]), a->len-index); \
		((T)(a->data))[index] = item; \
		r=0; \
		if (a->len++ > a->mem){ \
			a->data = realloc(a->data, sizeof(T) * (++a->mem + 1));\
			if (!a->data) {r=1; on_error;} \
		} \
	} \
	r;\
})

#define array_remove(a, T, index)\
({\
	T r;\
	memset(&r,0,sizeof(T)); \
	if (index >= 0 && index < a->len) {\
		r = ((T*)(a->data))[index]; \
		if (index != a->len - 1){ \
			memmove(&(((T*)(a->data))[index]), &(((T*)(a->data))[index+1]), a->len-index); \
		}\
		a->len--; \
	}\
	r; \
})

#define array_for_each(a, T, item)\
T * _p##a; \
T item; \
for (_p##a = (a->data), item = *((T*)_p##a); _p##a < &(((T*)(a->data))[a->len]);\
     _p##a++, item = *((T*)_p##a))

#define array_free(a)\
  free(a->data);\
free(a);

#endif // ARRAY_H
