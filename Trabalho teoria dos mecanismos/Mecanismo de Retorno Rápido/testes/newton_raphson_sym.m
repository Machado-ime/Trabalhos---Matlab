function [q_sol, info] = newton_raphson_sym(phi, q, q0, opts)
%NEWTON_RAPHSON_SYM Resolve phi(q) = 0 pelo metodo de Newton-Raphson.
%
%   [q_sol, info] = NEWTON_RAPHSON_SYM(phi, q, q0) resolve o sistema de
%   equacoes nao lineares phi(q) = 0 a partir da estimativa inicial q0.
%
%   ENTRADAS
%       phi - vetor coluna SIMBOLICO (m x 1) com as equacoes de restricao.
%             Nao pode conter parametros livres: use subs() antes para
%             atribuir valores numericos aos comprimentos, distancias, etc.
%       q   - vetor coluna SIMBOLICO (n x 1) com as coordenadas generalizadas
%       q0  - vetor coluna NUMERICO  (n x 1) com a estimativa inicial
%
%   OPCOES (pares nome-valor)
%       'tol'      - tolerancia de convergencia          (padrao 1e-10)
%       'max_iter' - numero maximo de iteracoes          (padrao 50)
%       'verbose'  - imprime tabela de iteracoes         (padrao false)
%
%   SAIDAS
%       q_sol - vetor coluna numerico com a solucao convergida
%       info  - struct com o diagnostico da convergencia:
%               .convergiu  - true/false
%               .iteracoes  - numero de iteracoes gastas
%               .residuo    - norm(phi) na solucao final
%               .historico  - [norm(phi), norm(dq)] por iteracao
%               .Phi_q      - Jacobiana simbolica (reaproveitavel p/ vel/acel)
%
%   METODO (Haug, secao 6.1)
%       Lineariza phi em torno da estimativa atual (Taylor de 1a ordem) e
%       resolve o sistema LINEAR resultante a cada iteracao:
%
%           Phi_q(q_i) * dq = -phi(q_i)
%           q_{i+1} = q_i + dq
%
%   EXEMPLO
%       syms x y
%       q   = [x; y];
%       phi = [x^2 + y^2 - 25; x - y];
%       q_sol = newton_raphson_sym(phi, q, [1; 1])

arguments
    phi
    q
    q0 (:,1) double
    opts.tol      (1,1) double {mustBePositive} = 1e-10
    opts.max_iter (1,1) double {mustBePositive} = 50
    opts.verbose  (1,1) logical = false
end

%% --- normaliza entradas (aceita symfun tambem) ---
if isa(phi, 'symfun'), phi = formula(phi); end
if isa(q,   'symfun'), q   = formula(q);   end
phi = phi(:);
q   = q(:);

n = numel(q);
m = numel(phi);

if numel(q0) ~= n
    error('newton_raphson_sym:dimensao', ...
          'q0 tem %d elementos, mas q tem %d coordenadas.', numel(q0), n);
end

%% --- verifica se sobrou algum parametro simbolico sem valor ---
livres = setdiff(symvar(phi), symvar(q));
if ~isempty(livres)
    error('newton_raphson_sym:parametrosLivres', ...
        ['phi ainda contem simbolo(s) sem valor numerico: %s\n' ...
         'Use subs() para atribuir os parametros antes de chamar esta funcao.'], ...
         strjoin(string(livres), ', '));
end

%% --- Jacobiana simbolica e conversao para funcoes numericas rapidas ---
Phi_q = jacobian(phi, q);

phi_fun   = matlabFunction(phi,   'Vars', {q});
Phi_q_fun = matlabFunction(Phi_q, 'Vars', {q});

%% --- iteracao de Newton-Raphson ---
q_i       = q0;
historico = zeros(opts.max_iter, 2);
convergiu = false;

if opts.verbose
    fprintf('\n%5s %16s %16s\n', 'iter', 'norm(phi)', 'norm(dq)');
    fprintf('%s\n', repmat('-', 1, 39));
end

for k = 1:opts.max_iter
    F = reshape(phi_fun(q_i),   m, 1);
    J = reshape(Phi_q_fun(q_i), m, n);

    % avisa se a Jacobiana esta perto de singular (posicao singular do mecanismo)
    if m == n && rcond(J) < 1e-12
        warning('newton_raphson_sym:jacobianaSingular', ...
                'Jacobiana quase singular na iteracao %d (rcond = %.2e).', k, rcond(J));
    end

    dq = -(J \ F);

    if any(~isfinite(dq))
        error('newton_raphson_sym:passoInvalido', ...
              'Passo nao finito na iteracao %d: Jacobiana singular.', k);
    end

    q_i = q_i + dq;

    norm_F  = norm(F);
    norm_dq = norm(dq);
    historico(k,:) = [norm_F, norm_dq];

    if opts.verbose
        fprintf('%5d %16.3e %16.3e\n', k, norm_F, norm_dq);
    end

    if norm_F < opts.tol && norm_dq < opts.tol
        convergiu = true;
        break
    end
end

if ~convergiu
    warning('newton_raphson_sym:naoConvergiu', ...
            'Nao convergiu em %d iteracoes (norm(phi) = %.2e).', ...
            opts.max_iter, norm(reshape(phi_fun(q_i), m, 1)));
end

%% --- saidas ---
q_sol = q_i;

info.convergiu = convergiu;
info.iteracoes = k;
info.residuo   = norm(reshape(phi_fun(q_i), m, 1));
info.historico = historico(1:k, :);
info.Phi_q     = Phi_q;

end
