#include "files.h"
#include <assert.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <openssl/md5.h>
#include "transport.h"
#include "net.h"
#include "../tl/alloc.h"
#include "peer.h"
#include "tg.h"
#include "updates.h"

#define BUF2STR(_b) strndup((char*)_b.data, _b.size)

static void tg_file_from_tl(tg_file_t *f, const tl_t *tl)
{
	fprintf(stderr, "%s\n", __func__);
	if (!tl || tl->_id != id_upload_file)
		return;

	tl_upload_file_t *uf = (tl_upload_file_t *)tl;
	
	#define TG_FILE_TYP(t, arg, ...) f->arg = uf->arg->_id;
	#define TG_FILE_ARG(t, arg, ...) f->arg = uf->arg;
	#define TG_FILE_BUF(t, arg, ...) f->arg = buf_add_buf(uf->arg);
	TG_FILE_ARGS
	#undef TG_FILE_TYP
	#undef TG_FILE_ARG
	#undef TG_FILE_BUF
}

int tg_get_file_with_progress(
		tg_t *tg, 
		InputFileLocation *location,
		int size,
		const char *ip,
		int port,
		void *userdata,
		int (*callback)(
			void *userdata, const tg_file_t *file),
		void *progressp,
			int (*progress)(void *progressp, int size, int total))
{
	ON_LOG(tg, "%s", __func__);
	/* If precise flag is not specified, then

		• The parameter offset must be divisible by 4 KB.
		• The parameter limit must be divisible by 4 KB.
		• 1048576 (1 MB) must be divisible by limit.

		 If precise is specified, then

		• The parameter offset must be divisible by 1 KB.
		• The parameter limit must be divisible by 1 KB.
		• limit must not exceed 1048576 (1 MB).
	 */

	/* In any case the requested part should be within 
	 * one 1 MB chunk from the beginning of the file, i. e.
   • offset / (1024 * 1024) == (offset + limit - 1) / (1024 * 1024).
	 */

	/*int i, limit = 1024*4, offset = 0; // for testing */
	int i, limit = 1048576, offset = 0;

	char ip_address[128];
	strcpy(ip_address, tg->ip);
		
	while (size>0?offset<size:1) 
	{
		printf("%s: download total: %d with offset: %d (%d%%)\n",
				__func__, size, offset, offset/size);
		// download parts of file
		buf_t getFile = tl_upload_getFile(
				NULL, 
				NULL, 
				location, 
				offset, 
				limit);
			
		// net send
		tl_t *tl = tg_send_query_sync_with_progress(
				tg, &getFile,
				progressp, progress);
		buf_free(getFile);

		if (tl == NULL)
			return 1;

		//if (tl->_id == id_rpc_error){
			//ON_LOG(tg, "%s: check FILE_MIGRATE", __func__);
			//// check FILE MIGRATE
			//tl_rpc_error_t *error =
				//(tl_rpc_error_t *)tl;

			//char *str;
			//str = strstr(
				//(char *)error->error_message_.data, 
				//"FILE_MIGRATE_");
			//if (str){
				//str += strlen("FILE_MIGRATE_");
				//int dc = atoi(str);
				//tl_free(tl);
				//const char *ip = tg_ip_address_for_dc(tg, dc); 
				//if (ip == NULL){
					//return 0;
				//}
				//strcpy(ip_address, ip);
				//// resend query
				//offset = 0;
				//continue;
			//}
			//return offset;
		//}

		if (tl->_id != id_upload_file){
			tl_free(tl);
			return 1;
		}
		
		tg_file_t file;
		memset(&file, 0, sizeof(tg_file_t));
		tg_file_from_tl(&file, tl);
		tl_free(tl);

		// add offset
		offset += file.bytes_.size;

		printf("FILE TYPE: %s\n", TL_NAME_FROM_ID(file.type_));
		if (callback)
			if (callback(userdata, &file))
				break;

		tg_file_free(&file);
	}
	
	return 0;
}

