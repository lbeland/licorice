
# cimport C libraries
from libc.stdlib cimport atoi, exit
from libc.stdio cimport printf, snprintf, fflush, stdout
from libc.string cimport strcpy, memset, memcpy
from libc.signal cimport SIGINT, SIGUSR1, SIGALRM, SIGBUS, SIGSEGV, SIGQUIT, SIGTERM
from libc.stdint cimport int8_t, uint8_t, int16_t, uint16_t, int32_t, uint32_t, int64_t, uint64_t
from posix.signal cimport kill, sigaction, sigaction_t, sigset_t, sigemptyset, sigaddset, sigfillset
from posix.unistd cimport getppid, pause, close, getpid
from posix.mman cimport shm_open, mmap, munmap, PROT_READ, PROT_WRITE, MAP_SHARED, mlockall, MCL_CURRENT, MCL_FUTURE, munlockall, shm_unlink
from posix.types cimport pid_t
cimport posix.stat 
from posix.fcntl cimport O_RDWR, O_CREAT, O_TRUNC
from libcpp cimport bool
from posix.time cimport clock_gettime, timespec

from runner_utils cimport times_t

import sys, signal
import SharedArray as sa
from cpython.exc cimport PyErr_CheckSignals
import random as random
import math
import numpy as np
import posix_ipc
import time

# import LiCoRICE utils
from module_utils import create_shared_array

cdef extern from "semaphore.h":
  enum: __SIZEOF_SEM_T
  cdef union sem_union:
    char __size[__SIZEOF_SEM_T]
    long int __align
  ctypedef sem_union sem_t
  sem_t *sem_open(const char *name, int oflag)
  int sem_wait(sem_t *)
  int sem_post(sem_t *)
  int sem_close(sem_t *sem)
  int sem_getvalue(sem_t *sem, int *val)
#not used yet, just seeing if it would work
cdef extern from "unistd.h":
  int getpagesize()
cdef extern from "stdatomic.h":
  enum memory_order:
    memory_order_relaxed,
    memory_order_consume,
    memory_order_acquire,
    memory_order_release,
    memory_order_acq_rel,
    memory_order_seq_cst
  void atomic_thread_fence(memory_order)

cdef extern from "utilityFunctions.h":
  void init_utils(void (*pHandleExit)(int exitStatus), sigset_t *pExitMask)
  void die(char *errorStr)
  void open_shared_mem(uint8_t **ppmem, const char *pName, int numBytes, int shm_flags, int mmap_flags)
  void set_sighandler(int signum, void *psh, sigset_t *block_mask)
  void make_realtime()

import numpy as np
cimport numpy as np
cimport cython

cdef extern from "constants.h":
  enum: NUM_PAGES_IN_GB
  enum: NUM_CHILDREN
  enum: BYTES_IN_GB
  cdef const char *SMEM0_PATHNAME
  enum: PAGESIZE
  enum: LATENCY
  enum: NUM_SEM_SIGS
  enum: NUM_INTERNAL_SIGS
  size_t ROUND_UP(int X, int Y)
  enum: BUF_VARS_LEN
  enum: SHM_SIZE
  enum: NUM_TICKS_OFFSET
  enum: CLOCK_MONOTONIC_RAW_OFFSET
  enum: CLOCK_MONOTONIC_OFFSET
  enum: CLOCK_REALTIME_OFFSET
  enum: BUF_VARS_OFFSET
  enum: SEM_NAME_LEN

cdef pid_t pid
cdef pid_t ppid
cdef public sigset_t exitMask

# shared memory vars
cdef size_t shm_size
cdef uint8_t *pmem
cdef int64_t *pNumTicks
cdef times_t times
cdef timespec *pClockMonotonicRaw
cdef timespec *pClockMonotonic
cdef timespec *pClockRealtime
cdef sem_t *pModUpSem
cdef sem_t *pModDownSem
cdef sem_t *pSigSems[NUM_SEM_SIGS]
cdef char semNameBuf[SEM_NAME_LEN]
cdef uint32_t *pBufVars
cdef uint32_t *messageBufVars
cdef uint32_t messageLatency






cdef void handle_exit(int exitStatus) noexcept:
  global pmem, shm_size, pModUpSem, pModDownSem, pSigSems
  printf("EXIT HANDLER for producer\n")

  
  sa_names = [sig.name for sig in sa.list()]
  if b"message" in sa_names:
    sa.delete("shm://message")
  else:
    print(sa_names, flush=True)
    print(sa.list(), flush=True)
    printf("Could not delete shared array message.\n")
  munmap(pmem, shm_size)
  munlockall()

  if (sem_close(pModUpSem) == -1):
    printf("Could not close source up semaphore. \n")
  if (sem_close(pModDownSem) == -1):
    printf("Could not close source down semaphore. \n")
  if (sem_close(pSigSems[0]) == -1):
    printf("Could not close signal semaphore. \n")

  exit(exitStatus)

cdef void int_handler(int signum):
  pass

cdef void exit_handler(int signum):
  printf("EXIT HANDLER for producer\n")
  fflush(stdout)
  handle_exit(0)

cdef void mem_error_handler(int signum):
  printf("Child memory error: signum %d\n", signum)
  printf("Child ID: %d\n", 0)
  handle_exit(1)

