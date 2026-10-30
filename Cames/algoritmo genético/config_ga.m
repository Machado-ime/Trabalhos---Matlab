function cfg = config_ga()
%% config_ga.m - todos os ajustes do algoritmo genetico (edite aqui)
% Variaveis otimizadas (genes):  x = [V a l]
%   V : tensao do motor                            [V]      -> w = k_motor*V
%   a : amplitude das senoides do quadril          [rad]    (entra na junta pelo Simulink-PS Converter)
%   l : comprimento da perna (cilindro)            [mm]
% No modelo: w = frequencia angular das senoides do quadril [rad/s] (Sine Wave / Sine Wave1)
% Funcao custo (minimizar):  J = -dx/D_ref + P_f*I_f   (ver custo_quadrupede.m)

%% 1) Geometria do robo (medida no modelo com Transform Sensors, frame "centro" do File Solid)
cfg.z_q        = 13.5;                % quadril abaixo do frame "centro" [mm]
cfg.r_pe       = 5;                   % raio do pe (Spherical Solid) e da perna [mm]
cfg.h_barriga  = 18.4;                % altura do "centro" com o chassi apoiado no chao [mm]
cfg.d_quadris  = 51;                  % distancia em X entre quadril dianteiro e traseiro do mesmo lado [mm]
cfg.folga0     = 1;                   % o pe comeca a 1 mm do chao [mm]
% Restricao: pernas do mesmo lado andam em oposicao e se aproximam nos extremos.
% Os pes se tocam quando  2*l*sin(a) = d_quadris - 2*r_pe   ->   l*sin(a) <= passo_max
cfg.passo_max  = (cfg.d_quadris - 2*cfg.r_pe)/2;                    % 20.5 mm

%% 2) Modelo Simulink
cfg.modelo       = 'sim_pre';
cfg.pasta_modelo = fileparts(fileparts(mfilename('fullpath')));   % pasta Cames (um nivel acima)
cfg.t_sim        = 10;                % tempo de simulacao [s]

% Onde cada gene entra no modelo. O GA escreve estes parametros em cada simulacao
% (Simulink.SimulationInput), sem alterar o arquivo .slx.
%   {bloco, parametro, expressao}
transf = @(k) sprintf('Rigid\nTransform%d', k);
cfg.blocos = {
    'Sine Wave',            'Frequency',                  'w'
    'Sine Wave1',           'Frequency',                  'w'
    'Sine Wave',            'Amplitude',                  'a'
    'Sine Wave1',           'Amplitude',                  'a'
    'Cylindrical Solid',    'CylinderLength',             'l'
    'Cylindrical Solid1',   'CylinderLength',             'l'
    'Cylindrical Solid2',   'CylinderLength',             'l'
    'Cylindrical Solid3',   'CylinderLength',             'l'
    transf(1),              'TranslationCartesianOffset', '[0 0  l/2]'   % quadril -> centro do cilindro
    transf(4),              'TranslationCartesianOffset', '[0 0  l/2]'
    transf(7),              'TranslationCartesianOffset', '[0 0  l/2]'
    transf(10),             'TranslationCartesianOffset', '[0 0  l/2]'
    transf(2),              'TranslationCartesianOffset', '[0 0 -l/2]'   % centro do cilindro -> pe
    transf(5),              'TranslationCartesianOffset', '[0 0 -l/2]'
    transf(8),              'TranslationCartesianOffset', '[0 0 -l/2]'
    transf(11),             'TranslationCartesianOffset', '[0 0 -l/2]'
    transf(12),             'TranslationCartesianOffset', ...            % altura inicial: pe a folga0 do chao
        sprintf('[0 0 l+%g]', cfg.z_q + cfg.r_pe + cfg.folga0)
    };

%% 3) Genes e limites
cfg.k_motor = 6.8068;                 % w(V) = 6.8068*V  [rad/s por volt]
cfg.nomes = {'V', 'a', 'l'};
cfg.unid  = {'V', 'rad', 'mm'};
cfg.lb    = [ 1    0.10  30];         % limites inferiores
cfg.ub    = [12    0.70  120];         % superiores (V = 12 -> w = 81.7 rad/s = 13 Hz)
% dentro da caixa, combinacoes com l*sin(a) > passo_max sao descartadas sem simular

%% 4) Funcao custo
cfg.sentido   = +1;                   % +1 premia andar em +X (lado dos quadris "frontal"), -1 em -X
cfg.D_ref     = 100;                  % distancia de referencia [mm]
cfg.P_f       = 10;                   % penalidade por queda (> maior dx/D_ref esperado)
% Queda por altura: o limite fica entre a menor altura possivel em pe (pernas no
% extremo a) e o chassi no chao. Depende de l e de a:
%   h_pe(l,a) = z_q + (l + r_pe)*cos(a)
%   h_min     = h_barriga + f_queda*(h_pe - h_barriga)
cfg.f_queda   = 0.5;
cfg.roll_max  = 30;                   % queda se |roll|  > roll_max  [graus]
cfg.pitch_max = 30;                   % queda se |pitch| > pitch_max [graus]
cfg.n_hist    = 400;                  % amostras guardadas das curvas de cada individuo

%% 5) Algoritmo genetico
cfg.n_pop       = 25;                 % individuos por geracao
cfg.n_ger       = 5000;                 % numero maximo de geracoes
cfg.n_elite     = 2;                  % melhores copiados sem alteracao
cfg.k_torneio   = 3;                  % tamanho do torneio na selecao
cfg.p_cruz      = 0.9;                % probabilidade de cruzamento
cfg.alfa_blx    = 0.5;                % cruzamento BLX-alfa
cfg.p_mut       = 0.3;                % probabilidade de mutacao por gene
cfg.sigma_mut   = [0.15 0.03];        % desvio da mutacao (fracao da faixa): inicio -> fim
cfg.estagnacao  = 20;                  % para se o melhor nao melhorar em N geracoes
cfg.semente     = 1;                  % rng (reprodutibilidade)

%% 6) Execucao e visualizacao
cfg.painel      = true;               % painel ao vivo, redesenhado a cada geracao (painel_ga.m)
cfg.gerenciador = true;              % Simulation Manager: progresso de cada simulacao da geracao
cfg.ver_melhor  = true;              % anima cada novo melhor no Mechanics Explorer (+1 simulacao)
cfg.paralelo  = true;                 % parsim (Parallel Computing Toolbox); false = uma por vez
cfg.n_workers = 6;                    % maximo do perfil "Processes" desta maquina; ~1-2 GB de RAM cada
cfg.arquivo   = fullfile(fileparts(mfilename('fullpath')), 'resultado_ga.mat');
end
