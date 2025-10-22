#ifndef TG_DC_H
#define TG_DC_H

/* Telegram is currently composed by a decentralized,
 * multi-DC infrastructure (currently 5 DCs, each of which
 * can work independently) spread across different
 * locations worldwide. However, some of the less busy DCs
 * have been lately dismissed and their IP addresses are now
 * kept as aliases to the nearest one.
 */

#define DCS \
	DC(1, 00001,  "pluto",  "149.154.175.53",   "2001:b28:f23d:f001::a","MIA, Miami FL, USA") \
	DC(2, 00002, "venus",  "149.154.167.51",   "2001:67c:4e8:f002::a", "AMS, Amsterdam, NL") \
	DC(3, 00003, "aurora", "149.154.175.100",  "2001:b28:f23d:f003::a","MIA, Miami FL, USA") \
	DC(4, 00004, "vesta",  "149.154.167.91",   "2001:67c:4e8:f004::a", "AMS, Amsterdam, NL") \
	DC(5, 00005, "flora",  "91.108.56.130",    "2001:b28:f23f:f005::a","SIN, Singapore") \
	DC(1t, 10001, "pluto",  "149.154.175.10",   "2001:b28:f23f:f005::a","MIA, Miami FL, USA TEST") \
	DC(2t, 10002, "venus",  "149.154.167.40",   "2001:67c:4e8:f002::e", "AMS, Amsterdam, NL TEST") \
	DC(3t, 10003, "aurora", "149.154.175.117",  "2001:b28:f23d:f003::e","MIA, Miami FL, USA TEST") \

enum dc {
	DCNULL = 0,
#define DC(n, ...) DC##n,
	DCS
#undef DC
	DC_COUNT
};

typedef struct dc_t {
	enum dc dc;            // DC1, DC2, etc
	int number;            // 1, 2, 3
	int id;                // 00001, 00002
	char name[16];
	char ipv4[16];
	char ipv6[32];
	char description[64];
} dc_t;

static const dc_t DCs[] = 
{
	DCNULL, 0, 0, "NULL", "0", "0", "NULL",
#define DC(n, num, dcname, ip4, ip6, desc) DC##n, num, DC##n, dcname, ip4, ip6, desc,
	DCS
#undef DC
};

#endif /* ifndef TG_DC_H */
