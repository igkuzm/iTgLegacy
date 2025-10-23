#ifndef TG_FILES_H
#define TG_FILES_H

#include "tg.h"
#include "peer.h"
#include <openssl/md5.h>
#include <stdio.h>
#include <stdbool.h>

#define TG_FILE_ARGS\
	TG_FILE_TYP(uint32_t, type_,  "INT",  "type") \
	TG_FILE_ARG(uint32_t, mtime_, "INT",  "mtime") \
	TG_FILE_BUF(buf_t,    bytes_, "TEXT", "bytes") \


typedef enum {
	TG_STORAGE_FILETYPE_NULL     = 0,
	TG_STORAGE_FILETYPE_UNKNOWN  = id_storage_fileUnknown, //Unknown type.
	TG_STORAGE_FILETYPE_PARTIRAL = id_storage_filePartial, // Part of a bigger file.
	TG_STORAGE_FILETYPE_JPEG     = id_storage_fileJpeg,    // JPEG image. MIME type: image/jpeg.
	TG_STORAGE_FILETYPE_GIF      = id_storage_fileGif,     // GIF image. MIME type: image/gif.
	TG_STORAGE_FILETYPE_PNG      = id_storage_filePng,     // PNG image. MIME type: image/png.
	TG_STORAGE_FILETYPE_PDF      = id_storage_filePdf,     // PDF document image. MIME type: application/pdf.
	TG_STORAGE_FILETYPE_MP3      = id_storage_fileMp3,     //Mp3 audio. MIME type: audio/mpeg.
	TG_STORAGE_FILETYPE_MOV      = id_storage_fileMov,     // Quicktime video. MIME type: video/quicktime.
	TG_STORAGE_FILETYPE_MP4      = id_storage_fileMp4,     // MPEG-4 video. MIME type: video/mp4.
	TG_STORAGE_FILETYPE_WEBP     = id_storage_fileWebp,    // WEBP image. MIME type: image/webp.
} TG_STORAGE_FILETYPE;

typedef struct tg_file_ {
	#define TG_FILE_TYP(t, arg, ...) t arg;
	#define TG_FILE_ARG(t, arg, ...) t arg;
	#define TG_FILE_BUF(t, arg, ...) t arg; 
	TG_FILE_ARGS
	#undef TG_FILE_TYP
	#undef TG_FILE_ARG
	#undef TG_FILE_BUF
} tg_file_t;

void tg_file_free(tg_file_t*);

int tg_get_file(
		tg_t *tg, 
		InputFileLocation *location,
		int total,
		void *userdata,
		int (*callback)(
			void *userdata, const tg_file_t *file));	

char * tg_get_photo_file(tg_t *tg, 
		uint64_t photo_id, uint64_t photo_access_hash, 
		const char *photo_file_reference,
		const char *photo_size);

char * tg_get_peer_photo_file(tg_t *tg, 
		tg_peer_t *peer, 
		bool big_photo,
		uint64_t photo_id); 

int tg_get_document(tg_t *tg, 
		uint64_t id, 
		uint64_t size, 
		uint64_t access_hash, 
		const char * file_reference, 
		void *userdata,
		int (*callback)(
			void *userdata, const tg_file_t *file),	
		void *progressp,
			int (*progress)(void *progressp, int size, int total));

char * tg_get_document_thumb(tg_t *tg, 
		uint64_t id, 
		uint64_t access_hash, 
		const char * file_reference, 
		const char * thumb_size);

typedef enum {
	DOCUMENT_TYPE_DEFAUL,
	DOCUMENT_TYPE_PHOTO,
	DOCUMENT_TYPE_IMAGE,
	DOCUMENT_TYPE_VIDEO,
	DOCUMENT_TYPE_AUDIO,

} DOCUMENT_TYPE;

typedef struct {
	DOCUMENT_TYPE type;
	char filepath[BUFSIZ];
	char mime_type[256];
	bool force_file;
	bool spoiler;
	bool no_sound_video; // (a GIF animation (even as MPEG4),for example)
	uint32_t  *ttl_seconds;
	// image attributes 
	uint32_t image_w;
	uint32_t image_h;
	// stickers attributes 
	char sticker_alt[7];
	int sticker_set_type; // todo: sticker set types
	uint64_t sricker_set_id;
	uint64_t sricker_set_access_hash;
	char sricker_set_short_name[32];
	char sricker_set_emoticon[32];
	// video attributes 
	bool video_supports_streaming;
	bool video_no_sound;
	double video_duration;
	uint32_t video_w;
	uint32_t video_h;
	uint32_t *video_preload_prefix_size;
	double *video_start_ts;
	// audio attributes 
	bool audio_voice;
	double audio_duration;
	char audio_title[256];
	char audio_perfomer[256];
	buf_t *audio_waveform;
	// filename attributes 
	char filename[256];
	// has_stickers attributes 
	bool has_stickers;
	// stickers
	buf_t *stickers;
	int stickers_len;
} tg_document_t;

tg_document_t *tg_document(tg_t *tg, const char *filepath,
		const char *filename, const char *mime_type);
tg_document_t *tg_photo(tg_t *tg, const char *filepath);
tg_document_t *tg_voice_message(tg_t *tg, const char *filepath);

int tg_document_send(
		tg_t *tg, tg_peer_t *peer, 
		tg_document_t *document,
		const char *message,
		void *progressp, int (*progress)(void *, int, int));

int tg_contact_send(
		tg_t *tg, tg_peer_t *peer, 
		const char *phone_number,
		const char *first_name,
		const char *last_name,
		const char *vcard,
		const char *message);

int tg_send_geopoint(tg_t *tg, tg_peer_t *peer, 
		double lat, double lon, const char *message);

const unsigned char *tg_file_hash(tg_t *, const char *filepath);

#endif /* ifndef TG_FILES_H */
