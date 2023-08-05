#ifndef PCH_H
#define PCH_H

#ifdef __cplusplus
extern "C" {
#endif

int shell(int argc, char* argv[]);
const char* v8_version();
void exec_file(char* name);

#ifdef __cplusplus
}
#endif
#endif 
