#include "whisper_bridge.h"

#include <string>

#include "whisper.h"

struct notes_whisper_context {
    whisper_context * ctx = nullptr;
};

notes_whisper_context * notes_whisper_init(const char * model_path) {
    if (model_path == nullptr) { return nullptr; }
    auto * out = new notes_whisper_context();

    whisper_context_params cparams = whisper_context_default_params();
    out->ctx = whisper_init_from_file_with_params(model_path, cparams);
    if (out->ctx == nullptr) {
        delete out;
        return nullptr;
    }
    return out;
}

void notes_whisper_free(notes_whisper_context * ctx) {
    if (!ctx) { return; }
    if (ctx->ctx) {
        whisper_free(ctx->ctx);
        ctx->ctx = nullptr;
    }
    delete ctx;
}

int notes_whisper_transcribe(
    notes_whisper_context * ctx,
    const float * samples,
    int n_samples,
    const char * language,
    int n_threads
) {
    if (!ctx || !ctx->ctx || !samples || n_samples <= 0) { return -1; }

    whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.print_progress   = false;
    params.print_realtime   = false;
    params.print_timestamps = false;
    params.translate        = false;
    params.no_context       = true;
    params.single_segment   = false;

    if (n_threads > 0) {
        params.n_threads = n_threads;
    }
    if (language && language[0] != '\0') {
        params.language = language;
    }

    const int rc = whisper_full(ctx->ctx, params, samples, n_samples);
    return rc;
}

int notes_whisper_n_segments(notes_whisper_context * ctx) {
    if (!ctx || !ctx->ctx) { return 0; }
    return whisper_full_n_segments(ctx->ctx);
}

const char * notes_whisper_segment_text(notes_whisper_context * ctx, int index) {
    if (!ctx || !ctx->ctx) { return ""; }
    return whisper_full_get_segment_text(ctx->ctx, index);
}

int notes_whisper_segment_t0(notes_whisper_context * ctx, int index) {
    if (!ctx || !ctx->ctx) { return 0; }
    return whisper_full_get_segment_t0(ctx->ctx, index);
}

int notes_whisper_segment_t1(notes_whisper_context * ctx, int index) {
    if (!ctx || !ctx->ctx) { return 0; }
    return whisper_full_get_segment_t1(ctx->ctx, index);
}

