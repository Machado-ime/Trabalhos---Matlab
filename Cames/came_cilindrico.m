%% came_cilindrico.m - came cilíndrico da perna: esquema do mecanismo e diagrama de deslocamento
% Mecanismo (entendimento a confirmar):
%   - o came cilíndrico (tambor) gira em torno do próprio eixo, na direção X, com a mesma velocidade w
%     das senoides do quadril: 1 volta do came = 1 ciclo de marcha
%   - a perna e a barra de R = 42,5 mm formam UM corpo rígido, que gira no pivô (quadril) em torno de Y
%   - o rolete fica na ponta da barra, com o centro na mesma altura do eixo do came, encostado
%     (tangente) na lateral do tambor, dentro de uma ranhura senoidal
%   - a ranhura empurra o rolete ao longo do eixo do came:  theta(phi) = a*sin(phi),  s(phi) = R*sin(theta)
% Dados do melhor indivíduo do GA (resultado_ga.mat); sem o arquivo usa os valores abaixo.
clear; close all; clc

%% 1) Dados
V = 7.07;  a = 0.172;  l = 117.8;               % melhor do GA (V [V], a [rad], l [mm])
arq = fullfile(fileparts(mfilename('fullpath')), 'algoritmo genético', 'resultado_ga.mat');
if isfile(arq)
    S = load(arq, 'R', 'cfg');
    Xall = vertcat(S.R.X);  [~, k] = min(vertcat(S.R.J));
    V = Xall(k,1);  a = Xall(k,2);  l = Xall(k,3);
    kmot = S.cfg.k_motor;
else
    kmot = 6.8068;
end
w  = kmot*V;                 % velocidade do came [rad/s]
T  = 2*pi/w;                 % período = 1 volta do came [s]
R  = 42.5;                   % barra: pivô -> centro do rolete [mm]
De = 42;  Di = 32;           % tambor: diâmetro externo e fundo da ranhura [mm]
Lr = (De - Di)/2;            % profundidade da ranhura = comprimento do rolete [mm]
rc = (De + Di)/4;            % raio de passo: eixo do came -> centro do rolete (meio da ranhura) [mm]
rr = 3;                      % raio do rolete [mm]                                     só desenho
g  = 2;                      % folga entre a barra e a superfície do tambor [mm]      só desenho
Lc = 44;                     % comprimento do tambor desenhado [mm]                    só desenho
yr = g + Lr/2;               % centro do rolete, fora do plano da barra (y = 0)
yc = yr + rc;                % eixo do came: mesma altura z = R do centro do rolete
re = rc + Lr/2;              % raio externo do tambor

%% 2) Cinemática
phi   = linspace(0, 2*pi, 721);          % ângulo do came
theta = a*sin(phi);                      % ângulo da perna/barra
s     = R*sin(theta);                    % deslocamento do rolete ao longo do eixo do came [mm]
smax  = R*sin(a);
fprintf('w = %.2f rad/s (%.2f Hz), T = %.1f ms\n', w, w/(2*pi), 1e3*T);
fprintf('theta = a*sin(phi): a = %.3f rad = %.1f graus\n', a, rad2deg(a));
fprintf('s = R*sin(theta):   s_max = %.2f mm, curso total = %.2f mm (arco R*a = %.2f mm)\n', smax, 2*smax, R*a);
fprintf('o rolete desce R*(1-cos a) = %.2f mm ao longo da superfície do tambor (%.1f graus de came)\n', ...
        R*(1-cos(a)), rad2deg(R*(1-cos(a))/rc));
fprintf('passo do pé 2*l*sin(a) = %.1f mm, velocidade máx. do rolete R*a*w = %.0f mm/s\n', 2*l*sin(a), R*a*w);
fprintf('desenvolvimento do tambor 2*pi*rc = %.1f mm\n', 2*pi*rc);

cor0 = [0 0 0];  corp = [0 .35 .8];  corn = [.85 .2 .1];        % phi = 0/180, 90, 270
azul = [.1 .3 .7];  cinza = [.35 .4 .55];  tambor = [.88 .92 .97];  laranja = [1 .75 .4];
pasta = fileparts(mfilename('fullpath'));

%% 3) Figura 1: mecanismo
f1 = figure('Color', 'w', 'Position', [40 40 1750 900]);
t1 = tiledlayout(f1, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t1, sprintf('Perna com came cilíndrico e seguidor oscilante   |   a = %.1f°   l = %.1f mm   R = %.1f mm   tambor Ø%g (fundo Ø%g)', ...
      rad2deg(a), l, R, De, Di), 'FontWeight', 'bold');
