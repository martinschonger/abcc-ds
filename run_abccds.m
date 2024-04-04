% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [general_opts, result, debug_output] = run_abccds(general_opts, problem_opts, lyapunov_opts, barrier_opts, solver_opts, pre_opts)
% Run Compositional ABC-DS
% Wrapper for abccds()

arguments
    general_opts.timestamp string
    general_opts.seed{mustBeInteger} = 13
    general_opts.output_root_path = fullfile(abcds.util.constants.OUTPUT_PATH, 'comp', filesep)
    general_opts.data abcds.data.data = abcds.data.lasa(1)
    general_opts.generate_plots = true
    problem_opts.f_fh
    problem_opts.i_idxs
    problem_opts.w
    problem_opts.deg_f
    problem_opts.epsilon
    lyapunov_opts.enable_lyapunov = true
    lyapunov_opts.deg_V
    lyapunov_opts.delta_lower
    lyapunov_opts.delta_upper
    lyapunov_opts.xi_V
    lyapunov_opts.rho_w_V
    barrier_opts.deg_B
    barrier_opts.deg_B_slack
    barrier_opts.alpha
    barrier_opts.xi_B
    barrier_opts.sigma
    barrier_opts.phi
    barrier_opts.rho_w_B
    barrier_opts.X_i cell = {{}} % of multisets, if populated must be of length num_subsystems
    barrier_opts.W_i cell % of multisets
    barrier_opts.X_0 cell % of multisets
    barrier_opts.X_u cell % of multisets
    solver_opts.PBM_MAX_ITER
    solver_opts.PEN_UP
    solver_opts.PRECISION_2
    solver_opts.UM_MAX_ITER
    pre_opts.pre cell = {}
end

result = struct;
debug_output = struct;

setup;
rng(general_opts.seed, 'twister');

%%
if ~isfield(general_opts, "timestamp")
    general_opts.timestamp = abcds.util.get_formatted_timestamp('file');
end
mkdir(general_opts.output_root_path, general_opts.timestamp);
output_root_path_final = fullfile(general_opts.output_root_path, general_opts.timestamp, filesep);
diary_filename = fullfile(output_root_path_final, 'log.txt');
diary(diary_filename);