# runtime code
# intialize utilityFunctions
sigfillset(&exitMask)
init_utils(&handle_exit, &exitMask)
ppid = getppid()
pid = getpid()
printf("child %d id: %d\n", 0, pid)

# open and map shared parent memory
shm_size = ROUND_UP(SHM_SIZE, PAGESIZE)
open_shared_mem(
  &pmem, SMEM0_PATHNAME, shm_size, O_RDWR, PROT_READ | PROT_WRITE
)
pNumTicks = <int64_t *>(pmem + NUM_TICKS_OFFSET)
pClockMonotonicRaw = <timespec *>(pmem + CLOCK_MONOTONIC_RAW_OFFSET)
pClockMonotonic = <timespec *>(pmem + CLOCK_MONOTONIC_OFFSET)
pClockRealtime = <timespec *>(pmem + CLOCK_REALTIME_OFFSET)
pBufVars = <uint32_t *>(pmem + BUF_VARS_OFFSET)

pModUpSem = sem_open("/mod_up_sem_0", 0)
pModDownSem = sem_open("/mod_down_sem_0", 0)
snprintf(semNameBuf, SEM_NAME_LEN, "/sig_sem_%d", 0)
pSigSems[0] = sem_open(semNameBuf, 0)


in_sigs = {}
created_mem = sa.list()

out_sigs = {}

if any([b'message' == x[0] for x in created_mem]):
  sa.delete("shm://message")
  print("recreated shared array message.\n", flush=True)
out_sigs["message"] = create_shared_array(
  "shm://message", (5000,128), dtype=np.double
)
# make sure SharedArray==2.0.4 -> try to transfer to 3.0.0
out_sigs["message"].base.mlock()
messageRaw = out_sigs["message"]
messageBufVars = pBufVars + 0
memset(messageBufVars, 0, 16)
messageLatency =  0
messageBufVars[2] = 0
messageBufVars[10] = 0 # messageLatency
message = messageRaw[messageBufVars[8]]
messageBufVars[5] = 128
messageBufVars[6] = 128
messageBufVars[7] = 640000
messageBufVars[13] = 1


# set signal mask
sigfillset(&exitMask)
# handle signals
set_sighandler(SIGINT, &int_handler, &exitMask)
set_sighandler(SIGTERM, &exit_handler, &exitMask)
set_sighandler(SIGBUS, &mem_error_handler, &exitMask)
set_sighandler(SIGSEGV, &mem_error_handler, &exitMask)





n_messages = 10000
output_file = '/home/linda/Documents/new_benchmark_test/Benchmark_IPC/licorice/rt_results/1_128'
send_times = []
make_realtime()

kill(ppid,SIGUSR1)

cdef int semVal
while(True):
  sem_wait(pModUpSem)


  if pNumTicks[0] >= 0:
    times.tick = pNumTicks[0]
  times.monotonic_raw = <uint64_t>(
    pClockMonotonicRaw[0].tv_sec * 1e9 + pClockMonotonicRaw[0].tv_nsec
  )
  times.monotonic = <uint64_t>(
    pClockMonotonic[0].tv_sec * 1e9 + pClockMonotonic[0].tv_nsec
  )
  times.realtime = <uint64_t>(
    pClockRealtime[0].tv_sec * 1e9 + pClockRealtime[0].tv_nsec
  )



  message = messageRaw[messageBufVars[10]]

  now = time.monotonic()
  message[:, :] = now
  
  if pNumTicks[0] >= 0:
      send_times.append(now)
  
  if pNumTicks[0] == n_messages - 1:
      diffs = np.diff(send_times)
      mean_period = float(np.mean(diffs)) * 1e6
      std_period = float(np.std(diffs)) * 1e6
      max_period = float(np.max(diffs)) * 1e6
  
      with open(output_file + "_Producer.csv", "w") as f:
          f.write("Metric,Send_period\n")
          f.write(f"mean,{mean_period}\n")
          f.write(f"std,{std_period}\n")
          f.write(f"max,{max_period}\n")
  


  messageBufVars[2] += messageBufVars[5]
  messageBufVars[10] += messageBufVars[13]
  if (messageBufVars[7] <= (messageBufVars[2] + messageBufVars[6])):
    messageBufVars[4] = messageBufVars[2]
    messageBufVars[12] = messageBufVars[10]
  elif (messageBufVars[2] > messageBufVars[4]):
    messageBufVars[4] = messageBufVars[2] 
    messageBufVars[12] = messageBufVars[10]
  messageBufVars[3] += messageBufVars[5]
  messageBufVars[11] += 1

  # update bufVars
  messageBufVars[1] = messageBufVars[2]
  messageBufVars[9] = messageBufVars[10] - messageLatency
  messageBufVars[0] = messageBufVars[1] - messageBufVars[3]
  messageBufVars[8] = messageBufVars[9] - messageBufVars[11]
  if (messageBufVars[7] < (messageBufVars[2] + messageBufVars[6])):
    messageBufVars[2] = 0
    messageBufVars[10] = 0
  messageBufVars[3] = 0
  messageBufVars[11] = 0  

  if pNumTicks[0] >= 0:
  
    sem_post(pSigSems[0])

  atomic_thread_fence(memory_order_seq_cst)
  sem_post(pModDownSem)