zfaixa = [-l-32, R+re+14];

%--- A) vista lateral: olhando ao longo de Y (o tambor está atrás da barra) ---------------------------
axA = nexttile(t1);  hold(axA, 'on');  axis(axA, 'equal');
rectangle(axA, 'Position', [-Lc/2 R-re Lc 2*re], 'FaceColor', tambor, 'EdgeColor', cinza);
beta = linspace(-pi/2, pi/2, 121);                            % ranhura na face voltada para a barra (phi = 0)
xg = R*sin(a*sin(beta));  zg = R + re*sin(beta);
patch(axA, [xg-rr fliplr(xg+rr)], [zg fliplr(zg)], [.68 .8 .96], 'EdgeColor', corp, 'LineWidth', 0.8);
plot(axA, Lc/2*[-1.3 1.3], [R R], '-.', 'Color', cinza);
text(axA, -Lc/2+1, R+re-1, 'came cilíndrico', 'FontSize', 8, 'Color', cinza, 'VerticalAlignment', 'top');
text(axA, xg(end)+rr+1, R+re-3, 'ranhura', 'FontSize', 8, 'Color', corp, 'VerticalAlignment', 'top');
text(axA, Lc/2*1.3, R-1.5, 'eixo X', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontSize', 8, 'Color', cinza);
tt = linspace(-a, a, 60);
plot(axA, -l*sin(tt), -l*cos(tt), ':', 'Color', [.5 .5 .5]);                % trajetória do pé
casos = {-a, corn; a, corp; 0, cor0};
for c = 1:3
    th = casos{c,1};  cc = casos{c,2};
    tip = R*[sin(th) cos(th)];  foot = -l*[sin(th) cos(th)];
    if th == 0, lw = 3; fr = laranja; fp = [.85 .85 .85]; else, lw = 1.2; fr = 'none'; fp = 'w'; end
    plot(axA, [foot(1) 0 tip(1)], [foot(2) 0 tip(2)], '-', 'Color', cc, 'LineWidth', lw);
    rectangle(axA, 'Position', [tip(1)-rr tip(2)-rr 2*rr 2*rr], 'Curvature', [1 1], 'EdgeColor', cc, 'FaceColor', fr);
    rectangle(axA, 'Position', [foot(1)-5 foot(2)-5 10 10], 'Curvature', [1 1], 'EdgeColor', cc, 'FaceColor', fp);
end
rectangle(axA, 'Position', [-2.5 -2.5 5 5], 'Curvature', [1 1], 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 1.5);
text(axA, 5, 0, 'pivô (quadril)', 'FontSize', 9, 'VerticalAlignment', 'middle');
text(axA, -5, 9, sprintf('R = %.1f mm', R), 'FontSize', 9, 'Color', azul, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
text(axA, 13, -l/2, {'perna', sprintf('l = %.1f mm', l)}, 'FontSize', 9, 'Color', azul, 'FontWeight', 'bold');
text(axA, smax+rr+1, R+4, 'rolete', 'FontSize', 8, 'VerticalAlignment', 'bottom');
zd = R + re + 4;                                                % cota do curso do rolete
for xx = [-1 1]*smax, plot(axA, xx*[1 1], [R+rr zd+2], 'k:'); end
seta2(axA, [-smax zd], [smax zd]);
text(axA, 0, zd+1.5, sprintf('2 s_{máx} = %.1f mm', 2*smax), 'FontSize', 9, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
yp = -l-18;                                                     % cota do passo do pé
seta2(axA, [-l*sin(a) yp], [l*sin(a) yp]);
text(axA, 0, yp-2, sprintf('passo do pé = %.1f mm', 2*l*sin(a)), 'FontSize', 9, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(axA, -l*sin(a), -l-9, '\theta = +a', 'FontSize', 8, 'Color', corp, 'HorizontalAlignment', 'center');
text(axA,  l*sin(a), -l-9, '\theta = -a', 'FontSize', 8, 'Color', corn, 'HorizontalAlignment', 'center');
xlim(axA, [-40 40]);  ylim(axA, zfaixa);  xlabel(axA, 'X [mm]');  ylabel(axA, 'Z [mm]');  grid(axA, 'on');  box(axA, 'on');
title(axA, {'Vista lateral (olhando ao longo de Y)', '\theta > 0: rolete vai para +X, pé vai para trás'}, 'FontSize', 10);

%--- B) vista frontal: olhando ao longo de X --------------------------------------------------------
axB = nexttile(t1);  hold(axB, 'on');  axis(axB, 'equal');
ang = linspace(0, 2*pi, 200);
fill(axB, yc + re*cos(ang), R + re*sin(ang), tambor, 'EdgeColor', cinza);
plot(axB, yc + (rc-Lr/2)*cos(ang), R + (rc-Lr/2)*sin(ang), '--', 'Color', cinza);       % fundo da ranhura
plot(axB, yc + rc*cos(ang), R + rc*sin(ang), ':', 'Color', corp);                        % raio de passo
plot(axB, yc, R, '+', 'Color', cinza, 'MarkerSize', 10, 'LineWidth', 1.2);
plot(axB, [-12 yc+re+4], [R R], '-.', 'Color', cinza);                                  % linha de centro
text(axB, -13, R, {'centro do rolete', 'na altura do', 'eixo do came'}, 'FontSize', 8, 'HorizontalAlignment', 'right', 'Color', cinza);
rectangle(axB, 'Position', [-8 -2.5 12 5], 'FaceColor', [.5 .5 .5], 'EdgeColor', 'none');   % pino do pivô (eixo Y)
plot(axB, [0 0], [-l R], '-', 'Color', azul, 'LineWidth', 3);                                % perna + barra
plot(axB, [0 g], [R R], '-', 'Color', [.3 .3 .3], 'LineWidth', 2);                          % eixo do rolete
rectangle(axB, 'Position', [g R-rr Lr 2*rr], 'FaceColor', laranja, 'EdgeColor', [.6 .4 .1]);
rectangle(axB, 'Position', [-5 -l-5 10 10], 'Curvature', [1 1], 'FaceColor', [.85 .85 .85], 'EdgeColor', 'k');
ar = linspace(deg2rad(-60), deg2rad(40), 40);  ra = re + 4;                                 % rotação do came
plot(axB, yc + ra*cos(ar), R + ra*sin(ar), 'k-', 'LineWidth', 1.2);
quiver(axB, yc + ra*cos(ar(end-3)), R + ra*sin(ar(end-3)), ra*(cos(ar(end))-cos(ar(end-3))), ...
       ra*(sin(ar(end))-sin(ar(end-3))), 0, 'k', 'LineWidth', 1.2, 'MaxHeadSize', 4);
text(axB, yc + ra*cos(ar(15))+1.5, R + ra*sin(ar(15)), '\omega', 'FontSize', 12);
for yy = [yr yc], plot(axB, yy*[1 1], [R-rr-1 R-re-7], 'k:'); end                           % cota r_c
seta2(axB, [yr R-re-5], [yc R-re-5]);
text(axB, (yr+yc)/2, R-re-7, sprintf('r_c = %g mm', rc), 'FontSize', 9, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(axB, -3, R+7, 'rolete', 'FontSize', 9, 'HorizontalAlignment', 'right');
text(axB, -2, R/2+3, 'barra R', 'FontSize', 9, 'Color', azul, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
text(axB, -2, -l/2, 'perna l', 'FontSize', 9, 'Color', azul, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
text(axB, -9, 0, 'pivô', 'FontSize', 9, 'HorizontalAlignment', 'right');
text(axB, yc, R+re+2, 'came (tambor)', 'FontSize', 9, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Color', cinza);
xlim(axB, [-42 yc+re+10]);  ylim(axB, zfaixa);  xlabel(axB, 'Y [mm]');  ylabel(axB, 'Z [mm]');  grid(axB, 'on');  box(axB, 'on');
title(axB, {'Vista frontal (olhando ao longo de X)', 'rolete tangente ao tambor; tracejado = fundo da ranhura'}, 'FontSize', 10);

%--- C) esboço 3D (perna cortada) -------------------------------------------------------------------
axC = nexttile(t1);  hold(axC, 'on');
az = -20;  el = 18;
[Yc, Zc, Xc] = cylinder(re, 90);                              % tambor com eixo em X
surf(axC, (Xc-0.5)*Lc, Yc + yc, Zc + R, 'FaceColor', [.75 .82 .92], 'FaceAlpha', 0.35, 'EdgeColor', 'none');
for xe = [-Lc/2 Lc/2]
    plot3(axC, xe*ones(size(ang)), yc + re*cos(ang), R + re*sin(ang), '-', 'Color', cinza);
end
plot3(axC, Lc/2*[-1.35 1.35], [yc yc], [R R], '-.', 'Color', cinza);
text(axC, Lc/2*1.4, yc, R, 'X', 'FontSize', 10, 'Color', cinza);
% ranhura: ponto psi da superfície, medido a partir da geratriz voltada para a barra (onde está o rolete)
psi = linspace(0, 2*pi, 361);
gx = R*sin(a*sin(psi));  gy = yc - re*cos(psi);  gz = R + re*sin(psi);
cam = [cos(deg2rad(el))*sin(deg2rad(az)), -cos(deg2rad(el))*cos(deg2rad(az)), sin(deg2rad(el))];
vis = (-cos(psi)*cam(2) + sin(psi)*cam(3)) > 0;               % normal da superfície . direção da câmera
plot3(axC, gx, gy, gz, ':', 'Color', [.6 .7 .85], 'LineWidth', 1);                      % parte de trás
gxv = gx;  gxv(~vis) = NaN;
plot3(axC, gxv, gy, gz, '-', 'Color', corp, 'LineWidth', 2.5);                          % parte visível
kg = round(numel(psi)/6) + 1;                                 % psi = 60 graus
plot3(axC, [gx(kg) -Lc/2], [gy(kg) gy(kg)], [gz(kg) R+re+10], '-', 'Color', corp, 'LineWidth', 0.8);
text(axC, -Lc/2, gy(kg), R+re+11, 'ranhura senoidal', 'FontSize', 9, 'Color', corp, ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
text(axC, Lc/2, yc, R+re+6, 'came cilíndrico', 'FontSize', 9, 'Color', cinza, 'HorizontalAlignment', 'center');
% barra + perna cortada (corpo rígido), eixo do rolete, rolete, pivô
plot3(axC, [0 0], [0 0], [-34 R], '-', 'Color', azul, 'LineWidth', 4);
plot3(axC, [0 0], [0 0], [-34 -46], ':', 'Color', azul, 'LineWidth', 2);
plot3(axC, [0 0], [0 g], [R R], '-', 'Color', [.3 .3 .3], 'LineWidth', 2);
[Xr, Zr, Yr] = cylinder(rr, 30);
surf(axC, Xr, g + Yr*Lr, Zr + R, 'FaceColor', laranja, 'EdgeColor', 'none');
[Xp, Zp, Yp] = cylinder(2.5, 30);
surf(axC, Xp, -8 + Yp*12, Zp, 'FaceColor', [.45 .45 .45], 'EdgeColor', 'none');
text(axC, 0, 0, -50, {sprintf('perna continua até l = %.1f mm', l), 'e termina no pé'}, 'FontSize', 9, ...
     'Color', azul, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(axC, -10, 0, -3, 'pivô (quadril)', 'FontSize', 9, 'HorizontalAlignment', 'right');
text(axC, -3, 0, R/2, 'barra R', 'FontSize', 9, 'Color', azul, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
text(axC, -4, 0, R+5, 'rolete', 'FontSize', 9, 'HorizontalAlignment', 'right');
seta3(axC, [-smax yr R-rr-5], [smax yr R-rr-5]);
text(axC, smax+2, yr, R-rr-5, 's', 'FontSize', 11, 'FontAngle', 'italic');
ar = linspace(deg2rad(100), deg2rad(210), 30);                % rotação do came, na tampa -X
xa = -Lc/2 - 3;  ra = re + 4;
plot3(axC, xa*ones(size(ar)), yc + ra*cos(ar), R + ra*sin(ar), 'k-', 'LineWidth', 1.3);
quiver3(axC, xa, yc + ra*cos(ar(end-3)), R + ra*sin(ar(end-3)), 0, ra*(cos(ar(end))-cos(ar(end-3))), ...
        ra*(sin(ar(end))-sin(ar(end-3))), 0, 'k', 'LineWidth', 1.3, 'MaxHeadSize', 4);
text(axC, xa, yc + ra*cos(ar(12)), R + ra*sin(ar(12)) + 2, '\omega', 'FontSize', 12);
axis(axC, 'equal');  axis(axC, 'off');  view(axC, az, el);
xlim(axC, [-36 36]);  ylim(axC, [-12 yc+re+4]);  zlim(axC, [-62, R+re+18]);
title(axC, {'Esboço 3D (perna cortada)', 'came gira em torno de X; barra e perna giram em torno de Y'}, 'FontSize', 10);

exportgraphics(f1, fullfile(pasta, 'came_mecanismo.png'), 'Resolution', 130);

%% 4) Figura 2: diagrama de deslocamento
fi  = rad2deg(phi);
tks = 0:90:360;
f2 = figure('Color', 'w', 'Position', [60 60 1300 820]);
t2 = tiledlayout(f2, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t2, sprintf('Diagrama de deslocamento do came   |   \\omega = %.1f rad/s (%.2f Hz, V = %.2f V)   R = %.1f mm', ...
      w, w/(2*pi), V, R), 'FontWeight', 'bold');

%--- theta(phi): a premissa -------------------------------------------------------------------------
axD = nexttile(t2);  hold(axD, 'on');
plot(axD, fi, rad2deg(theta), 'Color', azul, 'LineWidth', 2);
yline(axD, 0, 'k-');
yline(axD, [-1 1]*rad2deg(a), 'k:');
marcos(axD, rad2deg(a), cor0, corp, corn);
text(axD, 90, rad2deg(a)+0.8, sprintf('+a = %.1f°', rad2deg(a)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Color', corp);
text(axD, 270, -rad2deg(a)-0.8, sprintf('-a = -%.1f°', rad2deg(a)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Color', corn);
xlim(axD, [0 360]);  ylim(axD, rad2deg(a)*[-1.4 1.4]);  xticks(axD, tks);  xticklabels(axD, {});
ylabel(axD, '\theta [°]');  grid(axD, 'on');  box(axD, 'on');
title(axD, '\theta(\phi) = a sin\phi    (ângulo da perna e da barra: a senoide dada)', 'FontSize', 10);

%--- s(phi): o diagrama de deslocamento -------------------------------------------------------------
axE = nexttile(t2);  hold(axE, 'on');
area(axE, fi, s, 'FaceColor', azul, 'FaceAlpha', 0.12, 'EdgeColor', 'none');
plot(axE, fi, s, 'Color', azul, 'LineWidth', 2);
plot(axE, fi, R*a*sin(phi), '--', 'Color', [.5 .5 .5]);          % aproximação por arco R*theta
yline(axE, 0, 'k-');
yline(axE, [-1 1]*smax, 'k:');
marcos(axE, smax, cor0, corp, corn);
text(axE, 90, smax+0.35, sprintf('+s_{máx} = %.2f mm', smax), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Color', corp);
text(axE, 270, -smax-0.35, sprintf('-s_{máx} = -%.2f mm', smax), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Color', corn);
text(axE, 358, 1.35*smax, {sprintf('1 volta do came = 1 ciclo da marcha (T = %.1f ms)', 1e3*T), ...
     sprintf('desenvolvimento na borda Ø%g: 360° = \\pi\\cdot D = %.2f mm (meia volta %.2f mm)', De, pi*De, pi*De/2)}, ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontSize', 9, 'Color', [.3 .3 .3]);
xlim(axE, [0 360]);  ylim(axE, smax*[-1.4 1.4]);
xticks(axE, tks);  xticklabels(axE, arrayfun(@(p) sprintf('%d°\\newline%.1f ms', p, 1e3*deg2rad(p)/w), tks, 'UniformOutput', false));
xlabel(axE, 'ângulo do came \phi = \omega t');  ylabel(axE, 's [mm]');  grid(axE, 'on');  box(axE, 'on');
title(axE, 's(\phi) = R sin\theta(\phi) \approx R a sin\phi    (deslocamento do rolete ao longo do eixo do came; tracejado = R\cdot\theta)', 'FontSize', 10);

exportgraphics(f2, fullfile(pasta, 'came_deslocamento.png'), 'Resolution', 130);

%% Funções locais
function seta2(ax, p1, p2)
% seta de cota horizontal com ponta nas duas extremidades
plot(ax, [p1(1) p2(1)], [p1(2) p2(2)], 'k-', 'LineWidth', 0.8);
plot(ax, p1(1), p1(2), 'k<', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
plot(ax, p2(1), p2(2), 'k>', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
end

function seta3(ax, p1, p2)
% seta de cota 3D com ponta nas duas extremidades
plot3(ax, [p1(1) p2(1)], [p1(2) p2(2)], [p1(3) p2(3)], 'k-', 'LineWidth', 0.8);
plot3(ax, p1(1), p1(2), p1(3), 'k<', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
plot3(ax, p2(1), p2(2), p2(3), 'k>', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
end

function marcos(ax, ymax, cor0, corp, corn)
% pontos de phi = 0/180/360 (theta = 0), 90 (+a) e 270 (-a), com as cores da vista lateral
plot(ax, [0 180 360], [0 0 0], 'o', 'Color', cor0, 'MarkerFaceColor', 'w', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(ax, 90, ymax, 'o', 'Color', corp, 'MarkerFaceColor', corp, 'MarkerSize', 8);
plot(ax, 270, -ymax, 'o', 'Color', corn, 'MarkerFaceColor', corn, 'MarkerSize', 8);
end
