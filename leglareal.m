function [f,relres,iter,c]=leglareal(s,g,a,M,varargin)
%LEGLAREAL Le Rouxs Griffin-Lim Algorithm for real signals
%   Usage: f = leglareal(s,g,a,M)
%          f = leglareal(s,g,a,M,Ls)
%          [f,relres,iter,c] = leglareal(...)
%
%   Input parameters:
%         s       : Array of initial coefficients.
%         g       : Analysis Gabor window
%         a       : Hop factor
%         M       : Number of channels
%         Ls      : length of signal.
%   Output parameters:
%         f       : Signal.
%         relres  : Vector of residuals.
%         iter    : Number of iterations done.
%         c       : Coefficients with the reconstructed phase
%
%   `leglareal(s,g,a,M)` attempts to find a signal *f* with has *s* as
%   the abs. value of the Gabor coefficients such as::
%
%     s = abs(dgtreal(f,g,a,M));
%
%   using Le Rouxs modifications of the Griffin-Lim algorithm.
%
%   `[f,relres,iter,c]=leglareal(...)` additionally returns an array
%   of residuals `relres`, the number of iterations done `iter` and the
%   coefficients *c* with the reconstructed phase. The relationship between
%   *f* and *c* is::
%
%     f = idgtreal(c,gd,a,M)
%
%   where *gd* is the canonical dual window obtained by |gabdual|.
%
%   `leglareal` takes the following additional parameters:
%
%   Initial phase guess:
%
%     'input'      Choose the starting phase as the phase of the input
%                  *s*. This is the default
%
%     'zero'       Choose a starting phase of zero.
%
%     'rand'       Choose a random starting phase.
%
%   Variant of the algorithm:
%
%     'trunc'      The projection kernel is used directly.
%                  This is the default.
%
%     'modtrunc'   Modified phase update is done by setting the central
%                  sample of the projection kernel to zero.
%
%   Phase update scheme:
%
%     'stepwise'   Phase is updated only after the whole projection has
%                  been made.
%                  This is the default.
%
%     'onthefly'   The phase is updated for each coefficient immediatelly.
%
%   Algorithm acceleration:
%
%     'legla'      The original Giffin-Lim iteration scheme.
%                  This is the default.
%
%     'flegla'     A fast Griffin-Lim iteration scheme from the 2nd
%                  reference.
%
%     'alpha',a    Parameter of the Fast Griffin-Lim algorithm. It is
%                  ignored if not used together with 'flegla' flag.
%
%   Other:
%
%     'tol',t      Stop if relative residual error is less than the
%                  specified tolerance.
%
%     'maxit',n    Do at most n iterations.
%
%     'print'      Display the progress.
%
%     'quiet'      Don't print anything, this is the default.
%
%     'printstep',p  If 'print' is specified, then print every p'th
%                    iteration. Default value is p=10;
%
%   !!!!!!!!!!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!
%   This function requires LTFAT 2.1.2 and above.
%   !!!!!!!!!!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!
%
%   See also:  idgtreal, dgtreal
%
%   References:
%
%   Le Roux J., Kameoka H., Ono N., Sagayama S.: Fast Signal Reconstruction
%   from magnitude STFT Spectrogram Based on Spectrogram Consistency,
%   DAFx-10, Graz, Austria, September 6-10, 2010
%
%   Perraudin N., Balazs P., Søndergaard P. L.: A fast Griffin-Lim algorithm.
%   In Applications of Signal Processing to Audio and Acoustics (WASPAA),
%   2013 IEEE Workshop on, pages 1-4, Oct 2013.
%

%   AUTHOR: Zdenek Prusa

[~,N,W] = size(s);
L = N*a;

