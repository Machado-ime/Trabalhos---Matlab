function anima_robo(P, Q, tv, arquivo)
%ANIMA_ROBO  Anima a evolução temporal do mecanismo e salva em GIF.
%
%  anima_robo(P, Q, tv)
%  anima_robo(P, Q, tv, arquivo)
%
%  Entradas
%    P        struct de parâmetros (os mesmos exigidos por desenha_mecanismo,
%             função local deste arquivo — ver definição abaixo)
%    Q        [3xnt] histórico de ângulos de junta ao longo do tempo   [rad]
%    tv       [1xnt] ou [ntx1] vetor de tempo correspondente a Q       [s]
%    arquivo  (opcional) nome do GIF de saída. Padrão: 'animacao.gif'
%
%  Chama desenha_mecanismo(P, q) quadro a quadro — função LOCAL deste
%  arquivo (não é mais um .m separado). Sobrepõe apenas o rastro do CM e
%  o relógio de tempo.
%
%  O número de quadros de Q é reamostrado para no máximo ~150 quadros
%  (senão o GIF fica pesado); a duração do GIF é ~4 s, independente da
%  duração real da simulação, para o movimento ficar visível a olho nu.

if nargin < 4
    arquivo = 'animacao.gif';
end

tv = tv(:).';
nt = size(Q, 2);

% ── Reamostragem para um número de quadros exibível ───────────────────────
n_quadros = min(150, nt);
idx = round(linspace(1, nt, n_quadros));

% ── Rastro do CM: cinemática direta do modelo 'ponta', igual à
%    desenha_mecanismo (função local abaixo) ──────────────────────────────
a3 = Q(1,:) + Q(2,:) + Q(3,:);
XC =        P.l1*cos(Q(1,:)) + P.l2*cos(Q(1,:)+Q(2,:)) + P.l3*cos(a3);
YC = P.lb + P.l1*sin(Q(1,:)) + P.l2*sin(Q(1,:)+Q(2,:)) + P.l3*sin(a3);

% ── Figura ──────────────────────────────────────────────────────────────
fig = figure('Color', 'w', 'Position', [100 80 520 660]);
try, theme(fig, 'light'); catch, end
ax = axes(fig);

delay = 4 / n_quadros;   % GIF de ~4 s no total, não importa a duração real

