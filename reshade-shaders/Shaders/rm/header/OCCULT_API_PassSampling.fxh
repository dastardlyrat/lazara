#ifndef OCCULT_API_PASS_SAMPLING_FXH
#define OCCULT_API_PASS_SAMPLING_FXH

#define OCCULT_BATCH_00_START 0
#define OCCULT_BATCH_01_START 6
#define OCCULT_BATCH_02_START 12
#define OCCULT_BATCH_03_START 18
#define OCCULT_BATCH_WIDTH 6

int OCCULT_BatchStartIndex(int batchIndex)
{
    int safeBatch = clamp(batchIndex, 0, 3);
    return safeBatch * OCCULT_BATCH_WIDTH;
}

#endif // OCCULT_API_PASS_SAMPLING_FXH
