% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [f_fh, V_fh, V_i_fh, B_fh, B_i_fh, opts, debug_output] = abccds(x_ref, x_dot_ref, problem_opts, lyapunov_opts, barrier_opts, solver_opts, pre_opts)
% Compute f, V, and B for compositional ABC-DS
%
% :returns:
%   - **f_fh** (:mat:class:`function handle`) -- Dynamical system f.
%   - **V_fh** (:mat:class:`function handle`) -- Lyapunov function V.
%   - **V_i_fh** (:mat:class:`cell array` of :mat:class:`function handle`) -- Subsystem Lyapunov functions V_i.
%   - **B_fh** (:mat:class:`function handle`) -- Barrier certificate B.
%   - **B_i_fh** (:mat:class:`cell array` of :mat:class:`function handle`) -- Subsystem Lyapunov functions B_i.
%   - **opts** (:mat:class:`struct`) -- Struct containing structs corresponding to the input options structs, extended by any default argument values.
%   - **debug_output** (:mat:class:`struct`).

arguments
    x_ref double % array of size (dim, :)
    x_dot_ref double % array of size (dim, :)
    problem_opts.i_idxs cell % of arrays
    problem_opts.w{mustBeInteger} % array (matrix); TODO: potentially extend with connection weights
    problem_opts.f_fh % function handle
    problem_opts.deg_f % array of degrees
    problem_opts.epsilon
    lyapunov_opts.enable_lyapunov = true
    lyapunov_opts.deg_V % array of degrees
    lyapunov_opts.delta_lower
    lyapunov_opts.delta_upper
    lyapunov_opts.xi_V
    lyapunov_opts.rho_w_V
    barrier_opts.deg_B % array of degrees
    barrier_opts.deg_B_slack % array of degrees
    barrier_opts.alpha
    barrier_opts.xi_B
    barrier_opts.sigma
    barrier_opts.phi
    barrier_opts.rho_w_B
    barrier_opts.X_i cell = {{}} % of cell arrays of function handles
    barrier_opts.W_i cell % of cell arrays of function handles
    barrier_opts.X_0 cell % of cell arrays of function handles
    barrier_opts.X_u cell % of cell arrays of function handles
    solver_opts.PBM_MAX_ITER
    solver_opts.PEN_UP
    solver_opts.PRECISION_2
    solver_opts.UM_MAX_ITER
    pre_opts.pre cell = {}
end

debug_output = struct;

dim = size(x_ref, 1);

%% define subsystems and interconnection
if ~isfield(problem_opts, 'i_idxs')
    problem_opts.i_idxs = {1:dim};
end

num_subsystems = size(problem_opts.i_idxs, 2);

i_idxs_str = "{";
for i = 1:num_subsystems
    i_idxs_str = i_idxs_str + mat2str(problem_opts.i_idxs{i});
    if i < num_subsystems
        i_idxs_str = i_idxs_str + ", ";
    end
end
i_idxs_str = i_idxs_str + "}";
abcds.util.log_msg("Subsystem assignment: i_idxs=%s", i_idxs_str);

