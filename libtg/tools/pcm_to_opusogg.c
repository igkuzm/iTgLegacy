#include <assert.h>
#include <stdio.h>
#include <opusenc.h>

int pcm_to_opusogg(
		FILE *pcm, 
		const char *ogg_file_path,
		const char *artist,
		const char *title,
		float sample_rate,
		int channels,
		int frame_size)
{
	assert(pcm && ogg_file_path);

	OggOpusComments *comments = ope_comments_create();
	if (artist)
		ope_comments_add(comments, "ARTIST", artist);

	if (title)
		ope_comments_add(comments, "TITLE", title);

	int error;
	OggOpusEnc *enc = ope_encoder_create_file(
			ogg_file_path, 
			comments, 
			sample_rate, 
			channels, 
			0, 
			&error);
  if (!enc) {
    ope_comments_destroy(comments);
		return error;
  }
  while (1) {
    short buf[channels*frame_size];
    int ret = fread(
				buf, 
				channels*sizeof(short), 
				frame_size, 
				pcm);
    if (ret > 0) {
      ope_encoder_write(enc, buf, ret);
    } else break;
  }
  ope_encoder_drain(enc);
  ope_encoder_destroy(enc);
  ope_comments_destroy(comments);

	return 0;
}	
