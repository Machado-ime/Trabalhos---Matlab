%% grafico_coeficientes.m - deslocamento e coeficientes cinemáticos no estilo dos slides da disciplina
% Mesmo padrão da figura "Movimentos Padronizados" (Maj QEM Elias Dias Rossi Lopes): fundo branco,
% caixa com grade cinza clara, deslocamento em azul, coeficientes de 1ª, 2ª e 3ª ordem em vermelho,
% verde e preto, legenda com caixa e eixos "y" e "teta/beta".
% Função do projeto, em relação ao ângulo do came theta (rad), com u = a*sin(theta):
%   y   = R*sin(u)
%   y'  = R*a*cos(theta)*cos(u)
%   y'' = -R*a*sin(theta)*cos(u) - R*a^2*cos(theta)^2*sin(u)
%   y'''= -R*a*cos(theta)*cos(u) + 3*R*a^2*sin(theta)*cos(theta)*sin(u) - R*a^3*cos(theta)^3*cos(u)
% Aqui beta = 2*pi: o diagrama é a volta inteira do came (subida + retorno, sem permanência).
clear; close all; clc

R = 42.5;  a = 0.172;                     % barra pivô-rolete [mm], amplitude da perna [rad]
th = linspace(0, 2*pi, 3601);             % ângulo do came [rad]
u  = a*sin(th);
y   = R*sin(u);                                                                    % mm
y1  = R*a*cos(th).*cos(u);                                                         % mm/rad
y2  = -R*a*sin(th).*cos(u) - R*a^2*cos(th).^2.*sin(u);                             % mm/rad^2
y3  = -R*a*cos(th).*cos(u) + 3*R*a^2*sin(th).*cos(th).*sin(u) - R*a^3*cos(th).^3.*cos(u);   % mm/rad^3

% conferência das derivadas analíticas contra derivação numérica
d1 = gradient(y, th);  d2 = gradient(y1, th);  d3 = gradient(y2, th);
fprintf('erro máx. vs derivação numérica: 1ª ordem %.1e, 2ª ordem %.1e, 3ª ordem %.1e\n', ...
        max(abs(d1(2:end-1) - y1(2:end-1))), max(abs(d2(2:end-1) - y2(2:end-1))), max(abs(d3(2:end-1) - y3(2:end-1))));
fprintf('máximos: deslocamento %.2f mm, 1ª ordem %.2f, 2ª ordem %.2f, 3ª ordem %.2f\n', ...
        max(abs(y)), max(abs(y1)), max(abs(y2)), max(abs(y3)));

%% Figura no padrão do material
azul = [0 0.4470 0.7410];  vermelho = [1 0 0];  verde = [0 1 0];  preto = [0 0 0];
eixo = [0.15 0.15 0.15];                                    % cor padrão dos eixos e da grade do MATLAB
f = figure('Color', 'w', 'Units', 'inches', 'Position', [1 1 8 4.5]);
ax = axes(f, 'Position', [0.085 0.15 0.68 0.82]);  hold(ax, 'on');   % margens para os rótulos e a legenda
x = th/(2*pi);                                             % teta/beta com beta = 2*pi
h(1) = plot(ax, x, y,  'Color', azul,     'LineWidth', 4);
h(2) = plot(ax, x, y1, 'Color', vermelho, 'LineWidth', 2.5);
h(3) = plot(ax, x, y2, 'Color', verde,    'LineWidth', 2.5);
h(4) = plot(ax, x, y3, 'Color', preto,    'LineWidth', 2.5);
set(ax, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on', 'GridColor', eixo, 'GridAlpha', 0.15, 'GridLineStyle', '-', ...
    'Color', 'w', 'XColor', eixo, 'YColor', eixo, 'FontName', 'Arial', 'FontSize', 11, 'LineWidth', 0.5, ...
    'XLim', [0 1], 'XTick', 0:0.1:1, 'YLim', [-8 8], 'YTick', -8:4:8);
xlabel(ax, 'teta/beta', 'FontName', 'Arial', 'FontSize', 11, 'Color', eixo);
ylabel(ax, 'y', 'FontName', 'Arial', 'FontSize', 11, 'Color', eixo);
lg = legend(ax, h, {'deslocamento', 'coef 1ª ordem', 'coef 2ª ordem', 'coef 3ª ordem'}, ...
    'Location', 'eastoutside', 'Box', 'on', 'EdgeColor', eixo, 'Color', 'w', 'FontName', 'Arial', 'FontSize', 11);
lg.ItemTokenSize = [30 18];

pasta = fullfile(fileparts(mfilename('fullpath')), 'apresentacao');
if ~isfolder(pasta), mkdir(pasta); end
exportgraphics(f, fullfile(pasta, 'grafico_coeficientes_cinematicos.png'), 'Resolution', 250, 'BackgroundColor', 'white', 'Padding', 10);
