/**
 * 改动内容（区别于STM32CubeMX默认）：
 * - MEMORY段定义提前
 * - 删除了 __SCMI_SHM_region_start__ 和 __SCMI_SHM_region_end__ 定义（暂未使用）
 * - 删除了 GROUP(libgcc.a libc.a libm.a libnosys.a)
 * - 删除了 /DISCARD/ : { libc.a (*) libm.a (*) libgcc.a (*) }
 */

ENTRY(Reset_Handler)

MEMORY
{
  FLASH	(rx)	: ORIGIN = 0x80100600, LENGTH = 8387072
  NS_VECTOR_TBL	(xrw)	: ORIGIN = 0x80100000, LENGTH = 1536
  VIRTIO_SHMEM	(xrw)	: ORIGIN = 0x812f8000, LENGTH = 32K
  RAM	(xrw)	: ORIGIN = 0x80a00000, LENGTH = 1024K
  IPC_SHMEM_1	(xrw)	: ORIGIN = 0x81200000, LENGTH = 992K
}

/* Highest address of the user mode stack */
_estack = ORIGIN(RAM) + LENGTH(RAM);	/* end of "RAM" Ram type memory */
_sstack = _estack - _Min_Stack_Size;

_Min_Heap_Size = 0x200;	/* required amount of heap  */
_Min_Stack_Size = 0x400;	/* required amount of stack */

_virtio_shmem_size = 32K;  /* size of the virtio pool used for RPMsg communication */

 /* Symbols needed for OpenAMP to enable rpmsg */
__OPENAMP_region_start__  = ORIGIN(VIRTIO_SHMEM);
__OPENAMP_region_end__ = ORIGIN(VIRTIO_SHMEM)+LENGTH(VIRTIO_SHMEM);

LINKER_DEFAULT_ALIGNMENT = 16;

SECTIONS
{
  /*
   * To support firmware image encryption by OP-TEE (TF-M running on a coprocessor),
   * we need to align all sections to have a modulo 16 size. This size is the atomic block size to
   * encrypt. Use TFM_LINKER_DEFAULT_ALIGNMENT that is set to 32 bytes.
   * Each section declared should respect this template:
   *
   * section_name : ALIGN(LINKER_DEFAULT_ALIGNMENT)
   * {
   *     ...
   *     ALIGN(LINKER_DEFAULT_ALIGNMENT)
   * }
   */

  /* The startup code into "NS_VECTOR_TBL" Ram type memory
   * Do not update the ".isr_vectors" section name. the name
   * is used by the Linux kernel to retrieve the address
   * of the vector table*/
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

  /* The program code and other data into "RAM" Ram type memory */
  .text : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    *(.text)           /* .text sections (code) */
    *(.text*)          /* .text* sections (code) */
    *(.glue_7)         /* glue arm to thumb code */
    *(.glue_7t)        /* glue thumb to arm code */
    *(.eh_frame)

    KEEP (*(.init))
    KEEP (*(.fini))

    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >FLASH

  /* Constant data into "RAM" Ram type memory */
  .rodata : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    *(.rodata)         /* .rodata sections (constants, strings, etc.) */
    *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
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

  /* Used by the startup to initialize data */
  _sidata = LOADADDR(.data);

  /* Initialized data sections into "RAM" Ram type memory */
  .data : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    _sdata = .;        /* create a global symbol at data start */
    *(.data)           /* .data sections */
    *(.data*)          /* .data* sections */

    _edata = .;        /* define a global symbol at data end */
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >RAM AT> FLASH

  /* Uninitialized data section into "RAM" Ram type memory */
  .bss : ALIGN(LINKER_DEFAULT_ALIGNMENT)
  {
    /* This is used by the startup in order to initialize the .bss section */
    _sbss = .;         /* define a global symbol at bss start */
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    *(COMMON)

    _ebss = .;         /* define a global symbol at bss end */
    __bss_end__ = _ebss;
    . = ALIGN(LINKER_DEFAULT_ALIGNMENT);
  } >RAM

  /* User_heap_stack section, used to check that there is enough "RAM" Ram  type memory left */
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