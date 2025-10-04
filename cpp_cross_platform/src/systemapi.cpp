#include "systemapi.h"
#include <cstring>

// Platform-specific includes
#ifdef _WIN32
    #include <windows.h>
    #include <sysinfoapi.h>
#elif __APPLE__
    #include <sys/types.h>
    #include <sys/sysctl.h>
    #include <unistd.h>
#else // Linux
    #include <sys/sysinfo.h>
    #include <unistd.h>
    #include <limits.h>
#endif

// Template-based factorial calculator
template<int N>
struct Factorial {
    static constexpr uint64_t value = N * Factorial<N - 1>::value;
};

template<>
struct Factorial<0> {
    static constexpr uint64_t value = 1;
};

// Runtime factorial calculation
uint64_t calculateFactorialRuntime(int n) {
    if (n < 0) return 0;
    if (n == 0 || n == 1) return 1;

    uint64_t result = 1;
    for (int i = 2; i <= n; ++i) {
        result *= i;
    }
    return result;
}

// Get computer name/hostname
bool GetComputerNameString(char* buffer, int bufferSize) {
    if (buffer == nullptr || bufferSize <= 0) {
        return false;
    }

#ifdef _WIN32
    DWORD size = static_cast<DWORD>(bufferSize);
    return GetComputerNameA(buffer, &size) != 0;
#else
    return gethostname(buffer, bufferSize) == 0;
#endif
}

// Get total physical memory
uint64_t GetTotalPhysicalMemory() {
#ifdef _WIN32
    MEMORYSTATUSEX memStatus;
    memStatus.dwLength = sizeof(memStatus);
    if (GlobalMemoryStatusEx(&memStatus)) {
        return memStatus.ullTotalPhys;
    }
    return 0;
#elif __APPLE__
    int mib[2] = { CTL_HW, HW_MEMSIZE };
    uint64_t memSize = 0;
    size_t length = sizeof(memSize);

    if (sysctl(mib, 2, &memSize, &length, nullptr, 0) == 0) {
        return memSize;
    }
    return 0;
#else // Linux
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        return static_cast<uint64_t>(info.totalram) * info.mem_unit;
    }
    return 0;
#endif
}

// Get current process ID
uint32_t GetCurrentProcessID() {
#ifdef _WIN32
    return static_cast<uint32_t>(GetCurrentProcessId());
#else
    return static_cast<uint32_t>(getpid());
#endif
}

// Calculate factorial (runtime dispatch)
uint64_t CalculateFactorial(int n) {
    // Use template-based calculation for compile-time known values
    // For demonstration, we'll use runtime calculation
    return calculateFactorialRuntime(n);
}
