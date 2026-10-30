function R = ga_real(avaliar, cfg)
%% ga_real.m - algoritmo genetico com codificacao real (minimiza J)
%   avaliar : @(X) -> [J, res], avalia uma populacao inteira (linhas de X)
% Operadores:
%   populacao inicial  hipercubo latino (cada gene cobre a faixa em n_pop estratos)
%   selecao            torneio de k individuos
%   cruzamento         BLX-alfa: filho sorteado em [min-alfa*d, max+alfa*d] por gene
%   mutacao            gaussiana, desvio cai de sigma_mut(1) a sigma_mut(2) da faixa
%   elitismo           os n_elite melhores passam direto (simulacao e deterministica:
%                      o custo deles e reaproveitado, sem simular de novo)

rng(cfg.semente);
nv = numel(cfg.lb);  faixa = cfg.ub - cfg.lb;  np = cfg.n_pop;

estrato = cell2mat(arrayfun(@(~) randperm(np)', 1:nv, 'UniformOutput', false));
X = cfg.lb + (estrato - rand(np, nv))/np .* faixa;

R = struct('X', {}, 'J', {}, 'res', {}, 'tempo', {});
melhor = Inf;  sem_melhora = 0;
fprintf('\n ger |  melhor J |  dx [mm] | queda  |   V      a      l   | cairam | colisao | tempo\n');

for g = 1:cfg.n_ger
    tic;
    if g == 1
        [J, res] = avaliar(X);
    else
        [Jf, resf] = avaliar(X(cfg.n_elite+1:end, :));
        J   = [J(elite);   Jf];
        res = [res(elite); resf];
    end
    R(g) = struct('X', X, 'J', J, 'res', res, 'tempo', toc);

    [Jb, ib] = min(J);
    fprintf('%4d | %9.4f | %8.1f | %-6s | %5.2f  %5.3f  %5.1f | %4d   | %5d   | %4.0f s\n', g, Jb, ...
            res(ib).dx, res(ib).motivo, X(ib,:), sum([res.queda]), sum([res.motivo] == "colisao"), R(g).tempo);
    save(cfg.arquivo, 'R', 'cfg');                % checkpoint a cada geracao
    if cfg.painel, painel_ga(R, cfg); end

    if Jb < melhor - 1e-6, melhor = Jb; sem_melhora = 0; else, sem_melhora = sem_melhora + 1; end
    if g == cfg.n_ger || sem_melhora >= cfg.estagnacao, break, end

    % ---- proxima geracao
    [~, ord] = sort(J);
    elite = ord(1:cfg.n_elite);
    sigma = cfg.sigma_mut(1) + (cfg.sigma_mut(2) - cfg.sigma_mut(1))*g/max(cfg.n_ger - 1, 1);
    nf = np - cfg.n_elite;
    F  = zeros(nf + mod(nf, 2), nv);
    for i = 1:2:nf
        p1 = X(torneio(J, cfg.k_torneio), :);
        p2 = X(torneio(J, cfg.k_torneio), :);
        if rand < cfg.p_cruz
            d  = abs(p1 - p2);
            lo = min(p1, p2) - cfg.alfa_blx*d;
            hi = max(p1, p2) + cfg.alfa_blx*d;
            p1 = lo + rand(1, nv).*(hi - lo);
            p2 = lo + rand(1, nv).*(hi - lo);
        end
        F(i:i+1, :) = [p1; p2];
    end
    F = F(1:nf, :);
    m = rand(size(F)) < cfg.p_mut;
    F = F + m.*randn(size(F)).*(sigma*faixa);
    F = min(max(F, cfg.lb), cfg.ub);
    X = [X(elite, :); F];
end
end

function i = torneio(J, k)
c = randperm(numel(J), k);
[~, b] = min(J(c));
i = c(b);
end
