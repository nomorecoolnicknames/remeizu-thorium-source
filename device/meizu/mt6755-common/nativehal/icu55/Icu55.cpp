#include <unicode/ucnv.h>
#include <unicode/ucnv_err.h>

extern "C" {

UConverter* ucnv_open_55(const char* name, UErrorCode* status) {
    return ucnv_open(name, status);
}

void ucnv_close_55(UConverter* converter) {
    ucnv_close(converter);
}

void ucnv_convertEx_55(UConverter* targetConverter, UConverter* sourceConverter,
                      char** target, const char* targetLimit,
                      const char** source, const char* sourceLimit,
                      UChar* pivotStart, UChar** pivotSource, UChar** pivotTarget,
                      const UChar* pivotLimit, UBool reset, UBool flush,
                      UErrorCode* status) {
    ucnv_convertEx(targetConverter, sourceConverter, target, targetLimit,
                   source, sourceLimit, pivotStart, pivotSource, pivotTarget,
                   pivotLimit, reset, flush, status);
}

void UCNV_FROM_U_CALLBACK_STOP_55(const void* context,
                                UConverterFromUnicodeArgs* args,
                                const UChar* units, int32_t length,
                                UChar32 codePoint,
                                UConverterCallbackReason reason,
                                UErrorCode* status) {
    UCNV_FROM_U_CALLBACK_STOP(context, args, units, length, codePoint, reason, status);
}

void UCNV_TO_U_CALLBACK_STOP_55(const void* context,
                              UConverterToUnicodeArgs* args,
                              const char* units, int32_t length,
                              UConverterCallbackReason reason,
                              UErrorCode* status) {
    UCNV_TO_U_CALLBACK_STOP(context, args, units, length, reason, status);
}

void ucnv_setFromUCallBack_55(UConverter* converter,
                            UConverterFromUCallback callback,
                            const void* context,
                            UConverterFromUCallback* oldCallback,
                            const void** oldContext, UErrorCode* status) {
    ucnv_setFromUCallBack(converter, callback, context, oldCallback, oldContext, status);
    if (oldCallback && *oldCallback == UCNV_FROM_U_CALLBACK_STOP) {
        *oldCallback = UCNV_FROM_U_CALLBACK_STOP_55;
    }
}

void ucnv_setToUCallBack_55(UConverter* converter, UConverterToUCallback callback,
                          const void* context, UConverterToUCallback* oldCallback,
                          const void** oldContext, UErrorCode* status) {
    ucnv_setToUCallBack(converter, callback, context, oldCallback, oldContext, status);
    if (oldCallback && *oldCallback == UCNV_TO_U_CALLBACK_STOP) {
        *oldCallback = UCNV_TO_U_CALLBACK_STOP_55;
    }
}

}
