#include "v8-gn.h"
#include "v8.h"
#include "101.h"

extern "C" const char* v8_version() { return v8::V8::GetVersion(); }

