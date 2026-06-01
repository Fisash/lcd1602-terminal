#ifndef CALLS_H_SENTRY
#define CALLS_H_SENTRY

int sys_read(int fd, void *buf, int size);
int sys_write(int fd, const void *buf, int size);
int sys_open(const char *pathname, int flags, unsigned int mode);
int sys_close(int fd);
extern int sys_errno;

#endif