int tg_get_file(
		tg_t *tg, 
		InputFileLocation *location,
		int size,
		void *userdata,
		int (*callback)(
			void *userdata, const tg_file_t *file))
{
	ON_LOG(tg, "%s", __func__);
	return tg_get_file_with_progress(
			tg, 
			location, 
			size, 
			tg->ip,
			tg->port,
			userdata, 
			callback, 
			NULL, 
			NULL);
}

static int _photo_file_cb(void *userdata, const tg_file_t *file)
{
	char **photo = userdata;
	*photo = buf_to_base64(file->bytes_); 
	return 1;
}

char * tg_get_photo_file(tg_t *tg, 
		uint64_t photo_id, uint64_t photo_access_hash, 
		const char *photo_file_reference,
		const char *photo_size)
{
	ON_LOG(tg, "%s", __func__);
	char *photo = NULL;
	
	buf_t fr = buf_from_base64(photo_file_reference);
	InputFileLocation location = 
					tl_inputPhotoFileLocation(
							photo_id, 
							photo_access_hash, 
							&fr, 
							photo_size);
	buf_free(fr);

	tg_get_file(
			tg, 
			&location, 
			0,
			&photo, 
			_photo_file_cb);
	buf_free(location);
	
	return photo;
}

char * tg_get_peer_photo_file(tg_t *tg, 
		tg_peer_t *peer, 
		bool big_photo,
		uint64_t photo_id) 
{
	ON_LOG(tg, "%s", __func__);
	char *photo = NULL;
	
	buf_t peer_ = tg_inputPeer(*peer);
	InputFileLocation location = 
		tl_inputPeerPhotoFileLocation(
				true, 
				&peer_, 
				photo_id);
	buf_free(peer_);

	tg_get_file(
			tg, 
			&location, 
			0,
			&photo, 
			_photo_file_cb);
	buf_free(location);
	
	return photo;
}

int tg_get_document(tg_t *tg, 
		uint64_t id, 
		uint64_t size, 
		uint64_t access_hash, 
		const char * file_reference, 
		void *userdata,
		int (*callback)(
			void *userdata, const tg_file_t *file),	
		void *progressp,
			int (*progress)(void *progressp, int size, int total))
{
	ON_LOG(tg, "%s", __func__);
	buf_t fr = buf_from_base64(file_reference);
	InputFileLocation location =
		tl_inputDocumentFileLocation(
				id, 
				access_hash, 
				&fr, 
				"");
	buf_free(fr);

	int ret = tg_get_file_with_progress(
			tg, 
			&location, 
			size,
			tg->ip,
			tg->port,
			userdata, 
			callback,
			progressp,
			progress);

	buf_free(location);
	return ret;
}	

char * tg_get_document_thumb(tg_t *tg, 
		uint64_t id, 
		uint64_t access_hash, 
		const char * file_reference, 
		const char * thumb_size)
{	
	ON_LOG(tg, "%s", __func__);
	char *photo = NULL;
	
	buf_t fr = buf_from_base64(file_reference);
	InputFileLocation location =
		tl_inputDocumentFileLocation(
				id, 
				access_hash, 
				&fr, 
				thumb_size);
	buf_free(fr);

	tg_get_file(
			tg, 
			&location, 
			0,
			&photo, 
			_photo_file_cb);

	buf_free(location);

	return photo;
}

void tg_file_free(tg_file_t *f){
	#define TG_FILE_TYP(...)
	#define TG_FILE_ARG(...)
	#define TG_FILE_BUF(t, n, ...) buf_free(f->n); 
	TG_FILE_ARGS
	#undef TG_FILE_TYP
	#undef TG_FILE_ARG
	#undef TG_FILE_BUF
}