definput.keyvals.Ls=[];
definput.keyvals.tol=1e-6;
definput.keyvals.maxit=100;
definput.flags.startphase={'input','zero','rand'};
definput.flags.algvariant={'trunc','modtrunc'};
definput.flags.updatescheme={'stepwise','onthefly'};
definput.flags.method={'legla','flegla'};
definput.keyvals.alpha=0.99;
definput.flags.print={'quiet','print'};
definput.flags.phase={'freqinv','timeinv'};
definput.keyvals.relthr = 0.1;
definput.keyvals.kernsize = [];
definput.keyvals.printstep=10;

[flags,kv,Ls]=ltfatarghelper({'Ls','tol','maxit'},definput,varargin);


if flags.do_input
    % Start with the phase given by the input.
    c=s;
end;

if flags.do_zero
    % Start with a phase of zero.
    c=abs(s);
end;

if flags.do_rand
    c=abs(s).*exp(2*pi*1i*rand(size(s)));
end;

s = abs(s);

% For normalization purposes
norm_s=norm(s,'fro');

relres=zeros(kv.maxit,1);

gnum = gabwin(g,a,M,L);
gd = gabdual(g,a,M,L);

projfncBase = @(c) dgt(idgt(c,gd,a,flags.phase),g,a,M,flags.phase);
ctmp = zeros(M,N); ctmp(1) = 1;
kern = projfncBase(ctmp);
clear ctmp;

if isempty(kv.kernsize)
    kv.kernsize = [2*ceil(M/a)-1,2*ceil(M/a)-1];
else
    if ~isnumeric(kv.kernsize) || numel(kv.kernsize)~=2
        error('%s: Kernel size must be a 2 element vector.',upper(mflename));
    end
    if any(mod(kv.kernsize,2)==0)
        error('%s: Kernel size must be odd.',upper(mfilename));
    end
    if any(kv.kernsize<=0)
        error('%s: Invalid kernel size.',upper(mfilename));
    end
end

projfnc = @(c) comp_dgtreal(comp_idgtreal(c,gd,a,M,[0 1],flags.do_timeinv),gnum,a,M,[0 1],flags.do_timeinv);


if flags.do_modtrunc
    kern(1,1) = 0;
end

kernsmall = middlepad2(kern,kv.kernsize);
kernsmall = fftshift(involute2(kernsmall));

if flags.do_legla
    for iter=1:kv.maxit
        % We do the projection explicitly as the comp_leglaupdatereal
        % returns something different
        if nargout>1
            cproj = projfnc(c);
            relres(iter)=norm(abs(cproj)-s,'fro')/norm_s;
        end

        c = comp_leglaupdatereal(c,kernsmall,s,a,M,flags.do_onthefly);

        if relres(iter)<kv.tol
            relres=relres(1:iter);
            break;
        end;

        if flags.do_print
            if mod(iter,kv.printstep)==0
                fprintf('LEGLA: Iteration %i, residual = %f.\n',iter,relres(iter));
            end
        end
    end
elseif flags.do_flegla
    told=c;
    for iter=1:kv.maxit
        % We do the projection explicitly as the comp_leglaupdatereal
        % returns something different
        if nargout>1
            cproj = projfnc(c);
            relres(iter)=norm(abs(cproj)-s,'fro')/norm_s;
        end

        tnew = comp_leglaupdatereal(c,kernsmall,s,a,M,flags.do_onthefly);
        c = tnew + kv.alpha*(tnew-told);

        if relres(iter)<kv.tol
            relres=relres(1:iter);
            break;
        end;

        if flags.do_print
            if mod(iter,kv.printstep)==0
                fprintf('LEGLA: Iteration %i, residual = %f.\n',iter,relres(iter));
            end
        end

        told = tnew;
    end
end

f = idgtreal(c,gd,a,M,Ls,flags.phase);
f = comp_sigreshape_post(f,Ls,0,[0; W]);

function f=involute2(f)
f = involute(f,1);
f = conj(involute(f,2));

function f=middlepad2(f,L,varargin)
f = middlepad(f,L(1),1,varargin{:});
f = middlepad(f,L(2),2,varargin{:});