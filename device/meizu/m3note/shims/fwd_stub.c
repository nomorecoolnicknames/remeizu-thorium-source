/* Empty body of a DT_NEEDED forwarder (see Android.bp of this tree).
 * The library exists only for its soname and its own DT_NEEDED; bionic binds
 * every consumer against the whole breadth-first load group
 * (bionic/linker/linker.cpp), so the consumers' symbols land in the library
 * this one NEEDs.  Same idea as libgui_m95 (device/meizu/m95/shims). */
void __mt6755_fwd_marker(void) {}
