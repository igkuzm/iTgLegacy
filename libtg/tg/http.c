#include "../libtg.h"
#include "tg.h"
#include "dc.h"
#include <curl/curl.h>
#include <curl/easy.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/select.h>
#include <unistd.h>
#include "transport.h"
#include "answer.h"
#include "errors.h"
#include "../mtx/include/api.h"

#define VERIFY_SSL 0

/*  HTTPS
 *
 *  To establish a connection over HTTPS, simply use the TLS
 *  URI format. The rest is the same as with plain HTTP.
 *
 *  URI format
 *
 *  The URI format that must be used when connecting to the
 *  plain WebSocket and HTTP endpoints is the following:
 *
 *  http://X.X.X.X:80/api(w)(s)
 *
 *  The following URI may also be used only for HTTP and
 *  secure WebSocket endpoints (not usable for plain
 *  WebSocket connections):
 *
 *  http://(name)(-1).web.telegram.org:80/api(w)(s)(_test)
 *
 *  The w flag is added when CORS headers are required in
 *  order to connect from a browser.
 *  The s flag enables the WebSocket API.
 *  The name placeholder in the domain version specifies
 *  the DC ID to connect to:
 *
 * • pluto => DC 1
 * • venus => DC 2
 * • aurora => DC 3
 * • vesta => DC 4
 * • flora => DC 5
 *
 *  -1 can be appended to the DC name to raise
 *  the maximum limit of simultaneous requests
 *  per hostname.
 *  The _test flag, when connecting to the domain
 *  version of the URL, specifies that connection
 *  to the test DCs must be made, instead.
 */

#define URI    "%s%s.web.telegram.org:%d/api%s"
#define URI_IP "%s:%d/api%s"

static size_t tg_http_readfunc(
		unsigned char *data, size_t s, size_t n, 
		buf_t *buf)
{
	/*printf("%s: len %ld\n", __func__, s*n);*/
	size_t size = s * n;
	
	if (size > buf->size)
		size = buf->size;

	memcpy(data, buf->data, size);
	
	buf->data += size;
	buf->size -= size;

	return s;
}

static size_t tg_http_writefunc(
		unsigned char  *data, size_t s, size_t n, 
		buf_t *buf)
{
	printf("%s: len %ld\n", __func__, s*n);

	size_t len = s * n;
	*buf = buf_cat_data(*buf, data, len);

  return len;
}

CURL *tg_http_open_connection(
		tg_t *tg, int dc, int port, 
		bool maximum_limit)
{
	ON_LOG(tg, "%s line: %d", __func__, __LINE__);


	CURL *curl = curl_easy_init();
	if (!curl){
		ON_ERR(tg, "%s: can't init curl", __func__);
		return NULL;
	}

	//debug
	curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);

	const char *ipv4 = DCs[dc-1].ipv4;

	char url[BUFSIZ];
	snprintf(url, BUFSIZ-1, URI_IP, ipv4, port, "");
	
	ON_LOG(tg, "%s: open url: %s", __func__, url);
	
	curl_easy_setopt(curl, CURLOPT_URL, url);
	curl_easy_setopt(curl, CURLOPT_CONNECT_ONLY, 1L);

	curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, VERIFY_SSL);		
	curl_easy_setopt(curl, CURLOPT_TCP_KEEPALIVE, 1L);
	
	CURLcode res = curl_easy_perform(curl);
	if (res != CURLE_OK){
			ON_LOG(tg, "%s: error: %s", __func__, curl_easy_strerror(res));
			curl_easy_cleanup(curl);
			return NULL;
	}

	 return curl;
}

