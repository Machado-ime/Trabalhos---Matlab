function res = custo_quadrupede(simout, cfg, x)
%% custo_quadrupede.m - funcao custo de uma simulacao (roda como PostSimFcn)
%   J = -dx/D_ref + P_f*I_f
%   dx  : deslocamento em X ate o fim da simulacao ou ate a queda [mm] (x cfg.sentido)
%   I_f : 1 se caiu, 0 caso contrario
% Sinais lidos da junta 6-DOF (Simscape logging): Px, Pz e o quaternio Q = [q0 q1 q2 q3].
% A base da junta (Rigid Transform12) esta ligada ao World so com translacao em Z,
% entao Px e Pz estao nos eixos do mundo e h = Pz + z_base e a altura acima do solo.

a = x(2);  l = x(3);
z_base = l + cfg.z_q + cfg.r_pe + cfg.folga0;    % mesma expressao do Rigid Transform12 (config_ga)
h_pe   = cfg.z_q + (l + cfg.r_pe)*cos(a);         % menor altura com o robo em pe
h_min  = cfg.h_barriga + cfg.f_queda*(h_pe - cfg.h_barriga);

res = struct('J', NaN, 'dx', NaN, 'queda', true, 'motivo', "erro", 't_queda', NaN, ...
             'h_min', h_min, 'hist', []);
try
    junta = simout.simlog.x6_DOF_Joint;
catch
    res.J = cfg.P_f;                              % simulacao falhou: trata como queda sem avanco
    return
end

t  = junta.Px.p.series.time;
px = junta.Px.p.series.values('mm');
h  = junta.Pz.p.series.values('mm') + z_base;
Q  = junta.S.Q.series.values;                     % N x 4, escalar primeiro
[t, iu] = unique(t);                              % o log pode repetir instantes em eventos
px = px(iu);  h = h(iu);  Q = Q(iu,:);

% roll e pitch (sequencia ZYX) a partir do quaternio
q0 = Q(:,1); q1 = Q(:,2); q2 = Q(:,3); q3 = Q(:,4);
roll  = rad2deg(atan2(2*(q0.*q1 + q2.*q3), 1 - 2*(q1.^2 + q2.^2)));
pitch = rad2deg(asin(min(max(2*(q0.*q2 - q3.*q1), -1), 1)));

% criterios de queda
caiu_h  = h < h_min;
caiu_r  = abs(roll)  > cfg.roll_max;
caiu_p  = abs(pitch) > cfg.pitch_max;
k = find(caiu_h | caiu_r | caiu_p, 1);

if isempty(k)
    k = numel(t);
    res.queda  = false;
    res.motivo = "ok";
else
    motivos = ["altura" "roll" "pitch"];
    res.motivo  = strjoin(motivos([caiu_h(k) caiu_r(k) caiu_p(k)]), "+");
    res.t_queda = t(k);
end

res.dx = cfg.sentido*(px(k) - px(1));
res.J  = -res.dx/cfg.D_ref + cfg.P_f*res.queda;

% curvas reduzidas para os graficos (o simlog inteiro nao volta dos workers)
ti = linspace(t(1), t(end), cfg.n_hist)';
res.hist = struct('t', ti, 'px', interp1(t, px, ti), 'h', interp1(t, h, ti), ...
                  'roll', interp1(t, roll, ti), 'pitch', interp1(t, pitch, ti));
end