int tg_document_send(
		tg_t *tg, tg_peer_t *peer, 
		tg_document_t *document,
		const char *message,
		void *progressp, int (*progress)(void *, int, int))
{
	ON_LOG(tg, "%s", __func__);
	assert(document && peer && document->filepath[0]);
	int i;
	ON_LOG(tg, "%s...", __func__);
	FILE *fp = fopen(document->filepath, "r");
	if (fp == NULL){
		ON_ERR(tg, "%s: can't open file: %s", __func__, 
				document->filepath);
		return 1;
	}
	fseek(fp, 0, SEEK_END);
	int size = ftell(fp);
	fseek(fp, 0, SEEK_SET);

	// Before transmitting the contents of the file itself, 
	// the file has to be assigned a unique 64-bit 
	// client identifier: file_id.
	buf_t file_id_ = buf_rand(8);
	uint64_t file_id = buf_get_ui64(file_id_);
	buf_free(file_id_);

	// The file's binary content is then split into parts. 
	// All parts must have the same size (part_size) and 
	// the following conditions must be met:
	// • part_size % 1024 = 0 (divisible by 1KB)
  // • 524288 % part_size = 0 (512KB must be evenly divisible 
	// by part_size)
	//
	// The last part does not have to satisfy these conditions, 
	// provided its size is less than part_size.
	// The following appConfig fields specify the 
	// maximum number of uploadable file parts:
	// • upload_max_fileparts_default » - Maximum number of 
	//	 file parts uploadable by non-Premium users.
	// • upload_max_fileparts_premium » - Maximum number of 
	//   file parts uploadable by Premium users.
	//
	// Note that the limit of uploadable file parts does 
	// not account for the part_size: thus the total file 
	// size limit can only be reached with the biggest possible
	//
	// part_size of 512KB, which is actually the 
	// recommended part_size to avoid excessive protocol overhead.
	int part_size =  524288;
	
	// Each part should have a sequence number, file_part, 
	// with a value ranging from 0 to the value of the 
	// appropriate config parameter minus 1.
	uint32_t file_part = 0;

	// After the file has been partitioned you need to 
	// choose a method for saving it on the server. 
	// Use upload.saveBigFilePart in case the full size of 
	// the file is more than 10 MB and upload.saveFilePart 
	// for smaller files.
	buf_t buf = buf_new();
	ON_LOG(tg, "%s: prepare file: %s with size: %d", 
			__func__, document->filepath, size);
	
	if (size > 10485760){ // for files > 10Mb
		// need filename for big files
		if (document->filename[0] == 0) {
			ON_ERR(tg, "%s: need filename for files > 10Mb", __func__);
			return 1;
		}
		// save big file part
		int file_total_parts = size / part_size + (size % part_size == 0 ? 0 : 1);
		//
		buf_t bytes = buf_new();
		buf_realloc(&bytes, part_size);
		
		int len, current = 0, retry = 0;
		for (len = fread(bytes.data, 1, part_size, fp);
				 len > 0;
				 len = fread(bytes.data, 1, part_size, fp))
		{
			bytes.size = len;
			buf = buf_cat(buf, bytes);
			
tg_document_send_with_progress_saveBigFilePart:;
			ON_LOG(tg, "%s: upload %d part of file: %s", __func__, 
					file_part, document->filepath);
			if (retry > 9)
			{
				ON_ERR(tg, "%s: can't upload file: %s (retries > 10)", __func__,
					 	document->filepath);
			}

			buf_t saveFilePart = tl_upload_saveBigFilePart(
					file_id, 
					file_part,
					file_total_parts,	
					&bytes);
			buf_free(saveFilePart);

			tl_t *tl = tg_send_query_sync(
					tg, 
					&saveFilePart); 
			
			if (!tl || tl->_id != id_boolTrue){
				ON_ERR(tg, "%s: expected tl_true but got: %s", 
					__func__, tl?TL_NAME_FROM_ID(tl->_id):"NULL");
				if (tl)
					tl_free(tl);
				// retry
				retry++;
				goto tg_document_send_with_progress_saveBigFilePart;
			}
				
			if (tl)
				tl_free(tl);

			if (progress){
				if (progress(progressp, len, size)){
					buf_free(bytes);
					ON_LOG(tg, "%s: upload canceled", __func__);
					return 1;
				}
			}

			file_part++;
		}	
		buf_free(bytes);

	} else {  // for files < 10Mb
		// save file part
		buf_t bytes = buf_new();
		buf_realloc(&bytes, part_size);
		
		int len, current = 0, retry = 0;
		for (len = fread(bytes.data, 1, part_size, fp);
				 len > 0;
				 len = fread(bytes.data, 1, part_size, fp))
		{
			bytes.size = len;
			buf = buf_cat(buf, bytes);
			
tg_document_send_with_progress_saveFilePart:;
			ON_LOG(tg, "%s: upload %d part of file: %s", __func__, 
					file_part, document->filepath);
			if (retry > 9)
			{
				ON_ERR(tg, "%s: can't upload file: %s (retries > 10)", __func__,
					 	document->filepath);
			}

			buf_t saveFilePart = tl_upload_saveFilePart(
					file_id, 
					file_part, 
					&bytes);

			tl_t *tl = tg_send_query_sync(
					tg, 
					&saveFilePart); 
			buf_free(saveFilePart);
			
			if (!tl || tl->_id != id_boolTrue){
				ON_ERR(tg, "%s: expected tl_true but got: %s", 
					__func__, tl?TL_NAME_FROM_ID(tl->_id):"NULL");
				if (tl)
					tl_free(tl);
				// retry
				retry++;
				goto tg_document_send_with_progress_saveFilePart;
			}

			if (tl)
				tl_free(tl);
			
			if (progress)
				progress(progressp, len, size);

			file_part++;
		}	
		buf_free(bytes);
	}

	// While the parts are being uploaded, an MD5 hash of 
	// the file contents can also be computed to be used 
	// later as the md5_checksum parameter in the inputFile 
	// constructor (since it is checked only by the server, 
	// for encrypted secret chat files it must be generated 
	// from the encrypted file). 
	unsigned char md5[MD5_DIGEST_LENGTH];
	assert(MD5(buf.data, buf.size, md5));
	char md5_checksum[BUFSIZ] = {0};
	for (i = 0; i < MD5_DIGEST_LENGTH; ++i) {
		sprintf(md5_checksum, "%s%02x", md5_checksum, md5[i]); 
	}
	ON_LOG(tg, "%s: file MD5 hash: %s", __func__, md5_checksum);

	// After the entire file is successfully saved, the final
	// method may be called and passed the generated 
	// inputFile object. In case the upload.saveBigFilePart 
	// method is used, the inputFileBig constructor must 
	// be passed, in other cases use inputFile.
	buf_t inputFile;
	if (size > 10485760){
		inputFile = tl_inputFileBig(
				file_id, 
				file_part, 
				document->filename);
	
	} else {
		inputFile = tl_inputFile(
				file_id, 
				file_part, 
				document->filename, 
				md5_checksum);
	}

	InputMedia media;
	if (document->type == DOCUMENT_TYPE_PHOTO) {
		media = tl_inputMediaUploadedPhoto(
				document->spoiler, 
				&inputFile, 
				document->stickers, 
				document->stickers_len, 
				document->ttl_seconds);

	} else { // not a photo
		// set attributes
		DocumentAttribute attrs[8];
		memset(attrs, 0, sizeof(DocumentAttribute)*8);
		int attrs_len = 0;
		if (document->filename[0]){
			attrs[attrs_len++] = tl_documentAttributeFilename(
					document->filename);
		}
		if (document->has_stickers){
			attrs[attrs_len++] = tl_documentAttributeHasStickers();
		}
		switch (document->type) {
			case DOCUMENT_TYPE_IMAGE:
				attrs[attrs_len++] = tl_documentAttributeImageSize(
						document->image_w, document->image_h);
				break;
			case DOCUMENT_TYPE_VIDEO:
				attrs[attrs_len++] = tl_documentAttributeVideo(
						false, 
						document->video_supports_streaming, 
						document->video_no_sound, 
						document->video_duration, 
						document->video_w, 
						document->video_h, 
						document->video_preload_prefix_size, 
						document->video_start_ts);
				break;
			case DOCUMENT_TYPE_AUDIO:
				attrs[attrs_len++] = tl_documentAttributeAudio(
						document->audio_voice, 
						document->audio_duration, 
						document->audio_title, 
						document->audio_perfomer, 
						document->audio_waveform);
				break;
			
			default:
				break;
		}
	
		media = tl_inputMediaUploadedDocument(
				document->no_sound_video, 
				document->force_file, 
				document->spoiler, 
				&inputFile, 
				NULL, 
				document->mime_type, 
				attrs, 
				attrs_len, 
				document->stickers, 
				document->stickers_len, 
				document->ttl_seconds);
		// free attrs
		for (i = 0; i < attrs_len; ++i) {
			buf_free(attrs[i]);
		}
	} // end if photo
	
	buf_free(inputFile);

	buf_t peer_ = tg_inputPeer(*peer);
	buf_t random_id = buf_rand(8);

	buf_t sendMedia = tl_messages_sendMedia(
			false, 
			false, 
			false, 
			false, 
			false, 
			false, 
			&peer_, 
			NULL, 
			&media, 
			message?message:"", 
			buf_get_ui64(random_id), 
			NULL, 
			NULL, 
			0, 
			NULL, 
			NULL, 
			NULL, 
			NULL);
	buf_free(media);
	buf_free(peer_);
	buf_free(random_id);

	tl_t *tl = tg_send_query_sync(tg, &sendMedia);
	buf_free(sendMedia);

	if (tl == NULL)
	{
		ON_ERR(tg, "%s: answer is NULL", __func__);
		return 1;
	}
	//if (tl->_id != id_updatesTooLong &&
			//tl->_id != id_updateShortMessage &&
			//tl->_id != id_updateShortChatMessage &&
			//tl->_id != id_updateShort &&
			//tl->_id != id_updatesCombined &&
			//tl->_id != id_updates &&
			//tl->_id != id_updateShortSentMessage)
	//{
		//ON_ERR(tg, "%s: expected Updates but got: %s", 
				//__func__, TL_NAME_FROM_ID(tl->_id));
		//tl_free(tl);
		//return 1;
	//}

	// do updates
	tg_do_updates(tg, tl);
	tl_free(tl);

	return 0;
}	

