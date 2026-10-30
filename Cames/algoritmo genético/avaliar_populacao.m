function [J, res] = avaliar_populacao(X, cfg)
%% avaliar_populacao.m - simula cada linha de X = [V a l] e devolve o custo J
% 1) Restricao geometrica antes de simular: se l*sin(a) > passo_max os pes do mesmo
%    lado se cruzam. O Simscape nao tem contato entre as pernas (elas se atravessariam
%    sem erro), entao esses individuos nao sao simulados e recebem J = 2*P_f + violacao.
% 2) Os demais viram Simulink.SimulationInput (entrada_simulacao.m). A funcao custo
%    roda no fim de cada simulacao (PostSimFcn), entao so um resumo pequeno volta de
%    cada worker.

n   = size(X, 1);
res = repmat(struct('J', NaN, 'dx', NaN, 'queda', false, 'motivo', "colisao", ...
                    't_queda', NaN, 'h_min', NaN, 'hist', []), n, 1);
viol = X(:,3).*sin(X(:,2)) - cfg.passo_max;     % [mm], > 0 = pes se cruzam
for i = find(viol > 0)'
    res(i).J = 2*cfg.P_f + viol(i)/cfg.passo_max;
end

ok = find(viol <= 0);
if ~isempty(ok)
    in = repmat(Simulink.SimulationInput(cfg.modelo), numel(ok), 1);
    for k = 1:numel(ok)
        x = X(ok(k),:);
        in(k) = entrada_simulacao(x, cfg);
        in(k) = in(k).setPostSimFcn(@(out) custo_quadrupede(out, cfg, x));
    end

    onoff = {'off', 'on'};
    gerenciador = onoff{cfg.gerenciador + 1};
    if cfg.paralelo
        pastas = {cfg.pasta_modelo, fileparts(mfilename('fullpath'))};   % modelo e custo nos workers
        out = parsim(in, 'ShowProgress', 'off', 'ShowSimulationManager', gerenciador, ...
                     'TransferBaseWorkspaceVariables', 'off', 'StopOnError', 'off', ...
                     'SetupFcn', @() addpath(pastas{:}));
    else
        out = sim(in, 'ShowProgress', 'off', 'ShowSimulationManager', gerenciador, 'StopOnError', 'off');
    end

    for k = 1:numel(ok)
        i = ok(k);
        if isempty(out(k).ErrorMessage) && ismember('J', out(k).who)
            res(i) = struct('J', out(k).J, 'dx', out(k).dx, 'queda', out(k).queda, ...
                            'motivo', out(k).motivo, 't_queda', out(k).t_queda, ...
                            'h_min', out(k).h_min, 'hist', out(k).hist);
        else
            res(i).J = cfg.P_f;  res(i).queda = true;  res(i).motivo = "erro";   % = queda sem avanco
            warning('GA:sim', 'Simulacao falhou (V=%.3g a=%.3g l=%.3g): %s', ...
                    X(i,1), X(i,2), X(i,3), out(k).ErrorMessage);
        end
    end
end
J = [res.J]';
end
