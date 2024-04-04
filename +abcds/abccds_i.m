% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [f_i_fh, V_i_fh, B_i_fh, opts, debug_output] = abccds_i(x_ref_xiwi, x_dot_ref_xi, problem_opts, lyapunov_opts, barrier_opts, solver_opts, pre_opts)
% Compute f_i, V_i, and B_i for compositional ABC-DS

arguments
    x_ref_xiwi double % array of size (dim_xiwi, :)
    x_dot_ref_xi double % array of size (dim_xi, :)
    problem_opts.f_i_fh % function handle
    problem_opts.deg_f_i(1, 1) {mustBeInteger}
    problem_opts.epsilon(1, 1) double = 1e-3
    lyapunov_opts.enable_lyapunov{mustBeNumericOrLogical} = true
    lyapunov_opts.deg_V_i(1, 1) {mustBeInteger}
    lyapunov_opts.delta_lower_i(1, 1) double
    lyapunov_opts.delta_upper_i(1, 1) double
    lyapunov_opts.xi_V_i(1, 1) double
    lyapunov_opts.rho_w_V_i(1, 1) double
    barrier_opts.deg_B_i(1, 1) {mustBeInteger}
    barrier_opts.deg_B_i_slack(1, 1) {mustBeInteger} = 2
    barrier_opts.alpha_i(1, 1) double
    barrier_opts.xi_B_i(1, 1) double
    barrier_opts.sigma_i(1, 1) double
    barrier_opts.phi_i(1, 1) double
    barrier_opts.rho_w_B_i(1, 1) double
    barrier_opts.X_i cell = {} % of function handles
    barrier_opts.W_i cell % of function handles
    barrier_opts.X_0 cell % of function handles
    barrier_opts.X_u cell % of function handles
    solver_opts.PBM_MAX_ITER(1, 1) {mustBeInteger} = 50
    solver_opts.PEN_UP(1, 1) {mustBeNumeric} = 0.5
    solver_opts.PRECISION_2(1, 1) {mustBeNumeric} = 1e-6
    solver_opts.UM_MAX_ITER(1, 1) {mustBeInteger} = 100
    pre_opts.pre struct = struct()
end

% returns:
% f_i_fh: function handle
% V_i_fh: function handle
% B_i_fh: function handle
% opts: struct of options structs (useful if any default args are populated and needed outside)
% debug_output

abcds.util.log_msg("Start computation of subsystem");
abcds.util.log_msg("Problem options:\n%s", abcds.util.struct_to_str(problem_opts, "\n"));
if lyapunov_opts.enable_lyapunov
    abcds.util.log_msg("Lyapunov options:\n%s", abcds.util.struct_to_str(lyapunov_opts, "\n"));
end
enable_barrier = ~isempty(barrier_opts.X_i);
if enable_barrier
    abcds.util.log_msg("Barrier options:\n%s", abcds.util.struct_to_str(barrier_opts, "\n"));
end

debug_output = struct;

% attractor is assumed to be at the origin

[dim_xiwi, T] = size(x_ref_xiwi);
dim_xi = size(x_dot_ref_xi, 1);
xi_idx = 1:dim_xi;
wi_idx = dim_xi + 1:dim_xiwi;
x = sdpvar(dim_xiwi, 1);
abcds.util.log_msg("xi_idx=%s, wi_idx=%s", abcds.util.arr_to_str(xi_idx), abcds.util.arr_to_str(wi_idx));

rand_magnitude = 0;

%% Define variables
params = [];
f_i = [];
f_i_c_var = [];
if ~isfield(problem_opts, 'f_i_fh')
    for d = 1:dim_xi
        [f_i_tmp, f_i_c_var_tmp, f_i_monomials] = polynomial(x, problem_opts.deg_f_i, 1); % lower bound on deg is 1 since attractor is assumed to be at the origin
        f_i = [f_i; f_i_tmp];
        f_i_c_var = [f_i_c_var; f_i_c_var_tmp];
    end
    assign(f_i_c_var, (rand(size(f_i_c_var)) - 0.5) * rand_magnitude);
else
    f_i = problem_opts.f_i_fh(x);
    f_i_monomials = [];
end
params = [params; f_i_c_var(:)];
debug_output.f_i_monomials = f_i_monomials;
debug_output.f_i_x = x;
if lyapunov_opts.enable_lyapunov
    [V_i, V_i_c_var, ~] = polynomial(x(xi_idx), lyapunov_opts.deg_V_i, 1); % lower bound on deg is 1 since attractor is assumed to be at the origin
    params = [params; V_i_c_var(:)];
    dVidxi = jacobian(V_i, x(xi_idx))';
    Vdot_i = sum(dVidxi.*f_i, 1);
    assign(V_i_c_var, (rand(size(V_i_c_var)) - 0.5) * rand_magnitude);
