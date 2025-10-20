#ifndef PCM_TO_OPUSOGG_H
#define PCM_TO_OPUSOGG_H
#include <stdio.h>
int pcm_to_opusogg(
		FILE *pcm, 
		const char *ogg_file_path,
		const char *artist,
		const char *title,
		float sample_rate,
		int channels,
		int frame_size);
#endif /* ifndef PCM_TO_OPUSOGG_H */
