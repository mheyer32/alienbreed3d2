// set tabs to 4

#define WIDTH	320			// MUST be a multiple of 32
#define HEIGHT	200

struct TagItem TagArray[] = {
	SA_Interleaved, FALSE,		// c2p8 does NOT work on interleaved screens
	// can add other tags here
	TAG_DONE,0
};

struct ExtNewScreen NewScreenStructure = {
	0,0,
	WIDTH,HEIGHT,
	8,				// depth
	0,1,
	NULL,
	CUSTOMSCREEN+SCREENQUIET+NS_EXTENDED,
	NULL,
	NULL,
	NULL,
	NULL,
	(struct TagItem *)&TagArray
};

struct NewWindow NewWindowStructure1 = {
	0,0,
	WIDTH,HEIGHT,
	0,1,
	NULL,
	SIMPLE_REFRESH+BORDERLESS+NOCAREREFRESH,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	5,5,
	WIDTH,HEIGHT,
	CUSTOMSCREEN
};


// external function prototypes -----------------

void __asm c2p8_init (	register __a0 UBYTE *chunky,		// pointer to chunky data
						register __a1 UBYTE *chunky_cmp,	// pointer to chunky comparison buffer
						register __a2 PLANEPTR *planes,		// pointer to planes
						register __d0 ULONG signals1,		// 1 << sigbit1
						register __d1 ULONG signals2,		// 1 << sigbit2
						register __d2 ULONG pixels,			// WIDTH * HEIGHT
						register __d3 ULONG offset,			// byte offset into plane
						register __d4 UBYTE *buff2,			// Chip buffer (size = width*height)
						register __d5 UBYTE *buff3,			// Chip buffer (size = width*height)
						register __a3 struct GfxBase *GfxBase);

void __asm c2p8_go(void);


// internal function prototypes -----------------

long get_signals(void);
void free_signals(void);
long get_chunky_mem(void);
void free_chunky_mem(void);
void init_chunky(void);
long get_window(void);
void free_window(void);


// library bases --------------------------------

struct DosLibrary		*DOSBase;
struct IntuitionBase	*IntuitionBase;
struct ExecBase			*SysBase;
struct GfxBase			*GfxBase;


// window related variables ---------------------

struct RastPort *RP;
struct Screen *s;
struct Window *w;


// chunky data and c2p8() related variables -----

UBYTE *chunky;		// chunky data (preferably in fast ram)
UBYTE *chunky_cmp;	// chunky data comparison buffer (preferably in fast ram)
UBYTE *buff2;		// blitter buffer (chip ram)
UBYTE *buff3;		// blitter buffer (chip ram)

long sigbit1 = -1;		// used by c2p8()
long sigbit2 = -1;		// used by c2p8()


#define nokick	"This needs Kickstart 3.0!\n"
#define REPEAT_COUNT 10

long __saveds main(void)
{
	int count;

	SysBase = *(struct ExecBase **)4;

	if(DOSBase = (struct DosLibrary *) OpenLibrary("dos.library",33))
	{
		// check what kickstart version we are using
		// inform the user and exit if lower than 39

		if( DOSBase->dl_lib.lib_Version < 39)
		{
			Write(Output(), nokick, sizeof(nokick) );
			CloseLibrary( (struct Library *) DOSBase);
			return(0);
		}


		// if compiling with 68020+ code, exit before we crash
		// a 68000 machine


		#ifdef _M68020
		if(! ( SysBase->AttnFlags & AFF_68020) )
		{
			Printf("This version needs at least a 68020!\n");
			return(0);
		}
		#endif


		if(IntuitionBase = (struct IntuitionBase *) OpenLibrary("intuition.library",39))
		if(GfxBase = (struct GfxBase *) OpenLibrary("graphics.library",39))
		{

			if( get_window() )
			if( get_chunky_mem() )
			if( get_signals() )
			{

				// initialize c2p converter

				c2p8_init (	chunky,
							chunky_cmp,
							&RP->BitMap->Planes[0],
							1 << sigbit1,
							1 << sigbit2,
							WIDTH * HEIGHT,
							0,
							buff2,
							buff3,
							GfxBase);

				// fill the chunky buffer with a distinct pattern and a triangle

				init_chunky();
			
				for (count = 0; count < REPEAT_COUNT; count++)
				{
			
					// render next frame here

					c2p8_go();	// Convert chunky buffer to planar
								// only writes to the screen if the chunky
								// buffer has changed since last time.
								// Only converts the changed data

				}

				Delay(120);

			}

			free_signals();			// wait for c2p8 to finish before
									// freeing memory or closing screens

			free_chunky_mem();
			free_window();

			CloseLibrary((struct Library *)GfxBase);

		}

		if(IntuitionBase) CloseLibrary((struct Library *)IntuitionBase);

		CloseLibrary((struct Library *)DOSBase);
	}

	return(0);

}


