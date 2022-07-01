// set tabs to 4

#define WIDTH	320			// MUST be a multiple of 32
#define HEIGHT	200

struct TagItem TagArray[] = {
	// can add other tags here
	TAG_DONE,0
};

// screen related variables ---------------------

struct Screen *s;

char perm[8] = {0, 1, 2, 3, 4, 5, 6, 7};	// bitplane order

PLANEPTR raster;			// 8 contiguous bitplanes
struct BitMap bitmap_bm;	// The full depth-8 bitmap


struct ExtNewScreen NewScreenStructure = {
	0,0,
	WIDTH,HEIGHT,
	8,				// depth
	0,1,
	NULL,
	CUSTOMSCREEN+CUSTOMBITMAP+SCREENQUIET+NS_EXTENDED,
	NULL,
	NULL,
	NULL,
	&bitmap_bm,
	(struct TagItem *)&TagArray
};


// external function prototypes -----------------

void __asm c2p_020(	register __a0 UBYTE *chunky,
					register __a1 PLANEPTR raster );

// internal function prototypes -----------------

long get_timer(void);
void free_timer(void);
long get_chunky_mem(void);
void free_chunky_mem(void);
void init_chunky(void);
long get_screen(void);
void free_screen(void);


// library bases --------------------------------

struct DosLibrary		*DOSBase;
struct IntuitionBase	*IntuitionBase;
struct ExecBase			*SysBase;
struct GfxBase			*GfxBase;

struct Library			*TimerBase;
struct Library			*MathIeeeDoubBasBase;

// timer related variables ----------------------

struct timerequest	timerio_m;
struct EClockVal	time0_m;
struct EClockVal	time1_m;

struct timerequest	*timerio = &timerio_m;
struct EClockVal	*time0	= &time0_m;
struct EClockVal	*time1	= &time1_m;

ULONG timerclosed = TRUE;
double micros_per_eclock;		// Length of EClock tick in microseconds

// chunky data ----------------------------------

UBYTE *chunky;		// chunky data (preferably in fast ram)


#define nokick	"This needs Kickstart 3.0!\n"
#define REPEAT_COUNT 10

long __saveds main(void)
{
	int count;
	double micros, sum_micros;

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

			if( get_timer() )
			if( get_screen() )
			if( get_chunky_mem() )
			{
				Printf ("\nWidth = %ld, Height = %ld, Depth = 8\n\n",WIDTH, HEIGHT );
		
				sum_micros = 0.0;

	
				// time each c2p call and average it out over 10 calls

				for (count = 0; count < REPEAT_COUNT; count++)
				{
			
					Forbid();

					// fill the chunky buffer with a distinct pattern and a triangle
					init_chunky();

					ReadEClock(time0);

					c2p_020(chunky,raster);		// c2p_020() destroys given
												// chunky buffer - need to
												// render a new frame for
												// each c2p call

					ReadEClock (time1);
					Permit();
			
					micros = (time1->ev_lo - time0->ev_lo) * micros_per_eclock;
					sum_micros += micros;
			
					Printf (" %8ld : %9ld µs\n", count, (long)micros);

				}


				Printf ("\nMean time = %9ld microseconds\n\n", (long)(sum_micros / REPEAT_COUNT) );

			}

			free_chunky_mem();
			free_screen();
			free_timer();

			CloseLibrary((struct Library *)GfxBase);

		}

		if(IntuitionBase) CloseLibrary((struct Library *)IntuitionBase);

		CloseLibrary((struct Library *)DOSBase);
	}

	return(0);

}


// open timer.device and the math library -------

long get_timer(void)
{
	long ok = 0;

	if(MathIeeeDoubBasBase = OpenLibrary("mathieeedoubbas.library",33))
	if( ! (timerclosed = OpenDevice(TIMERNAME, UNIT_VBLANK, (struct IORequest *)timerio, 0)))
	{
		TimerBase = (struct Library *)timerio->tr_node.io_Device;
		micros_per_eclock = 1000000.0 / (double)ReadEClock (time0);

		ok = 1;
	}

	return(ok);

}

void free_timer(void)
{
	if(!timerclosed)
		CloseDevice( (struct IORequest *) timerio);

	if(MathIeeeDoubBasBase)
		CloseLibrary(MathIeeeDoubBasBase);
}


// get memory for chunky buffer -----------------

long get_chunky_mem(void)
{
	long ok = 0, size = WIDTH * HEIGHT;

	if( chunky = AllocVec(size, MEMF_CLEAR+MEMF_ANY))
	{
		ok = 1;
	}

	return(ok);

}

void free_chunky_mem(void)
{
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


// get bitplanes and open screen  ---------------

long get_screen(void)
{
	long depth, ok = 0;

	InitBitMap(&bitmap_bm, 8, WIDTH, HEIGHT);	// Full depth-8 bm

	// since c2p_020() needs 8 contiguous bitplanes, it is not
	// possible to just use OpenScreen() or AllocBitmap() as they
	// may give the bitplanes in a few chunks of memory (noncontiguous)

	if( raster = (PLANEPTR)AllocRaster (WIDTH, 8 * HEIGHT))
	{
		for(depth = 0; depth < 8; depth++)
		    bitmap_bm.Planes[depth] = raster + perm[depth] * RASSIZE (WIDTH, HEIGHT);

		
		if(s = OpenScreen( (struct NewScreen *) &NewScreenStructure))
		{
			SetRast(&s->RastPort, 0);		// clear screen memory
			WaitBlit();						// wait until it's finished
	
			ok = 1;
		}
	}

	return(ok);

}

void free_screen(void)
{
	if(s) CloseScreen(s);

	if(raster) FreeRaster (raster, WIDTH, 8 * HEIGHT);

}