tmp_path_for_log = {dir(output_root_path_final).folder};
tmp_path_for_log = tmp_path_for_log{1};
abcds.util.log_msg("Output directory: %s", tmp_path_for_log);
general_opts_for_log = general_opts;
general_opts_for_log.output_root_path = strrep(general_opts.output_root_path, '\', '\\');
abcds.util.log_msg("Options:\n%s", abcds.util.struct_to_str(general_opts_for_log, "\n"));

dim = general_opts.data.dim();
local_data = copy(general_opts.data);
local_data.shift_me();
local_data.scale_me();
[~, local_Pos, local_Vel, ~] = local_data.get_concatenated();

%% problem_opts
num_subsystems = length(problem_opts.i_idxs);

if isfield(problem_opts, 'f_fh')
    scalefact = local_data.state_maxnorm;
    shift = -local_data.shift;
    debug_output.problem_opts_f_fh_original = problem_opts.f_fh;
    problem_opts.f_fh = @(x) problem_opts.f_fh((x.*scalefact) + shift) ./ scalefact;
end

% w_ij:  connection from j to i
if ~isfield(problem_opts, 'w')
    % if not specified otherwise, assume full connection matrix
    w_mask = ones(num_subsystems, num_subsystems) - eye(num_subsystems);
    problem_opts.w = repmat((1:num_subsystems).', 1, num_subsystems) .* w_mask;
end
abcds.util.log_msg("Problem options:\n%s", abcds.util.struct_to_str(problem_opts, "\n"));
problem_opts_cell = abcds.util.struct_to_named_cellarray(problem_opts);

w_idxs = {};
for i = 1:num_subsystems
    w_idx_tmp = problem_opts.w(:, i).';
    w_idx_tmp2 = w_idx_tmp(w_idx_tmp > 0);
    w_idx = [problem_opts.i_idxs{w_idx_tmp2}];
    w_idxs{i} = w_idx;
end

%% lyapunov_opts
if lyapunov_opts.enable_lyapunov
    if ~isfield(lyapunov_opts, "delta_lower")
        lyapunov_opts.delta_lower = 1e-6 * ones(num_subsystems, 1); % > 0
    end
    if ~isfield(lyapunov_opts, "delta_upper")
        delta_upper_tmp = 1e6 * ones(num_subsystems, 1);
        lyapunov_opts.delta_upper = lyapunov_opts.delta_lower + delta_upper_tmp; % > 0
    end
    if ~isfield(lyapunov_opts, "xi_V")
        lyapunov_opts.xi_V = 0.0 * ones(num_subsystems, 1) + eps; % > 0
    end
    if ~isfield(lyapunov_opts, "rho_w_V")
        lyapunov_opts.rho_w_V = 0.0 * ones(num_subsystems, 1); % >= 0
    end
    abcds.util.log_msg("Compositional Lyapunov options:\n%s", abcds.util.struct_to_str(lyapunov_opts, "\n"));
end
lyapunov_opts_cell = abcds.util.struct_to_named_cellarray(lyapunov_opts);

%% barrier_opts
enable_barrier = ~cellfun(@isempty, barrier_opts.X_i);
if any(enable_barrier)
    num_subsystems_with_barrier = sum(enable_barrier);

    % any values where enable_barrier(i) == false are ignored
    if ~isfield(barrier_opts, "alpha")
        barrier_opts.alpha = Inf * ones(num_subsystems, 1); % > 0
    end
    if ~isfield(barrier_opts, "xi_B")
        barrier_opts.xi_B = 1e-6 * ones(num_subsystems, 1); % > 0
    end
    if ~isfield(barrier_opts, "sigma")
        barrier_opts.sigma = 1 * ones(num_subsystems, 1); % > 0; 0.0 * ones(num_subsystems, 1) + eps
    end
    if ~isfield(barrier_opts, "phi")
        barrier_opts.phi = 1 * ones(num_subsystems, 1) + 1e-3; % > 0; 1e-6 * ones(num_subsystems, 1) + eps
    end
    if ~isfield(barrier_opts, "rho_w_B")
        barrier_opts.rho_w_B = 0.0 * ones(num_subsystems, 1); % >= 0
    end

    for i = 1:num_subsystems
        if enable_barrier(i)
            for j = 1:length(barrier_opts.X_i{i}.sets)
                if isa(barrier_opts.X_i{i}.sets{j}, 'abcds.set.eval_later')
                    barrier_opts.X_i{i}.sets{j} = eval(barrier_opts.X_i{i}.sets{j}.eval_expr);
                end
            end
            for j = 1:length(barrier_opts.W_i{i}.sets)
                if isa(barrier_opts.W_i{i}.sets{j}, 'abcds.set.eval_later')
                    barrier_opts.W_i{i}.sets{j} = eval(barrier_opts.W_i{i}.sets{j}.eval_expr);
                end
            end
            for j = 1:length(barrier_opts.X_0{i}.sets)
                if isa(barrier_opts.X_0{i}.sets{j}, 'abcds.set.eval_later')
                    barrier_opts.X_0{i}.sets{j} = eval(barrier_opts.X_0{i}.sets{j}.eval_expr);
                end
            end
            for j = 1:length(barrier_opts.X_u{i}.sets)
                if isa(barrier_opts.X_u{i}.sets{j}, 'abcds.set.eval_later')
                    barrier_opts.X_u{i}.sets{j} = eval(barrier_opts.X_u{i}.sets{j}.eval_expr);
                end
            end
        end
    end

    abcds.util.log_msg("Compositional Barrier options:\n%s", abcds.util.struct_to_str(barrier_opts, "\n"));

    barrier_opts_mod = barrier_opts;
    for i = 1:num_subsystems
        if enable_barrier(i)
            local_scalefact = local_data.state_maxnorm(problem_opts.i_idxs{i});
            local_shift = -local_data.shift(problem_opts.i_idxs{i});
            barrier_opts_mod.X_i{i} = copy(barrier_opts.X_i{i});
            barrier_opts_mod.X_i{i}.shift_me(local_shift);
            barrier_opts_mod.X_i{i}.scale_me(local_scalefact);
            debug_output.X_i_scaled{i} = copy(barrier_opts_mod.X_i{i});
            barrier_opts_mod.X_i{i} = barrier_opts_mod.X_i{i}.to_cell();
            barrier_opts_mod.W_i{i} = copy(barrier_opts.W_i{i});
            barrier_opts_mod.W_i{i}.shift_me(-local_data.shift([problem_opts.i_idxs{i}, w_idxs{i}]));
            barrier_opts_mod.W_i{i}.scale_me(local_data.state_maxnorm([problem_opts.i_idxs{i}, w_idxs{i}]));
            debug_output.W_i_scaled{i} = copy(barrier_opts_mod.W_i{i});
            barrier_opts_mod.W_i{i} = barrier_opts_mod.W_i{i}.to_cell();
            barrier_opts_mod.X_0{i} = copy(barrier_opts.X_0{i});
            barrier_opts_mod.X_0{i}.shift_me(local_shift);
            barrier_opts_mod.X_0{i}.scale_me(local_scalefact);
            debug_output.X_0_scaled{i} = copy(barrier_opts_mod.X_0{i});
            barrier_opts_mod.X_0{i} = barrier_opts_mod.X_0{i}.to_cell();
            barrier_opts_mod.X_u{i} = copy(barrier_opts.X_u{i});
            barrier_opts_mod.X_u{i}.shift_me(local_shift);
            barrier_opts_mod.X_u{i}.scale_me(local_scalefact);
            debug_output.X_u_scaled{i} = copy(barrier_opts_mod.X_u{i});
            barrier_opts_mod.X_u{i} = barrier_opts_mod.X_u{i}.to_cell();
        end
        % otherwise: empty cell array 'inherited' from barrier_opts
    end
else
    barrier_opts_mod = struct;
end
barrier_opts_cell = abcds.util.struct_to_named_cellarray(barrier_opts_mod);

%% solver_opts
solver_opts_cell = abcds.util.struct_to_named_cellarray(solver_opts);

history = {};
next_pre = {};
for pre_idx = 1:length(pre_opts.pre)
    cur_pre = pre_opts.pre{pre_idx};
    [f_fh, V_fh, V_i_fh, B_fh, B_i_fh, ~, pre_debug_output] = abcds.abccds(local_Pos, local_Vel, problem_opts_cell{:}, lyapunov_opts_cell{:}, barrier_opts_cell{:}, solver_opts_cell{:}, cur_pre.overwrite{:}, pre = next_pre); %#ok<ASGLU>
    history{end+1} = pre_debug_output;
    next_pre = {};
    for i = 1:num_subsystems
        next_pre{i} = struct();
        if isfield(cur_pre, 'keep')
            if any(strcmp(cur_pre.keep, 'f_i_c_var'))
                next_pre{i}.f_i_c_var = history{end}.abccds_i{i}.f_i_c_var;
                next_pre{i}.f_i_monomials = history{end}.abccds_i{i}.f_i_monomials;
                next_pre{i}.f_i_x = history{end}.abccds_i{i}.f_i_x;
            end
        end
    end
end
debug_output.pre = history;

%% solve optimization problems
[f_fh, V_fh, V_i_fh, B_fh, B_i_fh, opts_returned_by_abccds, debug_output.abccds] = abcds.abccds(local_Pos, local_Vel, problem_opts_cell{:}, lyapunov_opts_cell{:}, barrier_opts_cell{:}, solver_opts_cell{:}, pre = next_pre);

generate_output = true;
debug_output.generate_output = generate_output;

shift = local_data.shift;
scalefact = 1.0 ./ local_data.state_maxnorm;
inv_scalefact_vel = local_data.vel_maxnorm;
debug_output.f_fh_original = f_fh;
f_fh = @(x) f_fh((x + shift).*scalefact) .* inv_scalefact_vel;
result.f_fh = f_fh;

%%
function_name = abcds.util.constants.F_VAR;
if generate_output
    writelines(abcds.util.str_arr_to_lambda(abcds.util.mvfun_to_str_arr(f_fh, dim)), fullfile(output_root_path_final, function_name+"_lambda.m"), LineEnding = "\n", TrailingLineEndingRule = "never");

    rep_strs = ["x", "y", "z", "a", "b", "g"];
    tmp = abcds.util.mvfun_to_str_arr(f_fh, dim, vectorize=false);
    for d = dim:-1:1
        tmp = replace(tmp, "x"+num2str(d), rep_strs(d));
    end
    writelines(tmp, fullfile(output_root_path_final, function_name+"_robot.txt"), LineEnding = "\n", TrailingLineEndingRule = "never");
end

x_sym_i = {};
f_sym_i = {};
for i = 1:num_subsystems
    x_sym_i{i} = vpa(sym(abcds.util.constants.STATE_VAR, [dim, 1], 'real'), abcds.util.constants.PRECISION);
    f_sym_i{i} = debug_output.abccds.f_i_fh{i}(x_sym_i{i});
end

%% V
if lyapunov_opts.enable_lyapunov
    debug_output.V_fh_original = V_fh;
    V_fh = @(x) V_fh((x + shift).*scalefact);
    result.V_fh = V_fh;

    function_name = abcds.util.constants.LYAP_VAR;
    if generate_output
        writelines(abcds.util.str_arr_to_lambda(abcds.util.mvfun_to_str_arr(V_fh, dim)), fullfile(output_root_path_final, function_name+"_lambda.m"), LineEnding = "\n", TrailingLineEndingRule = "never");
    end
    
    V_sym_i = {};
    dVdx_sym_i = {};
    Vdot_sym_i = {};
    for i = 1:num_subsystems
        V_sym_i{i} = V_i_fh{i}(x_sym_i{i}(1:length(problem_opts.i_idxs{i})));
        dVdx_sym_i{i} = jacobian(V_sym_i{i}, x_sym_i{i}(1:length(problem_opts.i_idxs{i})))';
        Vdot_sym_i{i} = sum(dVdx_sym_i{i}.*f_sym_i{i}, 1);
    end

    for i = 1:num_subsystems
        dim_i = length(problem_opts.i_idxs{i});

        debug_output.V_i_fh_original{i} = V_i_fh{i};
        V_i_fh{i} = @(x) V_i_fh{i}((x + shift(problem_opts.i_idxs{i})) .* scalefact(problem_opts.i_idxs{i}));
        result.V_i_fh{i} = V_i_fh{i};

        function_name = abcds.util.constants.LYAP_VAR + "_" + int2str(i);
        if generate_output
            writelines(abcds.util.str_arr_to_lambda(abcds.util.mvfun_to_str_arr(V_i_fh{i}, dim_i)), fullfile(output_root_path_final, function_name+"_lambda.m"), LineEnding = "\n", TrailingLineEndingRule = "never");
        end
    end
end

%% B
if any(enable_barrier)
    debug_output.B_fh_original = B_fh;
    B_fh = @(x) B_fh((x + shift).*scalefact);
    result.B_fh = B_fh;

    function_name = abcds.util.constants.BARR_VAR;
    if generate_output
        writelines(abcds.util.str_arr_to_lambda(abcds.util.mvfun_to_str_arr(B_fh, dim)), fullfile(output_root_path_final, function_name+"_lambda.m"), LineEnding = "\n", TrailingLineEndingRule = "never");
    end

    B_sym_i = {};
    dBdx_sym_i = {};
    Bdot_sym_i = {};
    for i = 1:num_subsystems
        B_sym_i{i} = B_i_fh{i}(x_sym_i{i}(1:length(problem_opts.i_idxs{i})));
        dBdx_sym_i{i} = jacobian(B_sym_i{i}, x_sym_i{i}(1:length(problem_opts.i_idxs{i})))';
        Bdot_sym_i{i} = sum(dBdx_sym_i{i}.*f_sym_i{i}, 1);
    end

    for i = 1:num_subsystems
        if enable_barrier(i)
            dim_i = length(problem_opts.i_idxs{i});

            debug_output.B_i_fh_original{i} = B_i_fh{i};
            B_i_fh{i} = @(x) B_i_fh{i}((x + shift(problem_opts.i_idxs{i})) .* scalefact(problem_opts.i_idxs{i}));
            result.B_i_fh{i} = B_i_fh{i};

            function_name = abcds.util.constants.BARR_VAR + "_" + int2str(i);
            if generate_output
                writelines(abcds.util.str_arr_to_lambda(abcds.util.mvfun_to_str_arr(B_i_fh{i}, dim_i)), fullfile(output_root_path_final, function_name+"_lambda.m"), LineEnding = "\n", TrailingLineEndingRule = "never");
            end
        end
    end
end

if generate_output && general_opts.generate_plots
    %% sample trajectories from estimated DS
    initial_set_center_est = general_opts.data.x0_mean();
    [pos_est, vel_est, tvec_est] = abcds.util.integrate_over_time(f_fh, initial_set_center_est, general_opts.data.target);
    dat_est = abcds.data.data(pos = {pos_est}, vel = {vel_est}, tvec = {tvec_est});

    %% plot individual dimensions over time (using general w)
    fig = plot_indiv_dims_over_time(general_opts.data, dat_est, problem_opts.i_idxs);
    figure_to_file2(fig, fullfile(output_root_path_final, 'pos_over_time'), format='-dpng');
    close(fig);

    %% plot subsystems
    fig = plot_experiment_subsystems(general_opts, problem_opts, lyapunov_opts, barrier_opts, result, dat_est=dat_est, limit_fact=1.2);
    figure_to_file2(fig, fullfile(output_root_path_final, 'pos_3D'), format='-dpng');
    close(fig);

    %% debug plots
    % plot_experiment_debug_subsystems(general_opts, problem_opts, lyapunov_opts, barrier_opts, result, output_root_path_final, dat_est=dat_est);

    %% debug plots: final V and B
    % plot_experiment_debug(general_opts, problem_opts, lyapunov_opts, barrier_opts, result, output_root_path_final, dat_est=dat_est);
end

%%
save(fullfile(output_root_path_final, 'opts'), "general_opts", "problem_opts", "lyapunov_opts", "barrier_opts", "solver_opts", "opts_returned_by_abccds", "-v7.3", "-nocompression");
save(fullfile(output_root_path_final, 'result'), "result", "-v7.3", "-nocompression");
yalmip clear;
save(fullfile(output_root_path_final, 'debug_output'), "debug_output", "-v7.3", "-nocompression");
diary off;

if batchStartupOptionUsed
    quit force;
end

end

%#ok<*AGROW>
%#ok<*BDSCA>