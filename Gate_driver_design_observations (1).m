%% Gate driver design study

clear; close all; clc

%% inputs
% switch widths
W_sw_n = 50000;                  % um, low side NMOS
W_sw_p = 100000;                 % um, high side PMOS
Vswing = 0.9;                    % V, gate swing
f_list = [80 100 150 200] * 1e6; % Hz
f_ref  = 80e6;                   % Hz

% sweep
N_list       = 2:12;                   % inverters per driver
FO_last_list = [NaN 13 21.6 28 40];    % last stage FO (NaN = equal FO)
W1_n         = 1;                      % um
PN           = 2;                      % Wp/Wn

% our pick
use_pick = true;
N_pick   = 6;      % inverters per driver
FO_pick  = 21.6;   % last stage FO
if use_pick
    if ~ismember(N_pick, N_list), N_list = sort([N_list N_pick]); end
    if ~any(abs(FO_last_list - FO_pick) < 1e-9), FO_last_list(end+1) = FO_pick; end
end

% limits (placeholders, change these)
edge_max_ps   = 100;     % ps, max 10-90% edge
f_stage_max   = 12;      % max taper per stage
delay_budget  = 0.10;    % delay + edge as a fraction of the period at f_max
even_only     = true;    % even N only (output stays in phase)
k_edge        = 0;       % mW per ps of edge (from top_level_buck, 0 = ignore)

% bench values, 60 nm LVT, per 200 um
W_unit     = 200;          % um
Cgg_n_unit = 120e-15;      % F, NMOS
Ron_n_unit = 5.5;          % ohm, NMOS
Cgg_p_unit = 79e-15;       % F, PMOS
Ron_p_unit = 17.2;         % ohm, PMOS

% model params [Cpar s_n s_p k_slew]
par_ideal = [1.00 1.000 1.000 0.000];   % ideal
par_cal   = [3.88 0.528 0.440 0.556];   % fit to Spectre (gate_driver_chains_fit.m)

% old fixed-load benches, split over n chains
C_total_bench = 500e-12;   % F
W_bench_total = 50000;     % um, sum of last stages
% Spectre: [P_mW delay_up delay_dn rise fall] (ps)
% delays are rough cursor readings
meas_fo8  = [5.58  117 121 57.7 45.1];
meas_fo10 = [4.644 123 126 60.6 45.1];
meas_fo14 = [3.66  141 145 58.6 45.4];
meas_n6   = [4.288 NaN NaN NaN NaN];   % 6 stage, 50 pF
% switch-loaded bench, 4-stage chain, 100 MHz (assumes 1u/2u unit inverter)
meas_sw4_p    = [3.5  NaN NaN NaN NaN];   % PMOS driver only
meas_sw4_both = [6.45 NaN NaN NaN NaN];   % both drivers
tr_real       = 50e-12;                     % s, input rise time (50p on the pulse source)
% own bench, 80 MHz, 50 ps edge, M1-M6 = 1 4 19 86 378 1667 (delay is input rising)
Wm = [1; 4; 19; 86; 378; 1667];
meas_m_p    = [2.864 108.0 NaN NaN NaN];   % PMOS driver
meas_m_n    = [2.479 107.1 NaN NaN NaN];   % NMOS driver
meas_m_both = [5.343 NaN   NaN NaN NaN];   % both drivers

%% per-um values
p.cn  = Cgg_n_unit / W_unit;    % F/um
p.cp  = Cgg_p_unit / W_unit;    % F/um
p.Rn1 = Ron_n_unit * W_unit;    % ohm*um
p.Rp1 = Ron_p_unit * W_unit;    % ohm*um
p.Vs  = Vswing;
p.fsw = f_ref;
p.tin = 0.8 * 20e-12;           % s, input edge
Cin_um = p.cn + PN*p.cp;        % F/um (whole inverter)