end
if enable_barrier
    [B_i, B_i_c_var, ~] = polynomial(x(xi_idx), barrier_opts.deg_B_i);
    params = [params; B_i_c_var(:)];
    dBidxi = jacobian(B_i, x(xi_idx))';
    Bdot_i = sum(dBidxi.*f_i, 1);
    assign(B_i_c_var, (rand(size(B_i_c_var)) - 0.5) * rand_magnitude);
end


% init sdpvars from options struct
if isfield(pre_opts.pre, 'f_i_c_var')
    assert(isfield(pre_opts.pre, 'f_i_monomials'), 'pre_opts.pre.f_i_monomials is required when pre_opts.pre.f_i_c_var is set');
    assert(isfield(pre_opts.pre, 'f_i_x'), 'pre_opts.pre.f_i_x is required when pre_opts.pre.f_i_c_var is set');

    f_i_c_init_tmp = zeros(length(f_i_monomials), dim_xi);
    % Assign the computed coefficient values to the matching coefficients of the higher-deg polynomial
    f_i_c_init_reshaped = reshape(pre_opts.pre.f_i_c_var, length(pre_opts.pre.f_i_c_var)/dim_xi, dim_xi);
    f_i_c_init_monomials_replaced = replace(pre_opts.pre.f_i_monomials, pre_opts.pre.f_i_x, x);
    [idx_from, idx_to] = abcds.util.match_monomials(sdisplay(f_i_c_init_monomials_replaced), sdisplay(f_i_monomials));
    for d = 1:dim_xi
        f_i_c_init_tmp(idx_to, d) = f_i_c_init_reshaped(idx_from, d);
    end
    assign(f_i_c_var, f_i_c_init_tmp(:));
end

%% objective
x_dot = {};
for t = 1:T
    x_dot{end+1} = replace(f_i, x, x_ref_xiwi(:, t));
