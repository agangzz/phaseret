#ifndef _mex_helper_h
#define _mex_helper_h

#include <complex.h>
#ifdef __STDC_UTF_16__
#include <uchar.h>
#endif
#include "mex.h"

#ifndef UNUSED
#define UNUSED(expr) do { (void)(expr); } while (0)
#endif

void
complex2split(const complex double* in, int L, double* outr, double* outi)
{
    for (int ii = 0; ii < L; ++ii)
    {
        outr[ii] = creal(in[ii]);
        outi[ii] = cimag(in[ii]);
    }

}

#endif