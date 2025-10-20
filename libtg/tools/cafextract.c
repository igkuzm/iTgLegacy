#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>
#include "byteswap.h"
#include "cafextract.h"

static bool is_little_endian()
{
	int x = 1;
	return *(char*)&x;
}

struct CAFFileHeader {
  uint32_t  mFileType;
	uint16_t  mFileVersion;
  uint16_t  mFileFlags;
};

struct CAFChunkHeader {
	uint32_t  mChunkType;
	int64_t   mChunkSize;
};

FILE * caf_extract(
		const char *caf, 
		struct CAFEAudioFormat *format)
{
	assert(caf);
	
	// open file
	FILE *in = fopen(caf, "r");
	if (!in){
		return NULL;
	}
	
	// read file header
	struct CAFFileHeader fileHeader;
	fread(&fileHeader, sizeof(fileHeader), 1, in);
	if (is_little_endian()){
		fileHeader.mFileVersion = bswap_16(fileHeader.mFileVersion);
		fileHeader.mFileFlags   = bswap_16(fileHeader.mFileFlags);
	}

	// read audio description chunk header - should be first
	// chunk
	struct CAFChunkHeader aChunkHeader;
	fread(&aChunkHeader, sizeof(aChunkHeader), 1, in);
	if (is_little_endian()){
		aChunkHeader.mChunkType = bswap_32(aChunkHeader.mChunkType);
		aChunkHeader.mChunkSize = bswap_64(aChunkHeader.mChunkSize);
	}
	if (aChunkHeader.mChunkType != 'desc'){
		return NULL;
	}

	// read audio description format
	struct CAFEAudioFormat aFormat;
	fread(&aChunkHeader, sizeof(aChunkHeader), 1, in);
	if (is_little_endian()){
		aFormat.mSampleRate       = bswap_64(aFormat.mSampleRate);
		aFormat.mFormatID         = bswap_32(aFormat.mFormatID);
		aFormat.mFormatFlags      = bswap_32(aFormat.mFormatFlags);
		aFormat.mBytesPerPacket   = bswap_32(aFormat.mBytesPerPacket);
		aFormat.mFramesPerPacket  = bswap_32(aFormat.mFramesPerPacket);
		aFormat.mChannelsPerFrame = bswap_32(aFormat.mChannelsPerFrame);
		aFormat.mBitsPerChannel   = bswap_32(aFormat.mBitsPerChannel);
	}
	if (format)
		*format = aFormat;

	// read audio data chunk header
	struct CAFChunkHeader dChunkHeader;
	fread(&dChunkHeader, sizeof(dChunkHeader), 1, in);
	if (is_little_endian()){
		dChunkHeader.mChunkType = bswap_32(dChunkHeader.mChunkType);
		dChunkHeader.mChunkSize = bswap_64(dChunkHeader.mChunkSize);
	}

	// read edit count
	uint32_t mEditCount;
	fread(&mEditCount, sizeof(mEditCount), 1, in);
	if (is_little_endian())
		mEditCount = bswap_32(mEditCount);

	return in;
}	
