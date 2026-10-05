// Preserve the own Android 6 C++ symbol while calling the genuine SDK28 C API.
// libgem requests native driver query strings, not the framework-facing strings.
extern "C" const char* sdk28EglQueryImplementation(void*, int)
    asm("eglQueryStringImplementationANDROID");

const char* eglQueryStringImplementationANDROID(void* display, int name) {
    return sdk28EglQueryImplementation(display, name);
}