// get signals necessary for c2p8() -------------

long get_signals(void)
{
	long ok = 0;

	if(-1 != (sigbit1 = AllocSignal(-1)))
	{
		SetSignal (1 << sigbit1, 1 << sigbit1); // Initial state is "finished"

		if(-1 != (sigbit2 = AllocSignal(-1)))
		{
			SetSignal (1 << sigbit2, 1 << sigbit2); // Initial state is "finished"

			ok = 1;
		}
	}

	return(ok);

}

void free_signals(void)
{
	if(sigbit1 != -1)
	{
		Wait (1 << sigbit1);	// wait for last c2p8 to finish pass 3
		FreeSignal(sigbit1);
		sigbit1 = -1;
	}

	if(sigbit2 != -1)
	{
		Wait (1 << sigbit2);	// wait for last c2p8 to finish totally
		FreeSignal(sigbit2);
		sigbit2 = -1;
	}
}


// get memory for chunky buffer, chunky comparsion buffer
// and two blitter buffers needed by c2p8() -----

long get_chunky_mem(void)
{
	long ok = 0, size = WIDTH * HEIGHT;

	if( chunky = AllocVec(size, MEMF_CLEAR+MEMF_ANY))
	if( chunky_cmp = AllocVec(size, MEMF_CLEAR+MEMF_ANY))
	if( buff2 = AllocVec(size, MEMF_CLEAR+MEMF_CHIP))
	if( buff3 = AllocVec(size, MEMF_CLEAR+MEMF_CHIP))
	{
		ok = 1;
	}

	return(ok);

}

void free_chunky_mem(void)
{
	if(buff3)
		FreeVec(buff3);

	if(buff2)
		FreeVec(buff2);

	if(chunky_cmp)
		FreeVec(chunky_cmp);

	if(chunky)
		FreeVec(chunky);

}


// Write a distinctive pattern to chunky buffer and a triangle

#define write_pixel(x,y,p) (chunky[y * WIDTH + x] = p )

void init_chunky(void)
{
	int i, j;
	UBYTE *p;

	p = chunky;
	for (j = 0; j < HEIGHT; j++)
	for (i = 0; i < WIDTH; i++)
	*p++ = (i + j) & 255;

	// Draw a triangle to check orientation

	for (i = 50; i < 150; i++)
	{
		write_pixel (i, 150, i);
		write_pixel (i+120, 150, i);

		write_pixel (50, i, i);
		write_pixel (170, i, i);

		write_pixel (i, i, i);
		write_pixel (i+120, i, i);
	}
}


// open a screen and a window -------------------

long get_window(void)
{
	long ok = 0;

	if(s = OpenScreen( (struct NewScreen *) &NewScreenStructure))
	{
		NewWindowStructure1.Screen = s;

		if(w = OpenWindow(&NewWindowStructure1))
		{
			RP = w->RPort;
			ok = 1;
		}
	}

	return(ok);

}

void free_window(void)
{
	if(w) CloseWindow(w);
	if(s) CloseScreen(s);
}