C_n = p.cn * W_sw_n;            % F
C_p = p.cp * W_sw_p;            % F
Cl_d = [C_n C_p];
drv_name = {'NMOS driver (low side)', 'PMOS driver (high side)'};
fprintf('Switch gate load: NMOS %.1f pF, PMOS %.1f pF (total %.1f pF)\n', C_n*1e12, C_p*1e12, (C_n + C_p)*1e12);
fprintf('Gate switching alone, both drivers: %.2f mW at %.0f MHz, %.2f mW at %.0f MHz\n', ...
    Vswing^2*(C_n + C_p)*f_list(1)*1e3, f_list(1)/1e6, Vswing^2*(C_n + C_p)*f_list(end)*1e3, f_list(end)/1e6);

%% 1. validation
tin_bench = 0.8 * 20e-12;    % s
tin_sw4 = 0.8 * 100e-12;   % s, tr = 100 ps
cases = struct('name', {}, 'Wn', {}, 'Cl', {}, 'Cl2', {}, 'f', {}, 'tin', {}, 'meas', {}, 'Wn2', {});
nb = [8 10 14];
mb = {meas_fo8, meas_fo10, meas_fo14};
for j = 1:3
    Cl = C_total_bench / nb(j);
    Wl = (W_bench_total / nb(j)) / (1 + PN);
    tp = (Wl / W1_n)^(1/(nb(j) - 1));
    cases(end+1) = struct('name', sprintf('FO%d, %.1f pF, 80 MHz', nb(j), Cl*1e12), ...
        'Wn', W1_n * tp.^((0:nb(j)-1)'), 'Cl', Cl, 'Cl2', 0, 'f', 80e6, 'tin', tin_bench, 'meas', mb{j}, 'Wn2', []); %#ok<SAGROW>
end
tp = (W_bench_total / 10 / (1 + PN) / W1_n)^(1/5);
cases(end+1) = struct('name', 'N6, 50 pF, 80 MHz', 'Wn', W1_n * tp.^((0:5)'), ...
    'Cl', 50e-12, 'Cl2', 0, 'f', 80e6, 'tin', tin_bench, 'meas', meas_n6, 'Wn2', []);
cases(end+1) = struct('name', '4-stage, PMOS, 100 MHz', 'Wn', [1; 10; 100; 1000], ...
    'Cl', C_p, 'Cl2', 0, 'f', 100e6, 'tin', tin_sw4, 'meas', meas_sw4_p, 'Wn2', []);
cases(end+1) = struct('name', '4-stage, both, 100 MHz', 'Wn', [1; 10; 100; 1000], ...
    'Cl', C_p, 'Cl2', C_n, 'f', 100e6, 'tin', tin_sw4, 'meas', meas_sw4_both, 'Wn2', []);

cases(end+1) = struct('name', 'M-chain, PMOS, 80 MHz', 'Wn', Wm, 'Cl', C_p, 'Cl2', 0, ...
    'f', 80e6, 'tin', 0.8*tr_real, 'meas', meas_m_p, 'Wn2', []);
cases(end+1) = struct('name', 'M-chain, NMOS, 80 MHz', 'Wn', Wm, 'Cl', C_n, 'Cl2', 0, ...
    'f', 80e6, 'tin', 0.8*tr_real, 'meas', meas_m_n, 'Wn2', []);
cases(end+1) = struct('name', 'M-chain, both, 80 MHz', 'Wn', Wm, 'Cl', C_n, 'Cl2', C_p, ...
    'f', 80e6, 'tin', 0.8*tr_real, 'meas', meas_m_both, 'Wn2', Wm);
nCase = numel(cases);

qnames = {'power (mW)', 'delay up (ps)', 'delay dn (ps)', 'edge rise (ps)', 'edge fall (ps)'};
Vi = zeros(nCase, 5);  Vc = zeros(nCase, 5);  Vm = zeros(nCase, 5);
for c = 1:nCase
    Vi(c,:) = case_model(cases(c), p, par_ideal, PN);
    Vc(c,:) = case_model(cases(c), p, par_cal,   PN);
    Vm(c,:) = cases(c).meas;
end
fprintf('\nIdeal vs calibrated vs Cadence (error = model / Cadence - 1):\n');
fprintf('%-32s %-16s %9s %9s %9s %8s %8s\n', 'case', 'quantity', 'ideal', 'calib.', 'Cadence', 'err ideal', 'err cal');
for c = 1:nCase
    for q = 1:5
        if ~isnan(Vm(c,q))
            fprintf('%-32s %-16s %9.2f %9.2f %9.2f %+8.1f%% %+7.1f%%\n', cases(c).name, qnames{q}, ...
                Vi(c,q), Vc(c,q), Vm(c,q), 100*(Vi(c,q)/Vm(c,q) - 1), 100*(Vc(c,q)/Vm(c,q) - 1));
        end
    end
end
fprintf('Note: the 4-stage rows use stage sizes 1/10/100/1000 times a 1 um / 2 um unit inverter (assumed), and were not used in the fit.\n');

%% 2. sweep
nN = numel(N_list);  nF = numel(FO_last_list);
Dc = zeros(nN, nF, 2);  Di = Dc;  Ed = Dc;  P80 = Dc;  Ft = Dc;  Ar = Dc;
for d = 1:2
    for i = 1:nN
        for k = 1:nF
            Wn = design_widths(N_list(i), FO_last_list(k), Cl_d(d), W1_n, PN, p);
            mc = chain_from_widths(Wn, PN, Cl_d(d), p, par_cal);
            mi = chain_from_widths(Wn, PN, Cl_d(d), p, par_ideal);
            Dc(i,k,d)  = 0.5 * (mc.T_inrise + mc.T_infall) * 1e12;   % ps
            Di(i,k,d)  = 0.5 * (mi.T_inrise + mi.T_infall) * 1e12;
            Ed(i,k,d)  = max(mc.edge_rise, mc.edge_fall) * 1e12;     % ps
            P80(i,k,d) = mc.Ptotal * 1e3;                            % mW at f_ref
            Ft(i,k,d)  = Wn(2) / Wn(1);
            Ar(i,k,d)  = sum(Wn) * (1 + PN);                         % um, total device width
        end
    end
end
Ptot80 = P80(:,:,1) + P80(:,:,2);              % mW, both drivers at f_ref
Emax   = max(Ed(:,:,1), Ed(:,:,2));            % ps
flab   = arrayfun(@(x) sprintf('FO_{last} = %g', x), FO_last_list, 'UniformOutput', false);
flab(isnan(FO_last_list)) = {'equal fan-out'};

%% 3. selection
fmax = max(f_list);
feas = false(nN, nF);
for i = 1:nN
    for k = 1:nF
        ok = (~even_only) || (mod(N_list(i), 2) == 0);
        for d = 1:2
            ok = ok && (Ed(i,k,d) <= edge_max_ps) && (Ft(i,k,d) <= f_stage_max) && ...
                 ((Dc(i,k,d) + Ed(i,k,d)) <= delay_budget * 1e12 / fmax);
        end
        feas(i,k) = ok;
    end
end
Cost = Ptot80 + k_edge * Emax;           % mW, driver power + edge penalty
Pm = Cost;  Pm(~feas) = Inf;
[~, order] = sort(Pm(:));
nShow = min(5, nnz(feas));
fprintf('\nLimits: edge <= %g ps, taper <= %g, delay + edge <= %.0f%% of the period at %.0f MHz, even N = %d\n', ...
    edge_max_ps, f_stage_max, 100*delay_budget, fmax/1e6, even_only);
if nShow == 0 && ~use_pick
    fprintf('No design meets all limits. Relax edge_max_ps or f_stage_max.\n');
    return
end
if nShow > 0
    fprintf('Lowest-cost designs that meet them (cost = power of both drivers at %.0f MHz + k_edge * edge, k_edge = %g):\n', f_ref/1e6, k_edge);
    fprintf('%4s %5s %9s %10s %10s %9s %9s %11s\n', 'rank', 'N', 'FO_last', 'taper_N/P', 'delay_N/P', 'edge_max', 'P(mW)', 'width(mm)');
    for r = 1:nShow
        [ii, kk] = ind2sub(size(Pm), order(r));
        fprintf('%4d %5d %9s %5.1f/%4.1f %5.0f/%4.0f %9.0f %9.2f %11.1f\n', r, N_list(ii), ...
            fo_str(FO_last_list(kk)), Ft(ii,kk,1), Ft(ii,kk,2), Dc(ii,kk,1), Dc(ii,kk,2), Emax(ii,kk), ...
            Ptot80(ii,kk), (Ar(ii,kk,1) + Ar(ii,kk,2)) / 1e3);
    end
end
if use_pick
    bi = find(N_list == N_pick, 1);
    bk = find(abs(FO_last_list - FO_pick) < 1e-9, 1);
    fprintf('\nSelected by the team: N = %d, FO_last = %s\n', N_list(bi), fo_str(FO_last_list(bk)));
    if feas(bi,bk)
        fprintf('  Meets all limits. Power rank among passing designs: %d of %d\n', ...
            find(order == sub2ind(size(Pm), bi, bk)), nnz(feas));
    else
        fprintf('  Does NOT meet every limit:\n');
        for d = 1:2
            fprintf('    %s: edge %.0f ps (limit %g), taper %.1f (limit %g), delay + edge %.0f ps (limit %.0f)\n', ...
                drv_name{d}, Ed(bi,bk,d), edge_max_ps, Ft(bi,bk,d), f_stage_max, ...
                Dc(bi,bk,d) + Ed(bi,bk,d), delay_budget*1e12/fmax);
        end
    end
    if nnz(feas) > 0
        [~, ib] = min(Pm(:));  [i0, k0] = ind2sub(size(Pm), ib);
        fprintf('  Lowest-cost passing design: N = %d, FO_last = %s, %.2f mW (selected: %.2f mW)\n', ...
            N_list(i0), fo_str(FO_last_list(k0)), Ptot80(i0,k0), Ptot80(bi,bk));
    end
else
    [bi, bk] = ind2sub(size(Pm), order(1));
    fprintf('\nSelected: N = %d, FO_last = %s\n', N_list(bi), fo_str(FO_last_list(bk)));
end
Wsel = cell(1,2);
for d = 1:2
    Wsel{d} = design_widths(N_list(bi), FO_last_list(bk), Cl_d(d), W1_n, PN, p);
    fprintf('  %s: load %.1f pF, last stage Wn + Wp = %.0f um, M list (m = Wn / %g um): %s\n', ...
        drv_name{d}, Cl_d(d)*1e12, Wsel{d}(end)*(1 + PN), W1_n, mat2str(round(Wsel{d}' / W1_n)));
end
fprintf('  Power of both drivers: ');
for f = f_list, fprintf('%.2f mW at %.0f MHz   ', Ptot80(bi,bk) * f / f_ref, f/1e6); end
fprintf('\n  Delay + edge as a share of the period: ');
tsel = max(Dc(bi,bk,:) + Ed(bi,bk,:)) * 1e-12;
for f = f_list, fprintf('%.1f%% at %.0f MHz   ', 100*tsel*f, f/1e6); end
fprintf('\n  Delay mismatch between the two drivers: %.1f ps\n', abs(Dc(bi,bk,1) - Dc(bi,bk,2)));

% M lists for Cadence
Nsel = N_list(bi);
Mcsv = [(1:Nsel)', round(Wsel{1} / W1_n), round(Wsel{2} / W1_n)];
writetable(array2table(Mcsv, 'VariableNames', {'Stage', 'M_NMOS_driver', 'M_PMOS_driver'}), 'gate_driver_design_M.csv');

%% fig 1: trade-offs
cols = lines(nF);
figure('Name', 'Design trade-offs', 'Position', [50 50 1300 800]);

subplot(2,2,1)
h = gobjects(1, nF);
for k = 1:nF
    h(k) = plot(N_list, Dc(:,k,2), 'o-', 'LineWidth', 2, 'Color', cols(k,:)); hold on
    plot(N_list, Di(:,k,2), '--', 'LineWidth', 1, 'Color', cols(k,:));
end
plot(N_list(bi), Dc(bi,bk,2), 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
hold off; grid on; xlabel('Inverters N'); ylabel('Chain delay (ps)'); ylim([0 250])
legend(h, flab, 'Location', 'northeast'); title('PMOS driver delay (solid = calibrated, dashed = ideal, star = selected)')

subplot(2,2,2)
for k = 1:nF
    plot(N_list, Ptot80(:,k), 'o-', 'LineWidth', 2, 'Color', cols(k,:)); hold on
end
plot(N_list(bi), Ptot80(bi,bk), 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
yline(Vswing^2 * (C_n + C_p) * f_ref * 1e3, 'k--', 'gate only');
hold off; grid on; xlabel('Inverters N'); ylabel(sprintf('Power, both drivers, %.0f MHz (mW)', f_ref/1e6))
legend(flab, 'Location', 'northwest'); title('Power vs stages and last-stage fan-out')

subplot(2,2,3)
NN = repmat(N_list(:), 1, nF);
scatter(Emax(:), Ptot80(:), 40, NN(:), 'filled'); hold on
plot(Emax(bi,bk), Ptot80(bi,bk), 'rp', 'MarkerSize', 16, 'MarkerFaceColor', 'r');
xline(edge_max_ps, 'k--', 'edge limit'); hold off; grid on; colorbar
xlabel('Largest gate edge, 10-90% (ps)'); ylabel(sprintf('Power at %.0f MHz (mW)', f_ref/1e6))
title('Power vs edge (color = N, star = selected)')

subplot(2,2,4)
scatter(reshape(Ft(:,:,2), [], 1), reshape(Dc(:,:,2), [], 1), 40, NN(:), 'filled'); hold on
plot(Ft(bi,bk,2), Dc(bi,bk,2), 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
xline(f_stage_max, 'k--', 'taper limit'); hold off; grid on; colorbar; xlim([0 30]); ylim([0 250])
xlabel('Taper between stages f (PMOS driver)'); ylabel('Chain delay (ps)')
title('Delay vs per-stage fan-out (color = N, star = selected)')

%% fig 2: frequency
alt = struct('label', {}, 'WN', {}, 'WP', {});
alt(1).label = sprintf('selected: N%d, FO_{last} %s', Nsel, fo_str(FO_last_list(bk)));
alt(1).WN = Wsel{1};  alt(1).WP = Wsel{2};
alt(2).label = 'N6, FO_{last} 28';
alt(2).WN = design_widths(6, 28, C_n, W1_n, PN, p);  alt(2).WP = design_widths(6, 28, C_p, W1_n, PN, p);
alt(3).label = 'N6, equal fan-out';
alt(3).WN = design_widths(6, NaN, C_n, W1_n, PN, p); alt(3).WP = design_widths(6, NaN, C_p, W1_n, PN, p);
alt(4).label = '4-stage 1/10/100/1000';
alt(4).WN = [1; 10; 100; 1000];  alt(4).WP = [1; 10; 100; 1000];
fp = linspace(f_list(1), fmax, 13);
Palt = zeros(numel(alt), 1);  Talt = zeros(numel(alt), 1);
for a = 1:numel(alt)
    mN = chain_from_widths(alt(a).WN, PN, C_n, p, par_cal);
    mP = chain_from_widths(alt(a).WP, PN, C_p, p, par_cal);
    Palt(a) = (mN.Ptotal + mP.Ptotal) * 1e3;                      % mW at f_ref
    Talt(a) = max([0.5*(mN.T_inrise + mN.T_infall) + max(mN.edge_rise, mN.edge_fall), ...
                   0.5*(mP.T_inrise + mP.T_infall) + max(mP.edge_rise, mP.edge_fall)]);   % s
end
figure('Name', 'Frequency', 'Position', [100 100 1200 450]);
subplot(1,2,1)
for a = 1:numel(alt), plot(fp/1e6, Palt(a) * fp / f_ref, 'o-', 'LineWidth', 2); hold on; end
plot(fp/1e6, Vswing^2 * (C_n + C_p) * fp * 1e3, 'k--', 'LineWidth', 1.5);
hold off; grid on; xlabel('Switching frequency (MHz)'); ylabel('Power, both drivers (mW)')
legend([{alt.label}, {'gate only'}], 'Location', 'northwest'); title('Driver power vs frequency')
subplot(1,2,2)
for a = 1:numel(alt), plot(fp/1e6, 100 * Talt(a) * fp, 'o-', 'LineWidth', 2); hold on; end
hold off; grid on; xlabel('Switching frequency (MHz)'); ylabel('Delay + edge, % of the period')
legend({alt.label}, 'Location', 'northwest'); title('Timing share of the period')

%% fig 3: optimal fan-out
gam = linspace(0.1, 6, 60);
fopt = arrayfun(@(g) fzero(@(x) x .* (log(x) - 1) - g, [exp(1) 60]), gam);
fo_ideal = fzero(@(x) x .* (log(x) - 1) - par_ideal(1), [exp(1) 60]);
fo_cal   = fzero(@(x) x .* (log(x) - 1) - par_cal(1),   [exp(1) 60]);
figure('Name', 'Optimal fan-out', 'Position', [150 150 1100 450]);
subplot(1,2,1)
plot(gam, fopt, 'LineWidth', 2); hold on
plot(par_ideal(1), fo_ideal, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 9);
plot(par_cal(1),   fo_cal,   'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 9);
hold off; grid on; xlabel('Self-loading Cpar (Cint / Cin)'); ylabel('Delay-optimal fan-out per stage')
legend('f_{opt}', sprintf('ideal model (%.1f)', fo_ideal), sprintf('calibrated (%.1f)', fo_cal), 'Location', 'northwest')
title('Optimal fan-out grows with self-loading')
subplot(1,2,2)
fv = linspace(1.8, 20, 200);
plot(fv, (par_ideal(1) + fv) ./ log(fv), 'b', 'LineWidth', 2); hold on
plot(fv, (par_cal(1) + fv) ./ log(fv), 'r', 'LineWidth', 2);
xline(2.7, ':', 'N10'); xline(4.4, ':', 'N6'); xline(10, ':', 'fan-out 10');
hold off; grid on; ylim([0 12]); xlabel('Fan-out per stage f'); ylabel('Delay / ln F  (units of t_{inv})')
legend('ideal (Cpar 1)', sprintf('calibrated (Cpar %.1f)', par_cal(1)), 'Location', 'north'); title('Delay vs fan-out')

%% fig 4: ideal vs Cadence power
figure('Name', 'Ideal vs Cadence', 'Position', [200 200 1100 450]);
ip = find(~isnan(Vm(:,1)));           % cases with a measured power
bar([Vi(ip,1) Vc(ip,1) Vm(ip,1)]); grid on
set(gca, 'XTick', 1:numel(ip), 'XTickLabel', {cases(ip).name}); xtickangle(25)
ylabel('Power (mW)'); legend('ideal model', 'calibrated model', 'Cadence', 'Location', 'northeast')
title('Driver power: model vs Cadence')

%% fig 5: design maps
FO_fine = 6:1:60;
Ng = N_list;
Dmap = zeros(numel(FO_fine), numel(Ng));  Emap = Dmap;  Pmap = Dmap;  Fmap = Dmap;
for a = 1:numel(FO_fine)
    for b = 1:numel(Ng)
        Wn_n = design_widths(Ng(b), FO_fine(a), C_n, W1_n, PN, p);
        Wn_p = design_widths(Ng(b), FO_fine(a), C_p, W1_n, PN, p);
        mn = chain_from_widths(Wn_n, PN, C_n, p, par_cal);
        mp = chain_from_widths(Wn_p, PN, C_p, p, par_cal);
        Dmap(a,b) = 1e12 * max(0.5*(mn.T_inrise + mn.T_infall), 0.5*(mp.T_inrise + mp.T_infall));
        Emap(a,b) = 1e12 * max([mn.edge_rise mn.edge_fall mp.edge_rise mp.edge_fall]);
        Pmap(a,b) = 1e3 * (mn.Ptotal + mp.Ptotal);
        Fmap(a,b) = max(Wn_n(2)/Wn_n(1), Wn_p(2)/Wn_p(1));
    end
end
Cmap = Pmap + k_edge * Emap;
figure('Name', 'Design maps', 'Position', [250 100 1300 800]);
maps  = {min(Dmap, 300), Emap, Pmap, Cmap};
mttl  = {'Chain delay (ps, clipped at 300)', 'Largest gate edge (ps)', ...
         sprintf('Power, both drivers, %.0f MHz (mW)', f_ref/1e6), ...
         sprintf('Cost = power + k_{edge} * edge (k_{edge} = %g)', k_edge)};
for m_i = 1:4
    subplot(2,2,m_i)
    contourf(Ng, FO_fine, maps{m_i}, 15); colorbar; hold on
    contour(Ng, FO_fine, Emap, [edge_max_ps edge_max_ps], 'k', 'LineWidth', 2);
    contour(Ng, FO_fine, Fmap, [f_stage_max f_stage_max], 'r--', 'LineWidth', 2);
    plot(N_list(bi), FO_last_list(bk), 'wp', 'MarkerFaceColor', 'w', 'MarkerSize', 14);
    hold off; xlabel('Inverters N'); ylabel('Last-stage fan-out FO_{last}'); title(mttl{m_i})
end
sgtitle('Black = edge limit, red dashed = taper limit, star = selected (both drivers)')

%% functions
function Wn = design_widths(N, FO_last, Cl, W1, PN, p)
    Cin_um = p.cn + PN*p.cp;
    if isnan(FO_last)
        f = (Cl / (Cin_um * W1))^(1/N);          % equal FO
    else
        Wl = Cl / (FO_last * Cin_um);            % um
        f  = (Wl / W1)^(1/(N - 1));
    end
    Wn = W1 * f.^((0:N-1)');
end

function s = fo_str(x)
    if isnan(x), s = 'equal'; else, s = sprintf('%g', x); end
end

function [v, P] = case_model(c, p, par, PN)
    p.tin = c.tin;                           % bench input edge
    m = chain_from_widths(c.Wn, PN, c.Cl, p, par);
    P = m.Ptotal * c.f / p.fsw;
    if c.Cl2 > 0
        W2 = c.Wn;  if ~isempty(c.Wn2), W2 = c.Wn2; end
        m2 = chain_from_widths(W2, PN, c.Cl2, p, par);
        P = P + m2.Ptotal * c.f / p.fsw;
    end
    v = [P*1e3, m.T_inrise*1e12, m.T_infall*1e12, m.edge_rise*1e12, m.edge_fall*1e12];
end

function m = chain_from_widths(Wn, PN, Cload, p, par)
    Cpar = par(1); sn = par(2); sp = par(3); ks = par(4);
    Wn  = Wn(:);
    N   = numel(Wn);
    odd = mod((1:N)', 2) == 1;
    Wp  = PN * Wn;
    Cin = (p.cn + PN*p.cp) * Wn;             % input cap of each stage
    Cself = Cpar * Cin;                      % self load
    Cnext = [Cin(2:end); Cload];             % what each stage drives
    Cout  = Cself + Cnext;
    Rn = sn * p.Rn1 ./ Wn;                   % ohm
    Rp = sp * p.Rp1 ./ Wp;                   % ohm
    R_up = Rn .* odd + Rp .* ~odd;           % input rising: odd stages pull down
    R_dn = Rp .* odd + Rn .* ~odd;
    tau_up = R_up .* Cout;   t_up = 2.2 * tau_up;     % 10-90% edge of each stage output
    tau_dn = R_dn .* Cout;   t_dn = 2.2 * tau_dn;
    d_up = 0.69 * tau_up + ks * [p.tin; t_up(1:end-1)];   % 50% delay incl. input slew
    d_dn = 0.69 * tau_dn + ks * [p.tin; t_dn(1:end-1)];
    m.T_inrise = sum(d_up);
    m.T_infall = sum(d_dn);
    if mod(N,2) == 0
        m.edge_rise = t_up(end);  m.edge_fall = t_dn(end);
    else
        m.edge_rise = t_dn(end);  m.edge_fall = t_up(end);
    end
    m.Ptotal = p.Vs^2 * p.fsw * sum(Cout);   % each stage charges its output
    m.Cin1   = Cin(1);
end
