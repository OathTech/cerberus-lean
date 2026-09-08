/* D2's local equivalent to perf: CPU-time SIGPROF sampling of the existing
 * executable, without recompiling it. Linux x86-64, native uint64_t records.
 * Compile: cc -shared -fPIC -O2 -o sampler.so cpu-stack-sampler.c -ldl
 * Use only on profiling runs, never on the ordinary CPU-ratio runs.
 * FC_SAMPLE_FILE must be a new file. Optional FC_SAMPLE_US defaults to 10000.
 * Header: magic, executable PIE base, interval us. Each record: interrupted
 * RIP, backtrace depth, 96 return addresses (unused slots zero).
 * backtrace is pre-warmed before enabling the timer. It is not guaranteed
 * async-signal-safe by POSIX; profiling runs have an external timeout and
 * must finish successfully. Raw traces are checked for complete records.
 */
#define _GNU_SOURCE
#include <execinfo.h>
#include <fcntl.h>
#include <link.h>
#include <signal.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/time.h>
#include <ucontext.h>
#include <unistd.h>

static int sample_fd = -1;
static uint64_t image_base;

static int find_main(struct dl_phdr_info *info, size_t size, void *data) {
    (void)size; (void)data;
    if (!info->dlpi_name || !info->dlpi_name[0]) {
        image_base = info->dlpi_addr;
        return 1;
    }
    return 0;
}

static void sample(int sig, siginfo_t *info, void *context) {
    (void)sig; (void)info;
    ucontext_t *uc = context;
    void *frames[96];
    uint64_t row[98] = {0};
    row[0] = uc->uc_mcontext.gregs[REG_RIP];
    int n = backtrace(frames, 96);
    row[1] = n;
    for (int i = 0; i < n; i++) row[i + 2] = (uintptr_t)frames[i];
    if (write(sample_fd, row, sizeof(row)) != sizeof(row)) _exit(96);
}

__attribute__((constructor)) static void start_sampling(void) {
    const char *path = getenv("FC_SAMPLE_FILE");
    if (!path) return;
    sample_fd = open(path, O_WRONLY | O_CREAT | O_EXCL, 0600);
    if (sample_fd < 0) _exit(97);
    dl_iterate_phdr(find_main, NULL);
    void *warm[96];
    backtrace(warm, 96);
    long interval = 10000;
    const char *period = getenv("FC_SAMPLE_US");
    if (period) interval = strtol(period, NULL, 10);
    if (interval < 1000 || interval >= 1000000) _exit(98);
    uint64_t header[3] = {0x464353414d504c31ULL, image_base, interval};
    if (write(sample_fd, header, sizeof(header)) != sizeof(header)) _exit(96);
    struct sigaction action = {0};
    action.sa_sigaction = sample;
    action.sa_flags = SA_SIGINFO | SA_RESTART;
    sigemptyset(&action.sa_mask);
    if (sigaction(SIGPROF, &action, NULL)) _exit(99);
    struct itimerval timer = {{0, interval}, {0, interval}};
    if (setitimer(ITIMER_PROF, &timer, NULL)) _exit(99);
}

__attribute__((destructor)) static void stop_sampling(void) {
    if (sample_fd < 0) return;
    struct itimerval timer = {{0, 0}, {0, 0}};
    setitimer(ITIMER_PROF, &timer, NULL);
    close(sample_fd);
}
