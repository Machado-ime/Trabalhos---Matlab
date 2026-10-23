%% gait_seno.m - funcao seno (cosseno por trechos) do angulo de quadril das 4 patas
% Dimensoes lidas do modelo sim_pre.slx (mm). Convencao: x para frente, y para a
% esquerda, z para cima; angulo do quadril medido da vertical, positivo = pe para frente.
clear; close all; clc

%% 1) Dimensoes da plataforma [mm]
corpo   = [100 50 25];        % Brick Solid: comprimento x largura x altura
quadril = [ 40  25;           % FL (x,y) do quadril em relacao ao centro do corpo
            40 -25;           % FR
           -40  25;           % HL
           -40 -25];          % HR
nomes   = ["FL" "FR" "HL" "HR"];
L_cil   = 50;                 % Cylindrical Solid (perna)
r_pe    = 2.5;                % Spherical Solid (pe)
Lf      = L_cil + r_pe;       % quadril -> centro do pe        (ASSUMIDO: 52.5)
h0      = Lf + r_pe;          % altura do quadril, perna vertical (55 = z inicial do autosave)

%% 2) Parametros da marcha (ajuste aqui)
S      = 30;                  % passada desejada: curso do pe no solo [mm]
H      = 8;                   % elevacao do pe no balanco [mm]
f      = 1;                   % frequencia da marcha [Hz]
marcha = "trote";             % "trote" | "caminhada"
sinal  = +1;                  % use -1 se a perna girar ao contrario no Simulink

A = asin(S/(2*Lf));           % amplitude do quadril: S = 2*Lf*sin(A)
switch marcha
    case "trote"              % diagonais em fase
        beta = 0.5;  fase = [0 0.5 0.5 0];        % [FL FR HL HR]
    case "caminhada"          % ordem HL -> FL -> HR -> FR, 1/4 de ciclo entre elas
        beta = 0.75; fase = [0.25 0.75 0 0.5];    % [FL FR HL HR]
end

%% 3) Funcao do angulo: cosseno por trechos (apoio beta, balanco 1-beta)
%  u = fase da perna em [0,1). Apoio: pe vai de +A a -A. Balanco: de -A a +A.
%  Com beta = 0.5 isso e exatamente  theta = A*cos(2*pi*f*t)  (senoide pura).
T = 1/f;  t = (0:0.001:4*T)';
u = mod(t*f - fase, 1);                       % N x 4

theta = zeros(size(u));  lift = zeros(size(u));
ap = u < beta;                                % apoio
theta(ap)  =  A*cos(pi*u(ap)/beta);
theta(~ap) = -A*cos(pi*(u(~ap)-beta)/(1-beta));
lift(~ap)  =  H*sin(pi*(u(~ap)-beta)/(1-beta));   % encurtamento da perna (joelho) no balanco

%% 4) Pe no referencial do quadril (x frente, z para baixo) e conferencias
Lr   = Lf - lift;                             % comprimento efetivo da perna
xp   = Lr.*sin(theta);   zp = Lr.*cos(theta);
xp0  = Lf*sin(theta);    zp0 = Lf*cos(theta); % so o quadril, sem levantar
fprintf('A = %.1f graus  (passada %.0f mm, Lf = %.1f mm)\n', rad2deg(A), S, Lf);
fprintf('Sem elevacao: o pe sobe %.2f mm nas pontas da passada, nos DOIS sentidos.\n', ...
        Lf*(1-cos(A)));
fprintf('Folga do pe no balanco (meio): %.1f mm acima do apoio. Vao entre quadris na lateral: %d mm.\n', ...
        H, 2*quadril(1,1));

%% 5) Sinais para o Simulink (From Workspace -> Simulink-PS Converter, rad)
hip  = timeseries(sinal*theta, t);  hip.Name  = 'hip_rad';    % colunas: FL FR HL HR
lift = timeseries(lift, t);         lift.Name = 'lift_mm';

%% 6) Graficos
figure('Color','w','Position',[100 100 900 380]);
subplot(1,2,1); plot(t, rad2deg(sinal*theta)); grid on; legend(nomes,'Location','best');
xlabel('t [s]'); ylabel('\theta_{quadril} [graus]'); title(sprintf('Quadril - %s', marcha));
subplot(1,2,2); k = 1; hold on; axis equal; grid on; set(gca,'YDir','reverse');
plot(xp(:,k), zp(:,k), 'LineWidth', 1.5); plot(xp0(:,k), zp0(:,k), 'k--');
xlabel('x [mm] (frente)'); ylabel('z [mm] (baixo)'); title('Pe em relacao ao quadril (FL)');
legend('quadril + elevacao', 'so quadril (mesmo arco ida e volta)', 'Location','south');
