function test_failed = test_libltfat_idgt_long(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

[~,~,enuminfo]=libltfatprotofile;
phaseconv = enuminfo.ltfat_phaseconvention;

fftwflags = struct('FFTW_MEASURE',0,'FFTW_ESTIMATE',64,'FFTW_PATIENT',32,'FFTW_DESTROY_INPUT',1,...
    'FFTW_UNALIGNED',2,'FFTW_EXHAUSTIVE',8,'FFTW_PRESERVE_INPUT',16);

Larr  = [350 350   9   1];
aarr  = [ 10  10   9   1];
Marr  = [ 35  35   3   1];
Warr  = [  1   3   3   1];

for do_complex = 0:1
    complexstring = '';
    if do_complex, complexstring = 'complex'; end
    
    for idx = 1:numel(Larr)
        L = Larr(idx);
        W = Warr(idx);
        a = aarr(idx);
        M = Marr(idx);

        N = L/a;

        if do_complex
            g = randn(L,1,flags.complexity) + 1i*randn(L,1,flags.complexity);
            gin = complex2interleaved(g);
        else
            g = randn(L,1,flags.complexity);
            gin = g;
        end
        gPtr = libpointer(dataPtr,gin);
        
        c = cast(randn(M,N,W)+1i*randn(M,N,W),flags.complexity);
        cin = complex2interleaved(c);
        f = cast(randn(L,W)+1i*randn(L,W),flags.complexity);
        fout = complex2interleaved(f);
        fPtr = libpointer(dataPtr,fout);
        cinPtr = libpointer(dataPtr,cin);

        truef = idgt(c,g,a);

        funname = makelibraryname('idgt_long',flags.complexity,do_complex);
        status = calllib('libltfat',funname,cinPtr,gPtr,L,W,a,M,phaseconv.LTFAT_FREQINV,fPtr);

        res = norm(truef - interleaved2complex(fPtr.Value),'fro');
        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['IDGT FREQINV       L:%3i, W:%3i, a:%3i, M:%3i %s %s %s %s\n'],L,W,a,M,complexstring,flags.complexity,ltfatstatusstring(status),fail);

        truef = idgt(c,g,a,'timeinv');
        status = calllib('libltfat',funname,cinPtr,gPtr,L,W,a,M,phaseconv.LTFAT_TIMEINV,fPtr);

        res = norm(truef - interleaved2complex(fPtr.Value),'fro');
        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['IDGT TIMEINV       L:%3i, W:%3i, a:%3i, M:%3i %s %s %s %s\n'],L,W,a,M,complexstring,flags.complexity,ltfatstatusstring(status),fail);

        % With plan
        c = cast(randn(M,N,W)+1i*randn(M,N,W),flags.complexity);
        cin = complex2interleaved(c);
        cinPtr = libpointer(dataPtr,cin);
        f = cast(randn(L,W)+1i*randn(L,W),flags.complexity);
        fout = complex2interleaved(f);
        fPtr = libpointer(dataPtr,fout);

        plan = libpointer();
        funname = makelibraryname('idgt_long_init',flags.complexity,do_complex);
        statusInit = calllib('libltfat',funname,cinPtr,gPtr,L,W,a,M,fPtr,phaseconv.LTFAT_FREQINV,fftwflags.FFTW_MEASURE,plan);
        
        cinPtr = libpointer(dataPtr,cin);

        funname = makelibraryname('idgt_long_execute_newarray',flags.complexity,do_complex);
        statusExecute = calllib('libltfat',funname,plan,cinPtr,fPtr);

        funname = makelibraryname('idgt_long_done',flags.complexity,do_complex);
        statusDone = calllib('libltfat',funname,plan);

        truef = idgt(c,g,a);
        res = norm(truef - interleaved2complex(fPtr.Value),'fro');
        [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
        fprintf(['IDGT FREQINV WP    L:%3i, W:%3i, a:%3i, M:%3i %s %s %s %s\n'],L,W,a,M,complexstring,flags.complexity,ltfatstatusstring(status),fail);

        %%%%%%
        c = cast(randn(M,N,W)+1i*randn(M,N,W),flags.complexity);
        cin = complex2interleaved(c);
        cinPtr = libpointer(dataPtr,cin);
        f = cast(randn(L,W)+1i*randn(L,W),flags.complexity);
        fout = complex2interleaved(f);
        fPtr = libpointer(dataPtr,fout);

        plan = libpointer();
        funname = makelibraryname('idgt_long_init',flags.complexity,do_complex);
        statusInit = calllib('libltfat',funname,cinPtr,gPtr,L,W,a,M,fPtr,phaseconv.LTFAT_TIMEINV,fftwflags.FFTW_MEASURE,plan);
        
        cinPtr = libpointer(dataPtr,cin);

        funname = makelibraryname('idgt_long_execute_newarray',flags.complexity,do_complex);
        statusExecute = calllib('libltfat',funname,plan,cinPtr,fPtr);

        funname = makelibraryname('idgt_long_done',flags.complexity,do_complex);
        statusDone = calllib('libltfat',funname,plan);

        truef = idgt(c,g,a,'timeinv');
        res = norm(truef - interleaved2complex(fPtr.Value),'fro');
        [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
        fprintf(['IDGT TIMEINV WP    L:%3i, W:%3i, a:%3i, M:%3i %s %s %s %s\n'],L,W,a,M,complexstring,flags.complexity,ltfatstatusstring(status),fail);

        % With plan, new array
        c = cast(randn(M,N,W)+1i*randn(M,N,W),flags.complexity);
        cin = complex2interleaved(c);
        cinPtr = libpointer(dataPtr,cin);
        f = cast(randn(L,W)+1i*randn(L,W),flags.complexity);
        fout = complex2interleaved(f);
        fPtr = libpointer(dataPtr,fout);

        plan = libpointer();
        nullPtr = libpointer();
        funname = makelibraryname('idgt_long_init',flags.complexity,do_complex);
        statusInit = calllib('libltfat',funname,nullPtr,gPtr,L,W,a,M,nullPtr,phaseconv.LTFAT_FREQINV,fftwflags.FFTW_ESTIMATE,plan);

        funname = makelibraryname('idgt_long_execute_newarray',flags.complexity,do_complex);
        statusExecute = calllib('libltfat',funname,plan,cinPtr,fPtr);

        funname = makelibraryname('idgt_long_done',flags.complexity,do_complex);
        statusDone = calllib('libltfat',funname,plan);

        truef = idgt(c,g,a);
        res = norm(truef - interleaved2complex(fPtr.Value),'fro');
        [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
        fprintf(['IDGT FREQINV WP NA L:%3i, W:%3i, a:%3i, M:%3i %s %s %s %s\n'],L,W,a,M,complexstring,flags.complexity,ltfatstatusstring(status),fail);

        %%%%%%
        c = cast(randn(M,N,W)+1i*randn(M,N,W),flags.complexity);
        cin = complex2interleaved(c);
        cinPtr = libpointer(dataPtr,cin);
        f = cast(randn(L,W)+1i*randn(L,W),flags.complexity);
        fout = complex2interleaved(f);
        fPtr = libpointer(dataPtr,fout);

        plan = libpointer();
        funname = makelibraryname('idgt_long_init',flags.complexity,do_complex);
        statusInit = calllib('libltfat',funname,nullPtr,gPtr,L,W,a,M,nullPtr,phaseconv.LTFAT_TIMEINV,fftwflags.FFTW_ESTIMATE,plan);

        funname = makelibraryname('idgt_long_execute_newarray',flags.complexity,do_complex);
        statusExecute = calllib('libltfat',funname,plan,cinPtr,fPtr);

        funname = makelibraryname('idgt_long_done',flags.complexity,do_complex);
        statusDone = calllib('libltfat',funname,plan);

        truef = idgt(c,g,a,'timeinv');
        res = norm(truef - interleaved2complex(fPtr.Value),'fro');
        [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
        fprintf(['IDGT TIMEINV WP NA L:%3i, W:%3i, a:%3i, M:%3i %s %s %s %s\n'],L,W,a,M,complexstring,flags.complexity,ltfatstatusstring(status),fail);
    end
end