tg_document_t *tg_document(tg_t *tg, const char *filepath,
		const char *filename, const char *mime_type)
{
	assert(filepath);
	tg_document_t *d = NEW(tg_document_t, 
			ON_ERR(tg, "%s: can't allocate memory", __func__);
			return NULL;);
	strncpy(d->filepath, filepath,
			 sizeof(d->filepath) - 1);
	strncpy(d->mime_type, mime_type,
			 sizeof(d->mime_type) - 1);
	strncpy(d->filename, filename,
			 sizeof(d->filename) - 1);
	d->type = DOCUMENT_TYPE_DEFAUL;
	return d;
}

tg_document_t *tg_photo(tg_t *tg, const char *filepath)
{
	assert(filepath);
	tg_document_t *d = NEW(tg_document_t, 
			ON_ERR(tg, "%s: can't allocate memory", __func__);
			return NULL;);
	strncpy(d->filepath, filepath,
			 sizeof(d->filepath) - 1);
	d->type = DOCUMENT_TYPE_PHOTO;
	return d;
}

tg_document_t *tg_voice_message(tg_t *tg, const char *filepath)
{
	assert(filepath);
	tg_document_t *d = NEW(tg_document_t, 
			ON_ERR(tg, "%s: can't allocate memory", __func__);
			return NULL;);
	strcpy(d->mime_type, "audio/ogg");
	strncpy(d->filepath, filepath,
			 sizeof(d->filepath) - 1);
	d->type = DOCUMENT_TYPE_AUDIO;
	d->audio_voice = true;
	return d;
}

