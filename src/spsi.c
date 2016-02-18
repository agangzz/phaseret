#include "spsi.h"
#include "float.h"

void
spsireal(const double* s, int a, int M, int N,  double* initphase,
         complex double* c)
{
    int M2 = M / 2 + 1;

    double* tmpphase = initphase;

    if (!initphase)
    {
        tmpphase = aligned_alloc(ALIGNBYTES, M2 * sizeof * tmpphase);
        memset(tmpphase, 0, M2 * sizeof * tmpphase);
    }


    for (int n = 0; n < N; n++)
    {
        const double* scol = s + n * M2;
        complex double* ccol = c + n * M2;

        spsirealupdate(scol, a, M, tmpphase);

        for (int m = 0; m < M2; m++)
            ccol[m] = scol[m] * cexp(I * tmpphase[m]);
    }

    if (!initphase)
        free(tmpphase);
}

void
maskedspsireal(const double* s, int a, int M, int N,
               const double* mask, const double* phase, double* initphase, complex double* c)
{
    int M2 = M / 2 + 1;

    double* tmpphase = initphase;

    if (!initphase)
    {
        tmpphase = aligned_alloc(ALIGNBYTES, M2 * sizeof * tmpphase);
        memset(tmpphase, 0, M2 * sizeof * tmpphase);
    }


    for (int n = 0; n < N; n++)
    {
        const double* scol = s + n * M2;
        complex double* ccol = c + n * M2;
        const double* maskcol = mask + n * M2;
        const double* phasecol = phase + n * M2;

        spsirealupdate(scol, a, M, tmpphase);

        for (int m = 0; m < M2; m++)
            if (maskcol[m])
                ccol[m] = scol[m] * cexp(I * phasecol[m]);
            else
                ccol[m] = scol[m] * cexp(I * tmpphase[m]);
    }

    if (!initphase)
        free(tmpphase);
}

void
spsirealupdate(const double* scol, int a, int M, double* tmpphase)
{
    int M2 = M / 2 + 1;

    for (int m = 1; m < M2 - 1; m++)
    {
        if (scol[m] > scol[m - 1] && scol[m] > scol[m + 1])
        {
            double p;
            double alpha = log(scol[m - 1] + DBL_MIN);
            double beta = log(scol[m] + DBL_MIN);
            double gamma = log(scol[m + 1] + DBL_MIN);
            double denom = alpha - 2.0 * beta + gamma;

            if (denom != 0.0)
                p = 0.5 * (alpha - gamma) / denom;
            else
                p = 0;

            double instf = m + p;
            double peakPhase = tmpphase[m] + 2.0 * M_PI * a * instf / M;
            tmpphase[m] = peakPhase;
            // Go towards low frequency bins
            int bin = m - 1;

            while (bin > 0 && scol[bin] < scol[bin + 1])
            {
                tmpphase[bin] = peakPhase;
                bin--;
            }

            bin = m + 1;

            while (bin < M2 - 1 && scol[bin] < scol[bin - 1])
            {
                tmpphase[bin] = peakPhase;
                bin++;
            }
        }
    }


}