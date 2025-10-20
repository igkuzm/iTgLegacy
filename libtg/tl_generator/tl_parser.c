#include "tl_parser.h"
#include "strtok_foreach.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

struct arg_t {
	char *name;
	char *type;
	int flagn;
	int flagb;
};

void print_method(const struct method_t *m)
{
	printf("METHOD: {\n");
	printf("\tname: %s\n", m->name);
	printf("\tid: %.8x\n", m->id);
	printf("\tret: %s\n", m->ret);
	printf("\targs: [\n");
	int i;
	for (i = 0; i < m->argc; ++i) {
		printf("\t\t{\n");	
		printf("\t\t\tname: %s\n", m->args[i].name);	
		printf("\t\t\ttype: %s\n", m->args[i].type);	
		printf("\t\t\tflagn: %d\n", m->args[i].flagn);	
		printf("\t\t\tflagb: %d\n", m->args[i].flagb);	
		printf("\t\t}\n");	
	}
	printf("\t]\n");
	printf("}\n");
}

static int parse_method_args(
		struct method_t *m,
		struct arg_t *t,
		char *buf)
{
	t->flagn = 0;
	/*if (strcmp(buf, "{X:Type}") == 0){*/
		/*t->type = strtok(buf, "{:");*/
		/*t->name = strtok(NULL, ":}");*/
		/*return 0;*/
	/*}*/

	t->name = strtok(buf, ":");
	if (strstr(t->name, "flags") && 
			strlen(t->name) < 7)
		m->nflags++;

	char *ftype = strtok(NULL, ":"); 
	
	char *flag = strtok(ftype, "?");
	char *type = strtok(NULL, "?");
	if (type){
		// get flags
		t->flagn = 1;
		if (sscanf(flag, "flags.%d", &t->flagb) < 1)
			sscanf(flag, "flags%d.%d", &t->flagn, &t->flagb);
	} else
		type = ftype;

	t->type = type;
	return 0;
}

static int parse_method_id_and_args(
		struct method_t *m,
		char *buf, int idx)
{
	strtok_foreach(buf, " ", arg)
	{
		if (idx == 1){
			sscanf(arg, "%x", &m->id);
			idx++;
			continue;
		}
	
		if (strcmp(arg, "{X:Type}") == 0)
			continue;

		parse_method_args(
				m,
				(struct arg_t *)(&m->args[m->argc++]), 
				strdup(arg));
	}
	return 0;
}

static int parse_method(struct method_t *m, char *buf)
{
	// get method id and flargs
	int idx = 0;
	strtok_foreach(buf, "#", str)
	{
		// check method name
		if (idx == 0){
			m->name = strdup(str);
			// remove '//' from name
			if(m->name[0] == '/')
				m->name += 2;
			idx++;
			continue;
		}

		// check vector declaration
		if (strstr(str, "{t:Type}")){
			char *arg = strtok(str, " ");
			sscanf(arg, "%x", &m->id);
			m->ret = strtok(NULL, "{t:}");
			return 0;
		}
		
		// get args
		parse_method_id_and_args(m, str, idx);
		idx++;
	}

	return 0;
}

static int parse_method_return(struct method_t *m, char *buf)
{
	// get method return type
	char *ret = strtok(buf, " ;");
	if (!ret)
		return 1;
	m->ret = ret;
	return 0;
}

static int parse_schema(
		FILE *fp, void *userdata,
		int (*callback)(
			void *userdata,
			const struct method_t *m,
			const char *error))
{
	int i;
	char buf[BUFSIZ*2], *a;
	for(a = fgets(buf, BUFSIZ*2, fp), i=1;
			a;
			a = fgets(buf, BUFSIZ*2, fp), i++)
	{
		// skip empty lines
		if (!*buf || *buf == ' ' || *buf == '\n')
			continue;
		
		char *s = strdup(buf);
		if (!s)
			return i;
		
		// get method
		char *method = strtok(s, "=");
		if (!method)
			return i;
		
		// get return type
		char *ret = strtok(NULL, "="); 
		if (!ret) // skip this line - this is not declaration
			continue;

		struct method_t m;
		memset(&m, 0, sizeof(m));
		int err;
		err = parse_method_return(&m, ret);
		err = parse_method(&m, method);
		
		//	drop simple types
		if (strrchr(m.name, '?'))
			continue;
		if (m.id == 0)
			continue;

		if (callback)
			if (callback(userdata, &m, NULL))
				break;
		
		free(s);
		if (err)
			return i;
	}

	return 0;
}

int tl_parse(
		const char *schema_file, 
		void *userdata,
		int (*callback)(
			void *userdata, 
			const struct method_t *m,
			const char *error))
{
	// open schema
	FILE *fp = fopen(schema_file, "r");
	if (!fp){
		if (callback)
			callback(userdata, NULL, "can't open file");
		return 1;
	}

	int err = parse_schema(
			fp, userdata, callback);
	fclose(fp);
	return err;
}