int tg_contact_send(
		tg_t *tg, tg_peer_t *peer, 
		const char *phone_number,
		const char *first_name,
		const char *last_name,
		const char *vcard,
		const char *message)
{
	InputMedia inputMedia = tl_inputMediaContact(
			phone_number, 
			first_name, 
			last_name, 
			vcard);
	InputPeer inputPeer = tg_inputPeer(*peer);
	buf_t random_id = buf_rand(8);

	buf_t sendMedia = tl_messages_sendMedia(
				false, 
				false, 
				false, 
				false, 
				false, 
				false, 
				&inputPeer, 
				NULL, 
				&inputMedia, 
				message?message:"", 
				buf_get_ui64(random_id), 
				NULL, 
				NULL, 
				0, 
				NULL, 
				NULL, 
				NULL, 
				NULL);

	buf_free(inputMedia);
	buf_free(inputPeer);
	buf_free(random_id);

	tl_t *tl = tg_send_query_sync(tg, &sendMedia);
	buf_free(sendMedia);

	if (tl == NULL)
		return 1;

	if (tl->_id == id_rpc_error){
		tl_free(tl);
		return 1;
	}

	tl_free(tl);
	return 0;
}

int tg_send_geopoint(tg_t *tg, tg_peer_t *peer, 
		double lat, double lon, const char *message)
{
	InputGeoPoint inputGeoPoint = tl_inputGeoPoint(
			lat, 
			lon, 
			NULL);
	InputMedia inputMedia = 
		tl_inputMediaGeoPoint(&inputGeoPoint);
	buf_free(inputGeoPoint);

	InputPeer inputPeer = tg_inputPeer(*peer);
	buf_t random_id = buf_rand(8);

	buf_t sendMedia = tl_messages_sendMedia(
				false, 
				false, 
				false, 
				false, 
				false, 
				false, 
				&inputPeer, 
				NULL, 
				&inputMedia, 
				message?message:"", 
				buf_get_ui64(random_id), 
				NULL, 
				NULL, 
				0, 
				NULL, 
				NULL, 
				NULL, 
				NULL);

	buf_free(inputMedia);
	buf_free(inputPeer);
	buf_free(random_id);

	tl_t *tl = tg_send_query_sync(tg, &sendMedia);
	buf_free(sendMedia);

	if (tl == NULL)
		return 1;

	if (tl->_id == id_rpc_error){
		tl_free(tl);
		return 1;
	}

	tl_free(tl);
	return 0;
}

