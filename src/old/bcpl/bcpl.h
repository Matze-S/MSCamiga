/* Copyright (C) 1989 by Matthias Schmidt */

/* BCPL.H - Header for Aztec C programs using the 'bcpl.lib' */

#ifndef BCPL_H
#define BCPL_H

/* global variables passed to the start() - routine */

struct globals {
	long *stkbase;			/* a1 */
	long null,*a2,a5,a6;		/* a0/a2/a5-a6 */
	long arglen;			/* argline... */
	char *argptr;
	struct ExecBase *SysBase;	/* library bases... */
};

/* defines */

#define IS_BSTR (1L<<31)		/* is already bcpl string */
#define TRUE -1L			/* booleans... */
#define FALSE 0L

/* macros */

#define lptr(bp) ((long *)((long)(bp) << 2))	/* convert bptr to lptr */
#define bptr(ap) ((long)(ap) >> 2))		/* convert aptr to bptr */

/* function declarations */

struct globals *globals();
long *alloc(),bstr(),callgv(),*cli(),currentdir(),doexec(),dolib();
long dospkt(),findinput(),findoutput(),input(),output(),*palloc(),*rdargs();
long rdch(),read(),request(),result2(),*root(),stricmp(),*taskid();
long *taskwait(),testbreak(),unrdch(),write();
void close(),endread(),endwrite(),fault(),free(),geta4(),geta6();
void selectinput(),selectoutput(),stop(),taskheld(),wrch(),writef();
void writes();

#endif

