/**
 * 改动内容（区别于STM32CubeMX默认）：
 * - MEMORY段定义提前
 * - 删除了 __SCMI_SHM_region_start__ 和 __SCMI_SHM_region_end__ 定义（暂未使用）
 * - 删除了 GROUP(libgcc.a libc.a libm.a libnosys.a)
 * - 删除了 /DISCARD/ : { libc.a (*) libm.a (*) libgcc.a (*) }
 */

/**
 * LLVM Linker Script 学习笔记
 * LLVM 的 Linker Script 语法和 GNU Linker Script 基本一致，但更严格一些。
 * ENTRY/MEMORY 等关键字被称为命令.
 * 变量被称为符号(Symbol), 有一个内置变量 '.' 代表当前地址.
 * 有内置函数, 比如 ALIGN(x) SIZEOF(.text) ORIGIN(region) LENGTH(region) LOADADDR(.data) KEEP(*(.isr_vectors))
 * 数字仅支持10进制和16进制
 * 双引号表示字符串, 有通配符
 */

/**
 * *(.text) 的意思是, 把所有 .o 文件里名叫 .text 的代码段都收集并拼接.
 * *(.text*) 编译器会把一些函数打包为 .text.fn 段, 所以这也是需要的.
 * *(.glue_7) *(.glue_7t) *(.eh_frame) 遗留代码
 * _sidata = LOADADDR(.data) 用于将 .data 段从 FLASH 加载到 RAM.
 */

ENTRY(Reset_Handler)

MEMORY
{
  FLASH	        (rx)  : ORIGIN = 0x80100600, LENGTH = 8387072
  /* 中断向量表 */
  NS_VECTOR_TBL	(xrw)	: ORIGIN = 0x80100000, LENGTH = 1536
  /* A核与M核通信(OpenAMP)共享内存 */
  VIRTIO_SHMEM	(xrw)	: ORIGIN = 0x812f8000, LENGTH = 32K
  RAM	          (xrw)	: ORIGIN = 0x80a00000, LENGTH = 1024K
  /* 核间通信资源表 */
  IPC_SHMEM_1	  (xrw)	: ORIGIN = 0x81200000, LENGTH = 992K
}

_Min_Heap_Size = 0x200;
_Min_Stack_Size = 0x400;
_estack = ORIGIN(RAM) + LENGTH(RAM);
_sstack = _estack - _Min_Stack_Size;

/* OpenAMP */
_virtio_shmem_size = 32K;
__OPENAMP_region_start__  = ORIGIN(VIRTIO_SHMEM);
__OPENAMP_region_end__ = ORIGIN(VIRTIO_SHMEM)+LENGTH(VIRTIO_SHMEM);

/* OPTEE encryption requires 16-byte alignment */
LINKER_DEFAULT_ALIGNMENT = 16;

SECTIONS
{
  .isr_vectors : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    KEEP(*(.isr_vectors))
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >NS_VECTOR_TBL

  .resource_table : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    KEEP (*(.resource_table*))
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >IPC_SHMEM_1

  .text : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    *(.text)
    *(.text*)
    *(.glue_7)
    *(.glue_7t)
    *(.eh_frame)

    KEEP (*(.init))
    KEEP (*(.fini))

    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >FLASH

  .rodata : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    *(.rodata)
    *(.rodata*)
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >FLASH

  .ARM.extab : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    *(.ARM.extab* .gnu.linkonce.armextab.*)
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >FLASH

  .ARM : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >FLASH

  .preinit_array : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >FLASH

  .init_array : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >FLASH

  .fini_array : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >FLASH

  _sidata = LOADADDR(.data);

  .data : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    _sdata = .;
    *(.data)
    *(.data*)

    _edata = .;
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >RAM AT> FLASH

  .bss : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    _sbss = .;
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    *(COMMON)

    _ebss = .;
    __bss_end__ = _ebss;
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >RAM

  ._user_heap_stack : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    PROVIDE ( end = . );
    PROVIDE ( _end = . );
    . = . + _Min_Heap_Size;
    . = . + _Min_Stack_Size;
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >RAM

  .ARM.attributes 0 : { *(.ARM.attributes) }
}