int tg_get_document_hashes(tg_t *tg, 
		uint64_t id, 
		uint64_t access_hash, 
		const char * file_reference, 
		void *data,
		int (*callback)(
			void *data, uint64_t offset, uint32_t limit, const char *hash))	
{
	ON_LOG(tg, "%s", __func__);
	buf_t fr = buf_from_base64(file_reference);
	InputFileLocation location =
		tl_inputDocumentFileLocation(
				id, 
				access_hash, 
				&fr, 
				"");
	buf_free(fr);
	
	// get file hashes
	buf_t getFileHashes = 
		tl_upload_getFileHashes(&location, 0);
	buf_free(location);
	
	tl_t *tl = tg_send_query_sync(tg, &getFileHashes); 
	buf_free(getFileHashes);
	
	if (tl == NULL)
		return 0;

	int i, n = 0, loop = 1;
	if (tl->_id == id_vector){
		tl_vector_t *vector = (tl_vector_t *)id;
		for (i = 0; i < vector->len_ && loop; ++i) {
			tl_t *tl = tl_deserialize(&vector->data_);
			if (tl == NULL)
				break;
			if (tl->_id == id_fileHash){
				tl_fileHash_t *fileHash = 
					(tl_fileHash_t *)tl;
				if (callback){
					char *hash = BUF2STR(fileHash->hash_);
					if (callback(data, fileHash->offset_, fileHash->limit_, hash))
						loop = 0;
					n++; // add counter
					if (hash)
						free(hash);
				}
			}
		}
	}

	tl_free(tl);
	return n;
}	
