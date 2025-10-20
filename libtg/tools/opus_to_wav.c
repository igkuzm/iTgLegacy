#include "opus_to_wav.h"
#include <opus/opusfile.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

struct mem {
	unsigned char *data;
	int len;
};

static int mem_init(struct mem *mem){
	mem->len = 0;
	mem->data = malloc(1);
	if (mem->data == NULL)
		return 1;
	return 0;
}

static int mem_add(struct mem *mem, int len, unsigned char *data)
{
	int i, new_len = mem->len + len + 1;
	void *ptr = realloc(mem->data, new_len);
	if (ptr == NULL){
		return 1;
	}
	mem->data = ptr;
	for (i = 0; i < len; ++i) {
		mem->data[mem->len++] = data[i];
	}
	return 0;
}

int opus_to_wav(const char *ogg, const char *wav)
{
	OggOpusFile *of;
	int error = OPUS_OK;		

	// check opus file
	of = op_test_file(ogg, &error);	
	if (of == NULL){
		return error;
	}
	
	// test open
	error = op_test_open(of);
	op_free(of);
	if (error != OPUS_OK){
		return error;
	}

	// open wav file
	FILE *wf = fopen(wav, "w");
	if (wf == NULL){
		return -1;
	}
			
	// open opus ogg
	of = op_open_file(ogg, &error);	
	assert(of);

	// read pcm raw data
	struct mem buf;
	if (mem_init(&buf))
		return -1;

	int c = op_channel_count(of, -1);
	opus_int16 pcm[(160*48*c)/2];
	int size = sizeof(pcm)/sizeof(*pcm);
	while (op_read_stereo(of, pcm, size) > 0) 
	{
		if (mem_add(&buf, size, (unsigned char *)pcm))
			return -1;
	}

	// add wav header
	int readcount=0;
	short NumChannels = 2;
	short BitsPerSample = 16;
	int SamplingRate = 48000;
	short numOfSamples = 160;

	int ByteRate = NumChannels*BitsPerSample*SamplingRate/8;
	short BlockAlign = NumChannels*BitsPerSample/8;
	//int DataSize = NumChannels*numOfSamples *  BitsPerSample/8;
	int DataSize = buf.len;
	int chunkSize = 16;
	int totalSize = 36 + DataSize;
	short audioFormat = 1;

	//totOutSample = 0;
	fwrite("RIFF", sizeof(char), 4,wf);
	fwrite(&totalSize, sizeof(int), 1, wf);
	fwrite("WAVE", sizeof(char), 4, wf);
	fwrite("fmt ", sizeof(char), 4, wf);
	fwrite(&chunkSize, sizeof(int),1,wf);
	fwrite(&audioFormat, sizeof(short), 1, wf);
	fwrite(&NumChannels, sizeof(short),1,wf);
	fwrite(&SamplingRate, sizeof(int), 1, wf);
	fwrite(&ByteRate, sizeof(int), 1, wf);
	fwrite(&BlockAlign, sizeof(short), 1, wf);
	fwrite(&BitsPerSample, sizeof(short), 1, wf);
	fwrite("data", sizeof(char), 4, wf);
	fwrite(&DataSize, sizeof(int), 1, wf);

	// add data
	fwrite(buf.data, buf.len, 1, wf);	
	
	// close and clear
	fclose(wf);
	free(buf.data);
	return 0;
}
