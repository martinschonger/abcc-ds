% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [constants_are_valid] = check_constants_B(alpha, xi_B, sigma, phi, rho_w_B)
    constants_are_valid = all(alpha > 0) && all(xi_B > 0) && all(sigma > 0) && all(phi > 0) && all(rho_w_B >= 0);
    if ~constants_are_valid
        return;
    end

    num_subsystems = size(xi_B, 1);

    constants_are_valid = sum(phi, 1) > sum(sigma, 1);
    if ~constants_are_valid
        return;
    end


    diag_xi_B = diag(xi_B);
    lambda_B = eye(num_subsystems) + diag_xi_B;

    rho_w_B_tmp = repmat(rho_w_B, 1, num_subsystems);
    alpha_tmp = repmat(transpose(alpha), num_subsystems, 1);
    delta_B_offdiag_mask = ones(num_subsystems, num_subsystems) - eye(num_subsystems);
    delta_B_offdiag = (rho_w_B_tmp ./ alpha_tmp) .* delta_B_offdiag_mask;
    delta_B = delta_B_offdiag;

    condition_lhs = sum(- lambda_B + delta_B, 2);

    abcds.util.log_msg("pi_i=%s", mat2str(condition_lhs));

    constants_are_valid =  all(max(condition_lhs) < -1);
end