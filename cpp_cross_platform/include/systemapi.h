#ifndef SYSTEMAPI_H
#define SYSTEMAPI_H

#include <cstdint>

// Export macros for cross-platform DLL/SO support
#ifdef _WIN32
    #ifdef SYSTEMAPI_EXPORTS
        #define SYSTEMAPI_API __declspec(dllexport)
    #else
        #define SYSTEMAPI_API __declspec(dllimport)
    #endif
#else
    #define SYSTEMAPI_API __attribute__((visibility("default")))
#endif

// C linkage for FFI compatibility
#ifdef __cplusplus
extern "C" {
#endif

// Get computer/hostname
SYSTEMAPI_API bool GetComputerNameString(char* buffer, int bufferSize);

// Get total physical memory in bytes
SYSTEMAPI_API uint64_t GetTotalPhysicalMemory();

// Get current process ID
SYSTEMAPI_API uint32_t GetCurrentProcessID();

// Calculate factorial (template-based in implementation)
SYSTEMAPI_API uint64_t CalculateFactorial(int n);

#ifdef __cplusplus
}
#endif

#endif // SYSTEMAPI_H