for n = 1:n_quadros
    k = idx(n);

    desenha_mecanismo(P, Q(:,k));

    hold(ax, 'on');
    plot(ax, XC(1:k), YC(1:k), '-', 'Color', [0.85 0.10 0.10 0.5], 'LineWidth', 1.2);
    text(ax, -0.135, 0.47, sprintf('t = %5.3f s', tv(k)), ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.15]);
    hold(ax, 'off');

    % exportgraphics (não getframe): em modo headless (-batch) o getframe
    % captura o fundo da figura como preto mesmo com Color='w'. O resto do
    % projeto já usa exportgraphics para as figuras estáticas e funciona.
    tmp = [tempname, '.png'];
    exportgraphics(fig, tmp, 'Resolution', 110);
    im = imread(tmp);
    delete(tmp);

    [imind, cm] = rgb2ind(im, 256);
    if n == 1
        imwrite(imind, cm, arquivo, 'gif', 'Loopcount', inf, 'DelayTime', delay);
    else
        imwrite(imind, cm, arquivo, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
    end
end

fprintf('Animação salva em %s (%d quadros, %.1f s de GIF)\n', arquivo, n_quadros, n_quadros*delay);

end


function desenha_mecanismo(P, q)
%DESENHA_MECANISMO  Visualiza o mecanismo plano de 4 barras numa dada postura.
%
%  desenha_mecanismo(P, q)  — função LOCAL, só visível dentro de anima_robo.m
%
%  Entradas
%    P   struct de parâmetros, precisa ter os campos:
%        lb, l1..l3, mb, m1..m3, cb, c1..c3, d_calcanhar, d_ponta, x_ref
%        (P.modelo_cm é opcional — se ausente, usa 'ponta')
%        Índice b = barra fixa (solo->tornozelo); 1,2,3 = canela, coxa, tronco.
%    q   [3x1] ângulos DE JUNTA (relativos) [rad]
%        q(1) tornozelo | q(2) joelho | q(3) quadril
%
%  ── CONVENÇÃO DE ÂNGULO ──────────────────────────────────────────────────
%  Ângulo absoluto medido a partir do eixo +x, sentido anti-horário — a
%  mesma convenção do main.mlx. Ângulos absolutos das barras:
%      a1 = q1 | a2 = q1+q2 | a3 = q1+q2+q3
%  Postura ereta => a1 = a2 = a3 = pi/2, e o joelho só flexiona com q2 >= 0.
%
%  Desenha no eixo corrente (gca / figura corrente). Elementos:
%    cinza grosso .... barra fixa lb (solo -> tornozelo)
%    azul grosso ..... base de apoio (pé), de -d_calcanhar a +d_ponta
%    preto ........... barras móveis l1, l2, l3
%    círculos brancos. juntas de revolução (tornozelo, joelho, quadril)
%    bola VERMELHA ... CM do modelo 'ponta' (massa concentrada)
%    bola LARANJA .... CM ponderado pelas 4 barras (o real do modelo)
%    tracejado ....... projeção vertical do CM ativo (P.modelo_cm) até o solo
%    verde ........... x_ref, alvo do controle

q = q(:);

if ~isfield(P, 'modelo_cm')
    P.modelo_cm = 'ponta';   % padrão se o campo não existir em P
end

% ── Cinemática direta: posição de todos os nós ───────────────────────────
a = [ q(1); q(1)+q(2); q(1)+q(2)+q(3) ];

p0 = [0; 0];                              % eixo fixo, no solo
p1 = p0 + [0; P.lb];                      % tornozelo
p2 = p1 + P.l1*[cos(a(1)); sin(a(1))];    % joelho
p3 = p2 + P.l2*[cos(a(2)); sin(a(2))];    % quadril
p4 = p3 + P.l3*[cos(a(3)); sin(a(3))];    % ponta = CM do tronco

pts = [p0, p1, p2, p3, p4];   % [2x5]: eixo, tornozelo, joelho, quadril, ponta

% ── Centro de massa: os dois modelos ──────────────────────────────────────
cm_ponta = p4;

rb = p0 + P.cb*(p1 - p0);   % CM da barra fixa
r1 = p1 + P.c1*(p2 - p1);   % CM da canela
r2 = p2 + P.c2*(p3 - p2);   % CM da coxa
r3 = p3 + P.c3*(p4 - p3);   % CM do tronco

m = [P.mb, P.m1, P.m2, P.m3];
cm_pond = (m(1)*rb + m(2)*r1 + m(3)*r2 + m(4)*r3) / sum(m);

switch P.modelo_cm
    case 'ponta'
        cm = cm_ponta;
    case 'ponderado'
        cm = cm_pond;
    otherwise
        error('desenha_mecanismo:modelo', ...
              'P.modelo_cm deve ser ''ponta'' ou ''ponderado'' (recebido: ''%s'').', ...
              P.modelo_cm);
end

% ── Desenho ────────────────────────────────────────────────────────────
ax = gca;
cla(ax); hold(ax, 'on');

% Força fundo claro (o R2026a abre em tema escuro por padrão)
set(ax, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
        'GridColor', [0.7 0.7 0.7], 'GridAlpha', 0.5);
set(ancestor(ax, 'figure'), 'Color', 'w');

% Solo, com hachura
xg = [-0.14, 0.14];
plot(ax, xg, [0 0], 'k-', 'LineWidth', 1.5);
for xh = linspace(xg(1), xg(2), 29)
    plot(ax, [xh, xh-0.010], [0, -0.012], 'k-', 'LineWidth', 0.5);
end

% Base de apoio (pé)
plot(ax, [-P.d_calcanhar, P.d_ponta], [0 0], '-', ...
     'Color', [0 0.45 0.74], 'LineWidth', 7);

% Barra fixa lb
plot(ax, pts(1,1:2), pts(2,1:2), '-', ...
     'Color', [0.45 0.45 0.45], 'LineWidth', 6);

% Barras móveis l1, l2, l3
plot(ax, pts(1,2:5), pts(2,2:5), '-', ...
     'Color', [0.10 0.10 0.10], 'LineWidth', 3);

% Eixo fixo (engaste)
plot(ax, pts(1,1), pts(2,1), 's', 'MarkerSize', 11, ...
     'MarkerFaceColor', [0.3 0.3 0.3], 'MarkerEdgeColor', 'k');

% Juntas de revolução
plot(ax, pts(1,2:4), pts(2,2:4), 'o', 'MarkerSize', 9, ...
     'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

% Projeção vertical do CM ativo
plot(ax, [cm(1), cm(1)], [cm(2), 0], '--', ...
     'Color', [0.85 0.10 0.10], 'LineWidth', 1);
plot(ax, cm(1), 0, 'v', 'MarkerSize', 8, ...
     'MarkerFaceColor', [0.85 0.10 0.10], 'MarkerEdgeColor', 'k');

% Alvo x_ref
plot(ax, [P.x_ref, P.x_ref], [-0.02, 0.03], '-', ...
     'Color', [0 0.60 0.30], 'LineWidth', 2.5);

% Centros de massa (os dois modelos, para comparação visual)
plot(ax, cm_pond(1), cm_pond(2), 'o', 'MarkerSize', 10, ...
     'MarkerFaceColor', [1 0.75 0], 'MarkerEdgeColor', 'k', 'LineWidth', 1);
plot(ax, cm_ponta(1), cm_ponta(2), 'o', 'MarkerSize', 17, ...
     'MarkerFaceColor', [0.85 0.10 0.10], 'MarkerEdgeColor', 'k', 'LineWidth', 1);

% Rótulos das juntas, encostados na margem esquerda
nomes = {'', 'tornozelo', 'joelho', 'quadril', ''};
for jn = 2:4
    plot(ax, [-0.132, pts(1,jn)-0.008], [pts(2,jn), pts(2,jn)], ':', ...
         'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    text(ax, -0.135, pts(2,jn), nomes{jn}, 'HorizontalAlignment', 'left', ...
         'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', [0.35 0.35 0.35]);
end

% Acabamento
axis(ax, 'equal');
xlim(ax, [-0.14, 0.14]);
ylim(ax, [-0.03, 0.50]);
grid(ax, 'on'); box(ax, 'on');
xlabel(ax, 'x  [m]'); ylabel(ax, 'z  [m]');

cab = sprintf('q = [%.0f, %.0f, %.0f]^\\circ   |   x_{CM} = %+.1f cm', ...
              rad2deg(q(1)), rad2deg(q(2)), rad2deg(q(3)), cm(1)*100);
t = title(ax, cab, 'FontWeight', 'normal');
set(t, 'Color', [0.10 0.10 0.10]);
set(get(ax,'XLabel'), 'Color', [0.15 0.15 0.15]);
set(get(ax,'YLabel'), 'Color', [0.15 0.15 0.15]);

hold(ax, 'off');

end
