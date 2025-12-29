#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct notes_whisper_context notes_whisper_context;

notes_whisper_context * notes_whisper_init(const char * model_path);
void notes_whisper_free(notes_whisper_context * ctx);

// Runs transcription for the provided 16kHz mono float samples.
// Returns 0 on success, non-zero on error.
int notes_whisper_transcribe(
    notes_whisper_context * ctx,
    const float * samples,
    int n_samples,
    const char * language,
    int n_threads
);

int notes_whisper_n_segments(notes_whisper_context * ctx);
const char * notes_whisper_segment_text(notes_whisper_context * ctx, int index);
int notes_whisper_segment_t0(notes_whisper_context * ctx, int index); // 10ms units
int notes_whisper_segment_t1(notes_whisper_context * ctx, int index); // 10ms units

#ifdef __cplusplus
}
#endif

