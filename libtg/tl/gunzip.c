#include "buf.h"
#include "str.h"
#include "alloc.h"
#include <stdio.h>
#include <zlib.h>
char *gunzip_buf_err(int err){
	struct str str;
	str_init(&str);

	if (err != Z_OK && err != Z_STREAM_END){
		switch (err) {
			case Z_BUF_ERROR:
				str_appendf(&str, "%s: %s (%s)", 
					__func__, 
					"Z_BUF_ERROR",	
					"uncompress error:"
					" no progress is possible; either avail_in: "
					"or avail_out was zero");
				break;
			case Z_MEM_ERROR:
				str_appendf(&str, "%s: %s (%s)", 
					__func__, 
					"Z_MEM_ERROR",	
					"uncompress error: Insufficient memory");
				break;
			case Z_STREAM_ERROR:
				str_appendf(&str, "%s: %s (%s)", 
					__func__, 
					"Z_STREAM_ERROR",	
				  "uncompress error: The state (as "
					"represented in stream) is inconsistent, "
					"or stream was NULL");
				break;
			case Z_NEED_DICT:
				str_appendf(&str, "%s: %s (%s)", 
					__func__, 
					"Z_NEED_DICT",	
				  "uncompress error: A preset dictionary"
					" is required. The adler field shall be set to"
					" the Adler-32 checksum of the dictionary"
					" chosen by the compressor");
				break;
			case Z_DATA_ERROR:
				str_appendf(&str, "%s: %s (%s)", 
				__func__, 
				"Z_NEED_DICT",	
				"uncompress error: data is corrupted\n");
				break;
			
			default:
				str_appendf(&str, "%s: %s: %d", 
				__func__, 
				"uncompress error", err);
				break;
		}
	} else {
		str_appendf(&str, "no error");
	}
	return str.str;
}

int gunzip_buf(buf_t *dst, buf_t src){
	// allocte data
	buf_init(dst);
	buf_realloc(dst, src.size * 10);

	z_stream s;
	s.zalloc    = Z_NULL;
	s.zfree     = Z_NULL;
	s.opaque    = Z_NULL;
	s.avail_in  = src.size;
	s.next_in   = src.data;
	s.avail_out = dst->asize;
	s.next_out  = dst->data;
	if (inflateInit2(&s, 16 + MAX_WBITS) != Z_OK){
		printf("can't init inflate\n");
		return 1;
	} 

	int ret = inflate(&s, Z_FINISH);  
	if (ret != Z_OK && ret != Z_STREAM_END){
		return ret;
	}

	inflateEnd(&s);
	dst->size = s.total_out;
	
	fprintf(stderr, "%s gunziped len: %ld\n",
		 	__func__, s.total_out);
	
	return 0;
}
