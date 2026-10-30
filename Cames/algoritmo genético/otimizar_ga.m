%% otimizar_ga.m - otimiza V, a, l do quadrupede (sim_pre.slx) com algoritmo genetico
% Minimiza J = -dx/D_ref + P_f*I_f: andar o maximo possivel em +X sem cair.
% Ajustes em config_ga.m. Arquivos: ga_real (GA), avaliar_populacao (simulacoes),
% entrada_simulacao (V, a, l -> w, a, l no modelo), custo_quadrupede (funcao custo),
% painel_ga (graficos ao vivo durante o treinamento).
clear; close all; clc
cfg = config_ga();
addpath(cfg.pasta_modelo);

%% 1) Conferencias antes de gastar tempo simulando
% os workers do parsim abrem o .slx do disco: alteracoes nao salvas seriam ignoradas
if bdIsLoaded(cfg.modelo) && strcmp(get_param(cfg.modelo, 'Dirty'), 'on')
    error('Salve o %s.slx antes de rodar o GA (os workers usam o arquivo do disco).', cfg.modelo);
end
load_system(cfg.modelo);
for b = 1:size(cfg.blocos, 1)
    blk = [cfg.modelo '/' cfg.blocos{b,1}];
    if getSimulinkBlockHandle(blk) < 0
        error('Bloco "%s" nao existe no modelo: corrija cfg.blocos em config_ga.m.', strrep(blk, newline, ' '));
    end
end
if cfg.paralelo && isempty(gcp('nocreate'))
    parpool('Processes', [1 cfg.n_workers]);      % aceita menos workers se o perfil limitar
end

%% 2) Algoritmo genetico
R = ga_real(@(X) avaliar_populacao(X, cfg), cfg);

%% 3) Melhor individuo de todas as geracoes
Xall = vertcat(R.X);  Jall = vertcat(R.J);  rall = vertcat(R.res);
[Jmin, k] = min(Jall);
x = Xall(k,:);  best = rall(k);
V = x(1);  w = cfg.k_motor*V;  a = x(2);  l = x(3);   % ficam no workspace para simular o modelo
fprintf('\nMelhor: V = %.2f V -> w = %.2f rad/s (%.2f Hz)  a = %.3f rad (%.1f graus)  l = %.1f mm\n', ...
        V, w, w/(2*pi), a, rad2deg(a), l);
fprintf('        J = %.4f   dx = %.1f mm   queda: %s   l*sin(a) = %.1f mm (max %.1f)\n', ...
        Jmin, best.dx, best.motivo, l*sin(a), cfg.passo_max);
fprintf('        %d individuos, %d simulados, %.1f min\n', numel(Jall), ...
        sum([rall.motivo] ~= "colisao"), sum([R.tempo])/60);

%% 4) Graficos
ger = 1:numel(R);
figure('Color','w','Position',[80 80 1100 700]);
subplot(2,2,1);
plot(ger, arrayfun(@(r) min(r.J), R), 'o-', ger, arrayfun(@(r) median(r.J), R), 's--');
grid on; xlabel('geracao'); ylabel('J'); legend('melhor','mediana'); title('Convergencia');

subplot(2,2,2);
plot(best.hist.t, best.hist.px - best.hist.px(1), 'LineWidth', 1.5); grid on;
if best.queda, xline(best.t_queda, 'r--', 'queda'); end
xlabel('t [s]'); ylabel('x - x_0 [mm]'); title('Deslocamento em X (melhor)');

subplot(2,2,3);
yyaxis left;  plot(best.hist.t, best.hist.h); ylabel('altura do corpo h [mm]');
yline(best.h_min, ':', 'h_{min}');
yyaxis right; plot(best.hist.t, best.hist.roll, best.hist.t, best.hist.pitch);
ylabel('[graus]'); grid on; xlabel('t [s]'); legend('h','h_{min}','roll','pitch');
title('Criterios de queda (melhor)');

subplot(2,2,4);
caiu = [rall.queda]';  col = [rall.motivo]' == "colisao";  bom = ~caiu & ~col;
scatter(Xall(bom,2), Xall(bom,3), 40, Jall(bom), 'filled'); hold on;
plot(Xall(caiu,2), Xall(caiu,3), 'kx', Xall(col,2), Xall(col,3), '.', 'Color', [.6 .6 .6]);
aa = linspace(cfg.lb(2), cfg.ub(2), 100);
plot(aa, cfg.passo_max./sin(aa), 'r-', 'LineWidth', 1.2);       % fronteira l*sin(a) = passo_max
plot(a, l, 'rp', 'MarkerSize', 16, 'MarkerFaceColor', 'r');
axis([cfg.lb(2) cfg.ub(2) cfg.lb(3) cfg.ub(3)]); colorbar; grid on;
xlabel('a [rad]'); ylabel('l [mm]');
title('cor = J, x = caiu, cinza = pes se cruzam');

%% 5) Ver o melhor andando no Mechanics Explorer
in = entrada_simulacao(x, cfg);
in = in.setModelParameter('SimMechanicsOpenEditorOnUpdate', 'on');
sim(in);
