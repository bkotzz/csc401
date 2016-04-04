function b = calculate_b(X, theta, M)
    % X: T x D
    X_size = size(X);
    T = X_size(1);
    D = X_size(2);
    
    b = zeros(T, M);
    
    for m=1:M
        % Compute b per dimension
        
        mu_m = theta.means(:, m); % D x 1
        rep_mu_m = repmat(mu_m.', T, 1); % T x D
        
        cov_m = diag(theta.cov(:, :, m)); % D x 1
        rep_cov_m = repmat(cov_m.', T, 1); % T x D
        
        b_m_per_d = normpdf(X, rep_mu_m, rep_cov_m); % T x D 

        % Since we assume dimensional independence, take product across
        % all dimensions to get b.
        b_m = prod(b_m_per_d, 2); % T x 1

        b(:, m) = b_m;
    end
end