CURLcode tg_http_send(tg_t *tg, CURL *curl, buf_t *query)
{
	ON_LOG(tg, "%s line: %d", __func__, __LINE__);
	curl_socket_t sockfd;
	size_t sent = 0;

	char header[BUFSIZ];
	sprintf(header, "POST /post HTTP/1.1 200 OK\\r\\n"
									"Keep-alive\\r\\n"
									"Content-Type: application/json\\r\\n"
									"Content-Length: %d\\r\\n", query->size);

	/*curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");		*/

	/*curl_easy_setopt(curl, CURLOPT_HEADER, 0);*/
	/*curl_easy_setopt(curl, CURLOPT_POST, 1L);		*/
	/*curl_easy_setopt(curl, CURLOPT_POSTFIELDS, query->data);*/
	/*curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, query->size);*/

	/*curl_easy_setopt(curl, CURLOPT_UPLOAD, 1L);*/
	/*curl_easy_setopt(curl, CURLOPT_READDATA, query);*/
	/*curl_easy_setopt(curl, CURLOPT_READFUNCTION, tg_http_readfunc);*/
	/*curl_easy_setopt(curl, CURLOPT_INFILESIZE_LARGE, query->size);*/
		
	//Extract the socket from the curl handle - we need it for waiting. 
	if (curl_easy_getinfo(curl, CURLINFO_ACTIVESOCKET, &sockfd) != CURLE_OK)
	{
		ON_ERR(tg, "%s: curl_easy_getinfo error", __func__);
	};

	CURLcode res = curl_easy_perform(curl);
	curl_easy_send(curl, header, strlen(header), NULL);

	//send data 
	while (sent < query->size){
		if (curl_easy_send(
				curl, query->data, query->size, &sent) != CURLE_OK)
		{
			ON_ERR(tg, "%s: curl_easy_send error", __func__);
		}
	}

	ON_LOG(tg, "%s: query size: %d", __func__, query->size);
	ON_LOG(tg, "%s: sent data: %d", __func__, sent);

	return CURLE_OK;
}

buf_t tg_http_recieve(tg_t *tg, CURL *curl)
{
	ON_LOG(tg, "%s line: %d", __func__, __LINE__);
	curl_socket_t sockfd;
	size_t nread;
	buf_t buf = buf_new();
	CURLcode res;

	curl_easy_setopt(curl, CURLOPT_WRITEDATA, &buf);		
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, tg_http_writefunc);
	
	/* Extract the socket from the curl handle - we need it for waiting. */
	if (curl_easy_getinfo(curl, CURLINFO_ACTIVESOCKET, &sockfd) != CURLE_OK)
	{
		ON_ERR(tg, "%s: curl_easy_getinfo error", __func__);
	};

	/* rescieve data */
	res = CURLE_AGAIN;
	while (res == CURLE_AGAIN) {
		res = curl_easy_recv(curl, buf.data, 
				buf.size, &nread); 
		if (res != CURLE_OK && res != CURLE_AGAIN)
		{
			ON_ERR(tg, "%s: curl_easy_recv error: %d", __func__, res);
		}
	}

	ON_LOG(tg, "%s: received: %d", __func__, nread);
	return buf;
}

static int tg_parse_answer_callback(void *d, const tl_t *tl)
{
	tl_t **answer = d;
	*answer = tl_deserialize((buf_t *)(&tl->_buf));
	return 0;
}

