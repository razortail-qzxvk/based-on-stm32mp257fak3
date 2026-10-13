#include "main.h"

extern "C" void SystemClock_Config(void);

int main() {
#if defined(DEBUG)
  volatile uint32_t debug = 1;
  while (debug); // waiting for ST-LINK attachment. User can change "debug" to 0 to continue the execution.
#endif

  HAL_Init();

  if (IS_DEVELOPER_BOOT_MODE()) {
    SystemClock_Config();
  } else {
    SystemCoreClockUpdate();
  }

  while (true) {
  }
}