% w_ij:  connection from j to i
if ~isfield(problem_opts, 'w')
    w_mask = ones(num_subsystems, num_subsystems) - eye(num_subsystems);
    problem_opts.w = repmat((1:num_subsystems).', 1, num_subsystems) .* w_mask;
end
abcds.util.log_msg("Subsystem interconnection: w=%s", mat2str(problem_opts.w));

if lyapunov_opts.enable_lyapunov
    assert(abcds.check_constants_V(lyapunov_opts.delta_lower, lyapunov_opts.delta_upper, lyapunov_opts.xi_V, lyapunov_opts.rho_w_V));
    abcds.util.log_msg("Compositional Lyapunov constants:\n%s", abcds.util.struct_to_str(lyapunov_opts, "\n"));
end

enable_barrier = ~cellfun(@isempty, barrier_opts.X_i);
if any(enable_barrier)
    num_subsystems_with_barrier = sum(enable_barrier);
    assert(abcds.check_constants_B(barrier_opts.alpha(enable_barrier), barrier_opts.xi_B(enable_barrier), barrier_opts.sigma(enable_barrier), barrier_opts.phi(enable_barrier), barrier_opts.rho_w_B(enable_barrier)));
    abcds.util.log_msg("Compositional Barrier constants:\n%s", abcds.util.struct_to_str(barrier_opts, "\n"));
end

%% solve optimization problems
f_i_fh = {};
V_i_fh = {};
B_i_fh = {};

w_idxs = {};
for i = 1:num_subsystems
    i_idx = problem_opts.i_idxs{i};
    w_idx_tmp = problem_opts.w(:, i).';
    w_idx_tmp2 = w_idx_tmp(w_idx_tmp > 0);
    w_idx = [problem_opts.i_idxs{w_idx_tmp2}];
    w_idxs{i} = w_idx;

    problem_i_opts = struct;
    if isfield(problem_opts, 'f_fh')
        paren = @(x, idxs) x(idxs, :);

        tmp_arr = [i_idx, w_idx];
        tmp_arr2 = [];
        for j = 1:dim
            tmp = find(tmp_arr - j == 0);
            if ~isempty(tmp)
                tmp_arr2(end+1) = tmp;
                assert(length(tmp) == 1, 'Check me!');
            else
                error('Check me!');
            end
        end

        problem_i_opts.f_i_fh = @(x) paren(problem_opts.f_fh(x(tmp_arr2)), i_idx);
    end
    if isfield(problem_opts, 'deg_f')
        problem_i_opts.deg_f_i = problem_opts.deg_f(i);
    end
    if isfield(problem_opts, 'epsilon')
        problem_i_opts.epsilon = problem_opts.epsilon;
    end
    problem_i_opts_cell = abcds.util.struct_to_named_cellarray(problem_i_opts);

    lyapunov_i_opts = struct;
    lyapunov_i_opts.enable_lyapunov = lyapunov_opts.enable_lyapunov;
    if lyapunov_i_opts.enable_lyapunov
        if isfield(lyapunov_opts, 'deg_V')
            lyapunov_i_opts.deg_V_i = lyapunov_opts.deg_V(i);
        end
        lyapunov_i_opts.delta_lower_i = lyapunov_opts.delta_lower(i);
        lyapunov_i_opts.delta_upper_i = lyapunov_opts.delta_upper(i);
        lyapunov_i_opts.xi_V_i = lyapunov_opts.xi_V(i);
        lyapunov_i_opts.rho_w_V_i = lyapunov_opts.rho_w_V(i);
    end
    lyapunov_i_opts_cell = abcds.util.struct_to_named_cellarray(lyapunov_i_opts);

    barrier_i_opts = struct;
    if any(enable_barrier) && enable_barrier(i)
        if isfield(barrier_opts, 'deg_B')
            barrier_i_opts.deg_B_i = barrier_opts.deg_B(i);
        end
        if isfield(barrier_opts, 'deg_B_slack')
            barrier_i_opts.deg_B_i_slack = barrier_opts.deg_B_slack(i);
        end
        barrier_i_opts.alpha_i = barrier_opts.alpha(i);
        barrier_i_opts.xi_B_i = barrier_opts.xi_B(i);
        barrier_i_opts.sigma_i = barrier_opts.sigma(i);
        barrier_i_opts.phi_i = barrier_opts.phi(i);
        barrier_i_opts.rho_w_B_i = barrier_opts.rho_w_B(i);

        barrier_i_opts.X_i = barrier_opts.X_i{i};
        barrier_i_opts.W_i = barrier_opts.W_i{i};
        barrier_i_opts.X_0 = barrier_opts.X_0{i};
        barrier_i_opts.X_u = barrier_opts.X_u{i};
    end
    barrier_i_opts_cell = abcds.util.struct_to_named_cellarray(barrier_i_opts);

    if length(pre_opts.pre) >= i % TODO: ensure that length(pre_opts.pre) == num_subsystems?
        pre_struct = pre_opts.pre{i};
    else
        pre_struct = struct();
    end

    %% solver_opts
    solver_opts_mod = solver_opts;
    if isfield(solver_opts, 'PBM_MAX_ITER') && length(solver_opts.PBM_MAX_ITER) > 1
        solver_opts_mod.PBM_MAX_ITER = solver_opts.PBM_MAX_ITER(i);
    end
    if isfield(solver_opts, 'PEN_UP') && length(solver_opts.PEN_UP) > 1
        solver_opts_mod.PEN_UP = solver_opts.PEN_UP(i);
    end
    if isfield(solver_opts, 'PRECISION_2') && length(solver_opts.PRECISION_2) > 1
        solver_opts_mod.PRECISION_2 = solver_opts.PRECISION_2(i);
    end
    if isfield(solver_opts, 'UM_MAX_ITER') && length(solver_opts.UM_MAX_ITER) > 1
        solver_opts_mod.UM_MAX_ITER = solver_opts.UM_MAX_ITER(i);
    end
    solver_opts_cell = abcds.util.struct_to_named_cellarray(solver_opts_mod);

    [f_i_fh{i}, V_i_fh{i}, B_i_fh{i}, ~, debug_output.abccds_i{i}] = abcds.abccds_i(x_ref([i_idx, w_idx], :), x_dot_ref(i_idx, :), problem_i_opts_cell{:}, lyapunov_i_opts_cell{:}, barrier_i_opts_cell{:}, solver_opts_cell{:}, pre = pre_struct);
    debug_output.f_i_fh{i} = f_i_fh{i};
end

%%
f_fh_str = '@(x) [';
for i = 1:num_subsystems
    f_fh_str = strcat(f_fh_str, 'f_i_fh{', num2str(i), '}(x([problem_opts.i_idxs{', int2str(i), '}, w_idxs{', int2str(i), '}],:));');
end
f_fh_str = strcat(f_fh_str, ']');
f_fh = eval(f_fh_str);
abcds.util.log_msg("Computed function:\n%s", abcds.util.str_arr_to_str(abcds.util.mvfun_to_str_arr(f_fh, dim)));

%% V
if lyapunov_opts.enable_lyapunov
    V_fh_str = '@(x) ';
    for i = 1:num_subsystems
        V_fh_str = strcat(V_fh_str, 'V_i_fh{', num2str(i), '}(x(problem_opts.i_idxs{', int2str(i), '},:))');
        if i < num_subsystems
            V_fh_str = strcat(V_fh_str, '+');
        end
    end
    V_fh = eval(V_fh_str);
    abcds.util.log_msg("Computed Lyapunov function:\n%s", abcds.util.str_arr_to_str(abcds.util.mvfun_to_str_arr(V_fh, dim), function_name = abcds.util.constants.LYAP_VAR));
else
    V_fh = [];
end

%% B
if any(enable_barrier)
    B_fh_str = '@(x) ';
    tmp_idx = 1;
    for i = 1:num_subsystems
        if enable_barrier(i)
            B_fh_str = strcat(B_fh_str, 'B_i_fh{', num2str(i), '}(x(problem_opts.i_idxs{', int2str(i), '},:))');
            if tmp_idx < num_subsystems_with_barrier
                B_fh_str = strcat(B_fh_str, '+');
            end
            tmp_idx = tmp_idx + 1;
        end
    end
    B_fh = eval(B_fh_str);
    abcds.util.log_msg("Computed Barrier function:\n%s", abcds.util.str_arr_to_str(abcds.util.mvfun_to_str_arr(B_fh, dim), function_name = abcds.util.constants.BARR_VAR));
else
    B_fh = [];
end

opts.problem_opts = problem_opts;
opts.lyapunov_opts = lyapunov_opts;
opts.barrier_opts = barrier_opts;
opts.solver_opts = solver_opts;

end

%#ok<*AGROW>