tl_t * tg_http_send_query_with_progress(
		tg_t *tg, int dc, int port, bool maximum_limit, 
		buf_t *query,
		void *progressp, 
		int (*progress)(void *progressp, int size, int total))
{
	/*buf_t buf = buf_new();*/

	// auth_key
	if (!tg->key.size){
		ON_LOG(tg, "new auth key");
		app_t mtx = api.app.open(tg->ip, 80); // set port	
		tg->key = 
			buf_add(shared_rc.key.data, shared_rc.key.size);
		tg->salt = 
			buf_add(shared_rc.salt.data, shared_rc.salt.size);
		tg->seqn = shared_rc.seqnh + 1;
		api.app.close(mtx);
	}

	// session id
	if (!tg->ssid.size){
		ON_LOG(tg, "new session id");
		tg->ssid = buf_rand(8);
	}

	// server salt
	if (!tg->salt.size){
		ON_LOG(tg, "new server salt");
		tg->salt = buf_rand(8);
	}

	// prepare query
	uint64_t msgid;
	buf_t headered = tg_header(tg, *query, true,
		 	true, &msgid);
	buf_t encrypted = tg_encrypt(tg, headered, true);
	buf_free(headered);

	ON_LOG_BUF(tg, encrypted, "%s: DATA to upload: ", __func__);
	
	/*CURL *curl = curl_easy_init();*/
	/*if (!curl){*/
		/*ON_ERR(tg, "%s: can't init curl", __func__);*/
		/*return NULL;*/
	/*}*/

	CURL *curl = tg_http_open_connection(tg, dc, port, maximum_limit);
	if (curl == NULL){
		return NULL;
	}
	
	//const char *ipv4 = DCs[dc-1].ipv4;
		
	//char url[BUFSIZ];
	/*snprintf(url, BUFSIZ-1, URI, */
			/*DCs[dc].name, maximum_limit?"-1":"", port, test?"_test":"");*/
	//snprintf(url, BUFSIZ-1, URI_IP, 
	//		ipv4, port, "");
	
	//ON_LOG(tg, "%s: open url: %s", __func__, url);
	
	//struct curl_slist *header = NULL;
	
	//curl_easy_setopt(curl, CURLOPT_URL, url);
	//curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");		

	//curl_easy_setopt(curl, CURLOPT_HEADER, 0);
	//curl_easy_setopt(curl, CURLOPT_POST, 1L);		
	//curl_easy_setopt(curl, CURLOPT_POSTFIELDS, encrypted.data);
	//curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, encrypted.size);

	/* enable TCP keep-alive for this transfer */
//#if LIBCURL_VERSION_NUM < 0x072050
//	header = curl_slist_append(header, "Keep-alive");
//#else
//  curl_easy_setopt(curl, CURLOPT_TCP_KEEPALIVE, 1L);
//#endif
	
//	curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header);

	/*curl_easy_setopt(curl, CURLOPT_UPLOAD, 1L);*/
	/*curl_easy_setopt(curl, CURLOPT_READDATA, query);*/
	/*curl_easy_setopt(curl, CURLOPT_READFUNCTION, tg_http_readfunc);*/
	/*curl_easy_setopt(curl, CURLOPT_INFILESIZE_LARGE, query->size);*/
		
//	curl_easy_setopt(curl, CURLOPT_WRITEDATA, &buf);		
//	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, tg_http_writefunc);

//  curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, VERIFY_SSL);		

	//if (progress) {
//#if LIBCURL_VERSION_NUM < 0x072000
		//curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, ptr);
		//curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, 
		//		progress);
//#else
		//curl_easy_setopt(curl, CURLOPT_XFERINFODATA, progressp);
		//curl_easy_setopt(curl, CURLOPT_XFERINFOFUNCTION, 
		//		progress);
//#endif
		//curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0);
	//}
		
//	CURLcode err = curl_easy_perform(curl);
	CURLcode err = tg_http_send(tg, curl, &encrypted);
	if (err){
		return NULL;
	}
	buf_free(encrypted);
	//curl_easy_cleanup(curl);
	//if (err){
		//ON_ERR(tg, "%s: %s", __func__, curl_easy_strerror(err));
		//return buf;
	//}

	/* now extract transfer info */
	/*curl_off_t usize, dsize;*/
	
/*#if LIBCURL_VERSION_NUM < 0x072000*/
	/*curl_easy_getinfo(curl, */
						/*CURLINFO_CONTENT_LENGTH_UPLOAD, &usize);*/
	/*curl_easy_getinfo(curl, */
						/*CURLINFO_CONTENT_LENGTH_DOWNLOAD, &dsize);*/
/*#else*/
	/*curl_easy_getinfo(curl, */
			/*CURLINFO_CONTENT_LENGTH_UPLOAD_T, &usize);*/
	
	/*curl_easy_getinfo(curl, */
			/*CURLINFO_CONTENT_LENGTH_DOWNLOAD_T, &dsize);*/
/*#endif*/
	
	/*ON_LOG(tg, "%s: uploaded: %ld", __func__, usize);*/
	/*ON_LOG(tg, "%s: downloaded: %ld", __func__, dsize);*/

	buf_t buf = tg_http_recieve(tg, curl);
	ON_LOG_BUF(tg, buf, "GOT DATA: ");
	if (buf.size == 0){
		buf_free(buf);
		return NULL;
	}

	// deheader message
	headered = tg_decrypt(tg, buf, true); 
	buf_free(buf);

	// decrypt message
	buf_t payload = tg_deheader(tg, headered, true);
	buf_free(headered);

// deserialize 
	tl_t *tl = tl_deserialize(&payload);
	buf_free(payload);

	tl_t *answer = NULL;
	tg_parse_answer(tg, tl, msgid,
		 	&answer, tg_parse_answer_callback);
	if (answer){
		tl_free(tl);
		tl = answer;
	} 
	//else {
		//while(answer == NULL){
			//// load data again
			//buf = tg_http_recieve(tg, curl);
			//headered = tg_decrypt(tg, buf, true); 
			//buf_free(buf);

			//buf_t payload = tg_deheader(tg, headered, true);
			//buf_free(headered);

			//tg_parse_answer(tg, tl, msgid,
				//&answer, tg_parse_answer_callback);
		//}

		//tl_free(tl);
		//tl = answer;
	//}
		
	if (tl == NULL){
		return NULL;
	}

	// check gzip
	if (tl->_id == id_gzip_packed){
		ON_LOG(tg, "%s: got GZIP", __func__);
		tl = tg_tl_from_gzip(tg, tl);
	}

	// check ack
	if (tl->_id == id_msgs_ack){
		ON_LOG(tg, "ACK: read answer again");
		// free tl
		tl_free(tl);
		tl = NULL;
		// load data again
		buf = tg_http_recieve(tg, curl);
		headered = tg_decrypt(tg, buf, true); 
		buf_free(buf);

		buf_t payload = tg_deheader(tg, headered, true);
		buf_free(headered);

		tg_parse_answer(tg, tl, msgid,
				&answer, tg_parse_answer_callback);

		if (answer){
			tl_free(tl);
			tl = answer;
		} 
	}


	// check server salt
	if (tl->_id == id_bad_server_salt){
		ON_LOG(tg, "BAD SERVER SALT: resend query");
		// free tl
		tl_free(tl);
		// resend query
		return tg_http_send_query_with_progress(
				tg, dc, port, maximum_limit, query, 
				progressp, progress);
	}

	// handle errors
	if (tl->_id == id_rpc_error){
		ON_LOG(tg, "%s: got rpc error", __func__);
		tl_rpc_error_t *error =
			(tl_rpc_error_t *)tl;

		// check file migrate
		const dc_t *migrate = 
			tg_error_file_migrate(tg, RPC_ERROR(tl)); 
		if (migrate){
			// resend requests with new dc
			return tg_http_send_query_with_progress(
					tg, migrate->number, port, maximum_limit, query, 
					progressp, progress);
		}

		// check flood wait
		int wait = tg_error_flood_wait(tg, RPC_ERROR(tl));
		if (wait){
			// wait and resend query
			sleep(wait);
			return tg_http_send_query_with_progress(
					tg, dc, port, maximum_limit, query, 
					progressp, progress);
		}
	}

	/* always cleanup */
	curl_easy_cleanup(curl);
	/*curl_slist_free_all(header);*/

	return tl;
}	

tl_t * tg_http_send_query(
		tg_t *tg, buf_t *query)
{
	return tg_http_send_query_with_progress(
			tg, DEFAULT_DC, SERVER_PORT, 
			false, 
			query, NULL, NULL);
}
