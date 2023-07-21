#include "cmakeconfig.h"
#include <wtf/MainThread.h>
#include "JavaScriptCore/InitializeThreading.h"
#include "JavaScriptCore/JavaScript.h"

extern "C" {
    #include "road-to-jsc.h"
}

void jsc_init() {
    WTF::initializeMainThread();
    JSC::initialize();
    std::string scriptString = "function a() {return 42;}; print(a())";

    JSContextGroupRef contextGroup = JSContextGroupCreate();
    JSGlobalContextRef context = JSGlobalContextCreateInGroup(contextGroup, nullptr);
    JSStringRef jsScriptString = JSStringCreateWithUTF8CString(scriptString.c_str());
    JSValueRef exception = nullptr;
    JSValueRef jsScript = JSEvaluateScript(context, jsScriptString, nullptr, nullptr, 0, &exception);
    
    JSStringRelease(jsScriptString);
    JSGlobalContextRelease(context);
    JSContextGroupRelease(contextGroup);
}
