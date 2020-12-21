#include <asm/desc.h>

#define PTR_LOW(x) ((unsigned long long)(x) & 0xFFFF)
#define PTR_MIDDLE(x) (((unsigned long long)(x) >> 16) & 0xFFFF)
#define PTR_HIGH(x) ((unsigned long long)(x) >> 32)

void my_store_idt(struct desc_ptr *idtr) {
		asm volatile("sidt %0":"=m" (*idtr));
}

void my_load_idt(struct desc_ptr *idtr) {
	asm volatile("lidt %0"::"m" (*idtr));
}

void my_set_gate_offset(gate_desc *gate, unsigned long addr) {
	gate->offset_low = PTR_LOW(addr);
	gate->offset_middle = PTR_MIDDLE(addr);
	gate->offset_high = PTR_HIGH(addr);
}

unsigned long my_get_gate_offset(gate_desc *gate) {
	#ifdef CONFIG_X86_64
		return gate->offset_low | ((unsigned long)gate->offset_middle << 16) |
				((unsigned long)gate->offset_high << 32);
	#else
		return gate->offset_low | ((unsigned long)gate->offset_middle << 16);
	#endif
}
