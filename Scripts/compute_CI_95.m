function [CI_min,CI_max] = compute_CI_95(odds_ratio,n_cases_exposure,n_control_exposure,n_cases_noexposure,n_control_noexposure)
%COMPUTE_CI_95 Summary of this function goes here
%compute the 95% of CI for the odds ratios 

%compute log odds ratio
log_ratio = log(odds_ratio);
SE_log_ratio = sqrt((1/n_cases_exposure)+(1/n_control_exposure)+(1/n_cases_noexposure)+(1/n_control_noexposure));

CI_min = exp(log_ratio - 1.96*SE_log_ratio);
CI_max = exp(log_ratio + 1.96*SE_log_ratio);

end

