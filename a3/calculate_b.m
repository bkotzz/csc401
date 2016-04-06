function b = calculate_b(X, theta, M)
    % X: T x D
    X_size = size(X);
    T = X_size(1);
    D = X_size(2);
    
    log_b = zeros(T, M);
    
    for m=1:M
        % Compute b per dimension
        
        mu_m = theta.means(:, m); % D x 1
        rep_mu_m = repmat(mu_m.', T, 1); % T x D
        
        cov_m = diag(theta.cov(:, :, m)); % D x 1
        rep_cov_m = repmat(cov_m.', T, 1); % T x D
        
        log_b(:, m) = logNormPdf(X, rep_mu_m, rep_cov_m);
    end
    
    b = exp(log_b); % T x M
end

function [log_b] = logNormPdf(X, mu, cov)
    % X  : T x D
    % mu : T x D (rep from 1 x D)
    % cov: T x D (rep from 1 x D)
    
    x_minus_mu = X - mu; % T x D
    exponent = (x_minus_mu .* x_minus_mu) ./ cov; % T x D
    log_b_per_t = -0.5 * (exponent + log(2 * pi * cov)); % T x D
    
    % Sum across all dimensions since we assume independence
    log_b = sum(log_b_per_t, 2); % T x 1
end

