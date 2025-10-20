/**
 * File              : list.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 23.03.2022
 * Last Modified Date: 09.01.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

/**
 * list.h
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
 * Simple list functions
 * add items in back order
 *
 * list_t *list = NULL; //create new list
 * list_add(&list, "!"); 
 * list_add(&list, "world"); 
 * list_add(&list, "hello");
 * 
 * // iterete the list:
 * char *str;
 * list_for_each(list, str){
 *		printf("%s ", str);	
 * } 
 * printf("\n");
 */

#ifndef LIST_H
#define LIST_H

#include <stdio.h>
#include <stdlib.h>

typedef struct list {
	struct list *prev;
	void *data;
} list_t;


// prepend item to list
static int list_add(list_t **listp, void *item)
{
	list_t *n  = (list_t *)malloc(sizeof(list_t));
	if (n == NULL)
		return 1;
	n->prev = *listp;
	n->data = item;
	*listp = n;
	return 0;
}

// remove from list and return item if cmp return true
static void *list_cut(list_t **listp, void *ptr, 
		int (*cmp)(void *ptr, void *item))
{
	void *data = NULL;
	list_t *l = *listp;
	list_t *prev = NULL;
	while(l) {
		if (cmp(ptr, l->data)) {
			data = l->data;
			if (prev)
				prev->prev = l->prev; 
			else 
				*listp = l->prev;
			free(l); 
			break; 
		}
		prev = l; 
		l = l->prev; 
	}
	return data; 
}

//foreach item at list
#define list_for_each(list, item) \
	list_t *__p = list; \
	if (__p) \
		for (item=__p->data; __p; __p=__p->prev, item = __p?__p->data:NULL)

//free memory of list
static void list_free(list_t **listp)
{
	list_t *l = *listp;
	while(l) {
		list_t * prev = l->prev;
		free(l);
		l = prev;
	}
	*listp = NULL;
}

#endif // LIST_H
