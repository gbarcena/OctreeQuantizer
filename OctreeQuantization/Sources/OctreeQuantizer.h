//
//  OctreeQuantizer.h
//  OctreeQuantization
//
//  Adapted from http://rosettacode.org/wiki/Color_quantization/C
//

#ifndef OctreeQuantization_OctreeQuantizer_h
#define OctreeQuantization_OctreeQuantizer_h

typedef struct {
	int w, h;
	unsigned char *pix;
} image_t, *image;

typedef struct oct_node_t oct_node_t, *oct_node;
struct oct_node_t{
	int64_t r, g, b, a; /* sum of all child node colors */
	int count, heap_idx;
	unsigned char n_kids, kid_idx, flags, depth;
	oct_node kids[8], parent;
};


void color_quant(image im, int n_colors, int dither);

#endif
