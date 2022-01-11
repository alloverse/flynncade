#include "libretro.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdbool.h>
#include <errno.h>
#include <dlfcn.h>
#include <libswresample/swresample.h>

void core_log(enum retro_log_level level, const char *fmt, ...) {
    char buffer[4096] = {0};
    static const char * levelstr[] = { "dbg ", "info", "warn", "err " };
    va_list va;

    va_start(va, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, va);
    va_end(va);

    if (level == 0)
        return;

    fprintf(stderr, "[%s] %s", levelstr[level], buffer);
    fflush(stderr);

    if (level == RETRO_LOG_ERROR)
        exit(EXIT_FAILURE);
}

static SwrContext *swr;
static int ssr, sst, dsr, dst;

size_t flynn_resample(
    const int16_t *source, size_t source_frame_count, int source_samplerate, bool source_stereo,
    int16_t *dest, size_t dest_frame_count, int dest_samplerate, bool dest_stereo
)
{
    if(swr && (ssr != source_samplerate || sst != source_stereo || dsr != dest_samplerate || dst != dest_stereo))
    {
        swr_close(swr);
        swr_free(&swr);
        swr = NULL;
    }
    if(!swr)
    {
        fprintf(stderr, "helper: reallocating resampling context\n");
        ssr = source_samplerate; sst = source_stereo; dsr = dest_samplerate; dst = dest_stereo;
        swr = swr_alloc_set_opts(
            NULL,
            dest_stereo ? AV_CH_LAYOUT_STEREO : AV_CH_LAYOUT_MONO,
            AV_SAMPLE_FMT_S16,
            dest_samplerate,
            source_stereo ? AV_CH_LAYOUT_STEREO : AV_CH_LAYOUT_MONO,
            AV_SAMPLE_FMT_S16,
            source_samplerate,
            0, 0
        );
        if(!swr)
        {
            fprintf(stderr, "helper: ERR: Failed to create audio converter!!\n");
            return 0;
        }
        swr_init(swr);
    }
    AVFrame *sourceframe = av_frame_alloc();
    sourceframe->channel_layout = source_stereo ? AV_CH_LAYOUT_STEREO : AV_CH_LAYOUT_MONO;
    sourceframe->sample_rate = source_samplerate;
    sourceframe->format = AV_SAMPLE_FMT_S16;
    sourceframe->data[0] = (uint8_t *)source;
    sourceframe->nb_samples = source_frame_count;

    AVFrame *destframe = av_frame_alloc();
    destframe->channel_layout = dest_stereo ? AV_CH_LAYOUT_STEREO : AV_CH_LAYOUT_MONO;
    destframe->sample_rate = dest_samplerate;
    destframe->format = AV_SAMPLE_FMT_S16;
    destframe->data[0] = (uint8_t *)dest;
    destframe->nb_samples = dest_frame_count;
    destframe->linesize[0] = dest_frame_count * 2 * dest_stereo?2:1;

    int ret = swr_convert_frame(swr, destframe, sourceframe);
    if(ret != 0)
    {
        fprintf(stderr, "helper: ERR: Failed to resample!! %d\n", ret);
        return 0;
    }
    return destframe->nb_samples;
}