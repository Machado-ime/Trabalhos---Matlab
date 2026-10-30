function in = entrada_simulacao(x, cfg)
%% entrada_simulacao.m - Simulink.SimulationInput de um individuo x = [V a l]
% Define as variaveis do modelo (w = k_motor*V, a, l) e escreve cfg.blocos nos
% parametros dos blocos, sem alterar o arquivo .slx.
in = Simulink.SimulationInput(cfg.modelo);
in = in.setVariable('w', cfg.k_motor*x(1));
in = in.setVariable('a', x(2));
in = in.setVariable('l', x(3));
for b = 1:size(cfg.blocos, 1)
    in = in.setBlockParameter([cfg.modelo '/' cfg.blocos{b,1}], cfg.blocos{b,2}, cfg.blocos{b,3});
end
% SimscapeLogLimitData off: por padrao o log guarda so os ultimos 5000 passos,
% o que cortaria o inicio da caminhada (dx e quedas iniciais)
in = in.setModelParameter('StopTime', num2str(cfg.t_sim), 'SimscapeLogType', 'all', ...
                          'SimscapeLogLimitData', 'off');
end
