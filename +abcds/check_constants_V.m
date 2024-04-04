% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [constants_are_valid] = check_constants_V(delta_lower, delta_upper, xi_V, rho_w_V)
    constants_are_valid = all(delta_lower > 0) && all(delta_upper >= delta_lower) && all(xi_V > 0) && all(rho_w_V >= 0);
    if ~constants_are_valid
        return;
    end

    num_subsystems = size(xi_V, 1);

    diag_xi_V = diag(xi_V);
    lambda_V = eye(num_subsystems) + diag_xi_V;

    rho_w_V_tmp = repmat(rho_w_V, 1, num_subsystems);
    delta_lower_tmp = repmat(transpose(delta_lower), num_subsystems, 1);
    delta_V_offdiag_mask = ones(num_subsystems, num_subsystems) - eye(num_subsystems);
    delta_V_offdiag = (rho_w_V_tmp ./ delta_lower_tmp) .* delta_V_offdiag_mask;
    delta_V = delta_V_offdiag;

    condition_lhs = sum(- lambda_V + delta_V, 2);

    abcds.util.log_msg("pi_i=%s", mat2str(condition_lhs));

    constants_are_valid =  all(max(condition_lhs) < -1);
end