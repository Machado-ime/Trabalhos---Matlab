function painel_ga(R, cfg)
%% painel_ga.m - painel ao vivo do GA, redesenhado ao fim de cada geracao (cfg.painel)
% Com cfg.ver_melhor = true, cada vez que surge um novo melhor individuo ele e
% simulado de novo aqui no cliente com o Mechanics Explorer aberto (cada animacao
% atrasa o GA no tempo de uma simulacao).

g    = numel(R);
Xall = vertcat(R.X);  Jall = vertcat(R.J);  rall = vertcat(R.res);
ger  = repelem(1:g, arrayfun(@(r) numel(r.J), R))';    % geracao de cada individuo (coluna)
[Jb, kb] = min(Jall);  xb = Xall(kb,:);  best = rall(kb);
col  = [rall.motivo]' == "colisao";  caiu = [rall.queda]';  atual = ger == g;

f = findobj('Type', 'figure', 'Tag', 'painel_ga');
if isempty(f)
    f = figure('Tag', 'painel_ga', 'Name', 'GA ao vivo', 'Color', 'w', 'Position', [60 60 1150 720]);
end
clf(f);
t = tiledlayout(f, 2, 2, 'TileSpacing', 'compact');
title(t, sprintf('Geracao %d de %d   |   melhor J = %.3f, dx = %.0f mm   |   V = %.2f V, a = %.3f rad, l = %.1f mm', ...
      g, cfg.n_ger, Jb, best.dx, xb));

% 1) convergencia
ax = nexttile(t);
plot(ax, 1:g, arrayfun(@(r) min(r.J), R), 'o-', 1:g, arrayfun(@(r) median(r.J), R), 's--');
xlim(ax, [0.5 max(cfg.n_ger, 2) + 0.5]);  grid(ax, 'on');
xlabel(ax, 'geracao');  ylabel(ax, 'J');  legend(ax, 'melhor', 'mediana');  title(ax, 'Convergencia');

% 2) plano a x l: geracao atual colorida por J, anteriores em cinza
ax = nexttile(t);  hold(ax, 'on');
plot(ax, Xall(~atual,2), Xall(~atual,3), '.', 'Color', [.75 .75 .75]);
scatter(ax, Xall(atual & ~col,2), Xall(atual & ~col,3), 50, Jall(atual & ~col), 'filled');
plot(ax, Xall(atual & col,2), Xall(atual & col,3), 'x', 'Color', [.85 .33 .1]);
aa = linspace(cfg.lb(2), cfg.ub(2), 100);
plot(ax, aa, cfg.passo_max./sin(aa), 'r-');                % fronteira dos pes se cruzando
plot(ax, xb(2), xb(3), 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
axis(ax, [cfg.lb(2) cfg.ub(2) cfg.lb(3) cfg.ub(3)]);  grid(ax, 'on');  colorbar(ax);
xlabel(ax, 'a [rad]');  ylabel(ax, 'l [mm]');  title(ax, 'Geracao atual (cor = J, x = colisao)');

% 3) avanco x tensao de todas as simulacoes, cor = geracao
ax = nexttile(t);  hold(ax, 'on');
scatter(ax, Xall(~col,1), [rall(~col).dx], 25, ger(~col), 'filled');
plot(ax, Xall(caiu,1), [rall(caiu).dx], 'kx');
cb = colorbar(ax);  cb.Label.String = 'geracao';  grid(ax, 'on');
xlim(ax, [cfg.lb(1) cfg.ub(1)]);  xlabel(ax, 'V [V]');  ylabel(ax, 'dx [mm]');
title(ax, 'Avanco x tensao (x = caiu)');

% 4) deslocamento do melhor ate agora e do melhor desta geracao
ax = nexttile(t);  hold(ax, 'on');
[~, kg] = min(R(g).J);  rg = R(g).res(kg);
if ~isempty(best.hist), plot(ax, best.hist.t, best.hist.px - best.hist.px(1), 'LineWidth', 1.5); end
if ~isempty(rg.hist),   plot(ax, rg.hist.t, rg.hist.px - rg.hist.px(1), '--'); end
grid(ax, 'on');  xlabel(ax, 't [s]');  ylabel(ax, 'x - x_0 [mm]');
legend(ax, 'melhor ate agora', 'melhor desta geracao', 'Location', 'northwest');
title(ax, 'Deslocamento em X');
drawnow;

if cfg.ver_melhor && (g == 1 || Jb < min(vertcat(R(1:g-1).J)))
    in = entrada_simulacao(xb, cfg);
    in = in.setModelParameter('SimMechanicsOpenEditorOnUpdate', 'on');
    sim(in);
end
end
