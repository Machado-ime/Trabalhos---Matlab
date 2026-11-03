%% graficos_apresentacao.m - gráficos dos slides: deslocamento s(phi) e ângulo de pressão alfa(phi)
% Mesmo modelo do came_cilindrico.m: theta = a*sin(phi), s = R*sin(theta).
% Ângulo de pressão da barra oscilante: alfa = |theta - atan(s'/r)| (normal à parede da
% ranhura x velocidade do centro do rolete, perpendicular à barra).
clear; close all; clc

R = 42.5;  a = 0.172;            % barra pivô-rolete [mm], amplitude da perna [rad]
r = [21 16];                     % raio da borda e do fundo da ranhura [mm]
phi = linspace(0, 2*pi, 1441);  fi = rad2deg(phi);
theta = a*sin(phi);
s  = R*sin(theta);
s1 = R*a*cos(phi).*cos(a*sin(phi));              % ds/dphi [mm/rad]
alfa = @(rr) rad2deg(abs(theta - atan(s1/rr)));

pasta = fullfile(fileparts(mfilename('fullpath')), 'apresentacao');
if ~isfolder(pasta), mkdir(pasta); end
fundo = [0.98 0.98 0.98];  texto = [0.122 0.161 0.216];  mudo = [0.357 0.396 0.451];
azul = [0.184 0.365 0.541];  cinza = [0.65 0.65 0.65];  grade = [0.88 0.88 0.88];
fonte = 'Calibri';

%% 1) Deslocamento do rolete (slide 6): 396 x 220 pt
f1 = figure('Units', 'points', 'Position', [50 50 396 220], 'Color', fundo);
ax = axes(f1, 'Units', 'points', 'Position', [46 34 340 178]);  hold(ax, 'on');
estilo(ax, fonte, mudo, grade, fundo);
plot(ax, fi, s, 'Color', azul, 'LineWidth', 2.2);
yline(ax, 0, 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8);
[sm, k] = max(s);
plot(ax, fi(k), sm, 'o', 'MarkerSize', 5, 'MarkerFaceColor', azul, 'MarkerEdgeColor', azul);
plot(ax, 270, -sm, 'o', 'MarkerSize', 5, 'MarkerFaceColor', azul, 'MarkerEdgeColor', azul);
text(ax, fi(k), sm + 1.0, strrep(sprintf('+%.2f mm', sm), '.', ','), 'HorizontalAlignment', 'center', ...
     'VerticalAlignment', 'bottom', 'FontName', fonte, 'FontSize', 11, 'Color', azul);
text(ax, 270, -sm - 1.0, strrep(sprintf('%.2f mm', -sm), '.', ','), 'HorizontalAlignment', 'center', ...
     'VerticalAlignment', 'top', 'FontName', fonte, 'FontSize', 11, 'Color', azul);
ylim(ax, [-10 10]);  yticks(ax, -8:4:8);
yticklabels(ax, arrayfun(@(v) sprintf('%d mm', v), -8:4:8, 'UniformOutput', false));
xlabel(ax, 'ângulo do came \phi', 'FontName', fonte, 'FontSize', 12, 'Color', mudo);
exportgraphics(f1, fullfile(pasta, 'grafico_deslocamento.png'), 'Resolution', 300, 'BackgroundColor', fundo);

%% 2) Ângulo de pressão (slide 7): 372 x 207 pt
f2 = figure('Units', 'points', 'Position', [50 50 372 207], 'Color', fundo);
ax = axes(f2, 'Units', 'points', 'Position', [34 34 262 165]);  hold(ax, 'on');
estilo(ax, fonte, mudo, grade, fundo);
ab = alfa(r(1));  af = alfa(r(2));
plot(ax, fi, ab, 'Color', cinza, 'LineWidth', 1.6);
plot(ax, fi, af, 'Color', azul, 'LineWidth', 2.2);
plot(ax, [0 360], [30 30], '--', 'Color', texto, 'LineWidth', 1.2);
[am, k] = max(af);
plot(ax, fi(k), am, 'o', 'MarkerSize', 5, 'MarkerFaceColor', azul, 'MarkerEdgeColor', azul);
text(ax, fi(k), am - 1.5, strrep(sprintf('%.1f°', am), '.', ','), 'HorizontalAlignment', 'center', ...
     'VerticalAlignment', 'top', 'FontName', fonte, 'FontSize', 11, 'Color', azul, 'FontWeight', 'bold');
% nomes das linhas à direita do último ponto
text(ax, 364, 30, 'limite 30°', 'FontName', fonte, 'FontSize', 11, 'Color', texto, 'Clipping', 'off');
text(ax, 364, af(end) + 1.2, sprintf('fundo Ø%d', 2*r(2)), 'FontName', fonte, 'FontSize', 11, 'Color', azul, 'Clipping', 'off');
text(ax, 364, ab(end) - 1.8, sprintf('borda Ø%d', 2*r(1)), 'FontName', fonte, 'FontSize', 11, 'Color', [0.45 0.45 0.45], 'Clipping', 'off');
ylim(ax, [0 35]);  yticks(ax, 0:10:30);
yticklabels(ax, arrayfun(@(v) sprintf('%d°', v), 0:10:30, 'UniformOutput', false));
xlabel(ax, 'ângulo do came \phi', 'FontName', fonte, 'FontSize', 12, 'Color', mudo);
exportgraphics(f2, fullfile(pasta, 'grafico_angulo_pressao.png'), 'Resolution', 300, 'BackgroundColor', fundo);
fprintf('s_max = %.3f mm; alfa_max: borda %.1f, fundo %.1f graus (phi = %.0f)\n', sm, max(ab), am, fi(k));

function estilo(ax, fonte, mudo, grade, fundo)
% eixos limpos: só grade horizontal clara, sem caixa, rótulos na cor secundária
set(ax, 'Color', fundo, 'FontName', fonte, 'FontSize', 11, 'XColor', mudo, 'YColor', mudo, ...
    'Box', 'off', 'TickLength', [0 0], 'XLim', [0 360], 'XTick', 0:90:360, ...
    'XTickLabel', {'0°', '90°', '180°', '270°', '360°'}, 'YGrid', 'on', 'XGrid', 'off', ...
    'GridColor', grade, 'GridAlpha', 1, 'LineWidth', 0.8);
drawnow;  ax.YAxis.Axle.Visible = 'off';                 % sem linha do eixo y (a grade basta)
end