end
x_dot = cat(2, x_dot{:});
x_dot_error = x_dot - x_dot_ref_xi;
objective = (x_dot_error(:)' * x_dot_error(:)) / T;

%% constraints
constraints = [];
epsilon = problem_opts.epsilon;
normxi = sum(x(xi_idx).^2, 1);
epxi = epsilon * normxi; %#ok<NASGU>
normxiwi = sum(x.^2, 1);
epxiwi = epsilon * normxiwi; %#ok<NASGU>
normwi = sum(x(wi_idx).^2, 1);

% Stability
if lyapunov_opts.enable_lyapunov
    % constraints = [constraints, (replace(V_i, x(xi_idx), attractor(xi_idx)) == 0):'(5c-1)'];  % can omit since assume attractor at origin
    % constraints = [constraints, (replace(V_i, x(xi_idx), zeros(dim_xi, 1)) == 0)];  % can omit since assume attractor at origin
    constraints = [constraints, (sos(V_i-(lyapunov_opts.delta_lower_i+epsilon)*normxi)):'(5c-2)']; % assume attractor at origin
    constraints = [constraints, (sos((lyapunov_opts.delta_upper_i-epsilon)*normxi-V_i)):'(5c-3)']; % assume attractor at origin

    % Lie derivative
    % constraints = [constraints, (replace(Vdot_i, x(xi_idx), attractor(xi_idx)) == 0):'(5d-1)'];  % % can omit since assume attractor at origin
    % constraints = [constraints, (replace(Vdot_i, x(xi_idx), zeros(dim_xi, 1)) == 0)];  % % can omit since assume attractor at origin
    if isempty(wi_idx)
        constraints = [constraints, (sos(-(lyapunov_opts.xi_V_i+epsilon)*V_i-Vdot_i)):'(5d-2)']; % assume attractor at origin
    else
        constraints = [constraints, (sos(-(lyapunov_opts.xi_V_i+epsilon)*V_i+lyapunov_opts.rho_w_V_i*normwi-Vdot_i)):'(5d-2)']; % assume attractor at origin
    end
end

% Barrier
if enable_barrier
    X_i = {};
    W_i = {};
    X_0 = {};
    X_u = {};
    for j = 1:length(barrier_opts.X_i)
        X_i{j} = barrier_opts.X_i{j}(x(xi_idx));
    end
    for j = 1:length(barrier_opts.W_i)
        W_i{j} = barrier_opts.W_i{j}(x);
    end
    for j = 1:length(barrier_opts.X_0)
        X_0{j} = barrier_opts.X_0{j}(x(xi_idx));
    end
    for j = 1:length(barrier_opts.X_u)
        X_u{j} = barrier_opts.X_u{j}(x(xi_idx));
    end

    % X_i
    if ~isinf(-barrier_opts.alpha_i)
        sos_X_i = B_i - (barrier_opts.alpha_i+epsilon) * normxi;
        % slack_X_i = {};
        % slack_X_i_coef = {};
        % for j = 1:length(X_i)
        %     [slack_X_i{j}, slack_X_i_coef{j}, ~] = polynomial(x(xi_idx), barrier_opts.deg_B_i_slack);
        %     params = [params; slack_X_i_coef{j}(:)];
        %     constraints = [constraints, sos(slack_X_i{j})];
        %     sos_X_i = sos_X_i - slack_X_i{j} * X_i{j};
        % end
        constraints = [constraints, (sos(sos_X_i)):'(7)'];
    end

    % initial set
    sos_X_0 = barrier_opts.sigma_i - B_i;
    slack_X_0 = {};
    slack_X_0_coef = {};
    for j = 1:length(X_0)
        [slack_X_0{j}, slack_X_0_coef{j}, ~] = polynomial(x(xi_idx), barrier_opts.deg_B_i_slack);
        params = [params; slack_X_0_coef{j}(:)];
        constraints = [constraints, sos(slack_X_0{j})];
        sos_X_0 = sos_X_0 - slack_X_0{j} * X_0{j};
    end
    constraints = [constraints, (sos(sos_X_0-epsilon)):'(8)'];

    % unsafe set
    sos_X_u = B_i - barrier_opts.phi_i;
    slack_X_u = {};
    slack_X_u_coef = {};
    for j = 1:length(X_u)
        [slack_X_u{j}, slack_X_u_coef{j}, ~] = polynomial(x(xi_idx), barrier_opts.deg_B_i_slack);
        params = [params; slack_X_u_coef{j}(:)];
        constraints = [constraints, sos(slack_X_u{j})];
        sos_X_u = sos_X_u - slack_X_u{j} * X_u{j};
    end
    constraints = [constraints, (sos(sos_X_u-epsilon)):'(9)'];

    % Lie derivative
    sos_B_lie = -(barrier_opts.xi_B_i+epsilon) * B_i - Bdot_i;
    if isempty(wi_idx)
        % sos_B_lie = sos_B_lie;
        % slack_B_lie_X_i = {};
        % slack_B_lie_X_i_coef = {};
        % for j = 1:length(X_i)
        %     [slack_B_lie_X_i{j}, slack_B_lie_X_i_coef{j}, ~] = polynomial(x(xi_idx), barrier_opts.deg_B_i_slack);
        %     params = [params; slack_B_lie_X_i_coef{j}(:)];
        %     constraints = [constraints, sos(slack_B_lie_X_i{j})];
        %     sos_B_lie = sos_B_lie - slack_B_lie_X_i{j} * X_i{j};
        % end
    else
        warning("check if need to combine X_i and W_i for this constraint");
        sos_B_lie = sos_B_lie + barrier_opts.rho_w_B_i * normwi;
        % slack_B_lie_W_i = {};
        % slack_B_lie_W_i_coef = {};
        % for j = 1:length(W_i)
        %     [slack_B_lie_W_i{j}, slack_B_lie_W_i_coef{j}, ~] = polynomial(x, barrier_opts.deg_B_i_slack);
        %     params = [params; slack_B_lie_W_i_coef{j}(:)];
        %     constraints = [constraints, sos(slack_B_lie_W_i{j})];
        %     sos_B_lie = sos_B_lie - slack_B_lie_W_i{j} * W_i{j};
        % end
    end
    constraints = [constraints, (sos(sos_B_lie)):'(10)'];

    B_tmp = 0;
    for t = 1:5:T
        B_tmp = B_tmp + max([0, replace(B_i, x(xi_idx), x_ref_xiwi(xi_idx, t)) - barrier_opts.phi_i]);
    end
    constraints = [constraints, (B_tmp <= 0)];
end


% Solver options
sdp_opts = sdpsettings('solver', 'penbmi', 'verbose', 1, 'debug', 1, 'showprogress', 1, 'usex0', 1, 'warmstart', 1);
sdp_opts = sdpsettings(sdp_opts, 'OUTPUT', 3);
solver_opts_cell = abcds.util.struct_to_named_cellarray(solver_opts);
sdp_opts = sdpsettings(sdp_opts, solver_opts_cell{:});
abcds.util.log_msg("Solver options:\n%s", abcds.util.struct_to_str(solver_opts, "\n"));

% Call solver
abcds.util.log_msg("Start optimization");
tic;
if ~isempty(constraints) && sum(logical(is(constraints, 'sos'))) > 0
    [sol, v, Q, res] = solvesos(constraints, objective, sdp_opts, params);
else
    sol = optimize(constraints, objective, sdp_opts);
    v = [];
    Q = [];
    res = [];
end
debug_output.total_solver_time = toc;
abcds.util.log_msg("Finish optimization");
debug_output.v = v;
debug_output.Q = Q;
debug_output.res = res;

if sol.problem ~= 0
    yalmiperror(sol.problem);
end

% Optimization result
sol.info
if ~isempty(constraints)
    check(constraints)
end
abcds.util.log_msg("Total error: %2.2f, Computation Time: %2.2f", value(objective), sol.solvertime);
abcds.util.log_msg('Total solver time: %2.2f\n', debug_output.total_solver_time);


% For SOS constraints: eigenvalues of Gramians -> compare with size of residual
fprintf('[DEBUG] Validation of SOS constraints:\n');
fprintf(['The relative factors need to be >= 1 for the polynomial\n', ...
    'to be non-negative.\n']);
fprintf('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n');
fprintf('| Idx| Min eigval of Q| Primal residual|  Relative fact.|\n');
fprintf('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n');
min_q_eigvals = [];
primal_res = check(constraints(logical(is(constraints, 'sos'))));
relative_factors = [];
for i = 1:length(Q)
    min_eigval = min(eig(Q{i}));
    min_q_eigvals(end+1) = min_eigval;
    rel_fact = min_eigval / (primal_res(i) * size(Q{i}, 1));
    relative_factors(end+1) = rel_fact;
    fprintf('|%4.0f|%16g|%16g|%16g|  All eigvals of Q: %s\n', i, min_eigval, primal_res(i), rel_fact, mat2str(eig(Q{i})));
end
debug_output.min_q_eigvals = min_q_eigvals;
debug_output.primal_residuals = primal_res';
debug_output.relative_factors = relative_factors;
fprintf('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n');
fprintf('[DEBUG_END]\n');


% Output variables
if ~isempty(f_i_c_var)
    f_i_sdpvar = replace(f_i, f_i_c_var, value(f_i_c_var));
else
    f_i_sdpvar = f_i;
end
f_i_fhm = {};
f_i_fh_str = '@(x) [';
for d = 1:dim_xi
    f_i_fhm{d} = abcds.sdpvar_to_fun_compositional(f_i_sdpvar(d), x);
    f_i_fh_str = strcat(f_i_fh_str, 'f_i_fhm{', num2str(d), '}(x);');
end
f_i_fh_str = strcat(f_i_fh_str, ']');
f_i_fh = eval(f_i_fh_str);
abcds.util.log_msg("Computed function:\n%s", abcds.util.str_arr_to_str(abcds.util.mvfun_to_str_arr(f_i_fh, dim_xiwi), function_name = "f_i"));

if lyapunov_opts.enable_lyapunov
    V_i_sdpvar = replace(V_i, V_i_c_var, value(V_i_c_var));
    V_i_fh = abcds.sdpvar_to_fun_compositional(V_i_sdpvar, x(xi_idx));
    abcds.util.log_msg("Computed Lyapunov function:\n%s", abcds.util.str_arr_to_str(abcds.util.mvfun_to_str_arr(V_i_fh, dim_xi), function_name = "V_i"));
else
    V_i_fh = [];
end

if enable_barrier
    B_i_sdpvar = replace(B_i, B_i_c_var, value(B_i_c_var));
    B_i_fh = abcds.sdpvar_to_fun_compositional(B_i_sdpvar, x(xi_idx));
    abcds.util.log_msg("Computed Barrier function:\n%s", abcds.util.str_arr_to_str(abcds.util.mvfun_to_str_arr(B_i_fh, dim_xi), function_name = "B_i"));
else
    B_i_fh = [];
end

debug_output.f_i_c_var = value(f_i_c_var);

opts.problem_opts = problem_opts;
opts.lyapunov_opts = lyapunov_opts;
opts.barrier_opts = barrier_opts;
opts.solver_opts = solver_opts;

abcds.util.log_msg("Finish computation of subsystem with indices");

end

%#ok<*AGROW>
%#ok<*BDSCA>